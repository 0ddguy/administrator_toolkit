using namespace System;
using namespace Systems.Collections.Generic
import-module activedirectory
set-alias -name print -value write-host
$PSver = $PSversiontable.PSversion
$ver = '2.0'
$dom = get-addomain -current localcomputer
$dom_forest = $dom.forest

class DomainHandler
{

    
    # Grab strings for memberof display
    [string]$RX_CN = "N=(.*)"
    [PScustomobject]$query
    [bool]$verbose = $false

    # filters to be used by ad searches
    [hashtable]$filters = @{
        1 = 'Name';
        2 = 'EmployeeID';
        3 = 'Name';
        4 = 'IPv4Address';
        5 = 'LoggedOn'
    }

    # ordered dictionaries used in displaying queries
    $user_props = [ordered]@{
        'name' = 'Name: ';
        'employeeid' = 'Employee ID: ';
        'title' = 'Title: ';
        'lockedout' = 'Lock status: ';
        'emailaddress' = 'Email address: ';
        'manager' = 'Supervisor: ';
        'department' = 'Department: ';
        'lastlogondate' = 'Last logged in: ';
        'memberof' = '[VERBOSE] Member of: ';
    }

    $computer_props = [ordered]@{
        'samaccountname' = 'Display name: ';
        'description' = 'Description: ';
        'ipv4address' = 'IPv4: ';
        'operatingsystem' = 'OS: ';
        'operatingsystemversion' = 'OS ver: ';
        'dnshostname' = 'DNS hostname: ';
        'enabled' = 'Object enabled: ';
        'canonicalname' = 'CN: ';
    }

    # call get-aduser cmdlet with provided parameters
    [void]search([int]$filter_key, [string]$query, [bool]$verbose)
    {
        $this.verbose = $verbose
        $filter = $this.filters[$filter_key]
        if($filter_key -eq 1 -or $filter_key -eq 2)
        {
            $this.query = get-aduser -filter "$filter -eq $query" -properties name, employeeid, lockedout, manager, lastlogondate, title, emailaddress, department, memberof, objectclass
        }
        elseif($filter_key -eq 3 -or $filter_key -eq 4)
        {
            $this.query = get-adcomputer -filter "$filter -eq '$query'" -properties samaccountname, description, ipv4address, operatingsystem, operatingsystemversion, dnshostname, enabled, canonicalname, objectclass
        }

    }

    [void]unlock([int]$filter, [string]$crit)
    {
        print $filter $crit
    }

    # return arraylist containing all members of a provided member
    [System.Collections.ArrayList]format_member([string]$member)
    {
        [System.Collections.ArrayList]$formatted_member = @()
        
        foreach($member in $member.split(','))
        {
            if($member -match $this.RX_CN)
            {
                $member -match $this.RX_CN
                $formatted_member.add($matches[0].replace('N=',''))
            }
        }
        return $formatted_member
    }

    # [void]get_comp_user([string]$user)
    # {
    #     $ping = new-object System.Net.NetworkInformation.Ping
    #     $comp_lst = get-adcomputer -filter "enabled -eq True"
    #     print $comp_lst
    #     foreach($comp in $comp_lst)
    #     {
    #         $reply = $null
    #         $reply = $ping.send($comp)
    #         if($reply.status -like 'Success')
    #         {
    #             $exp_proc = gwmi win32_process -computer $comp -filter "Name = 'explorer.exe'"
    #             foreach($p in $exp_proc)
    #             {
    #                 print $p 
    #                 $t = ($p.getowner()).user
    #                 if($t -eq $user)
    #                 {
    #                     print $user": "$comp
    #                 }
    #             }
    #         }
    #     }
    # }

    # display stored query
    [void]display_query()
    {
        print "| Query results |" -foregroundcolor darkcyan
        if($this.query.objectclass -eq 'user')
        {
            foreach ($i in $this.user_props.keys)
            {
                # call upon format_member to format supervisor output
                if($i -eq 'manager')
                {
                    $fi = $this.format_member($this.query.$i)
                    print $this.user_props[$i] -nonewline -foregroundcolor darkyellow;print $fi[0]
                }
                # call upon format_member to format security groups
                elseif($i -eq 'memberof')
                {
                    if($this.verbose)
                    {
                        $fi = $this.format_member($this.query.$i)
                        print $this.user_props[$i] -foregroundcolor blue
                        foreach($member in $fi){print $member}
                    }
                }

                elseif($i -eq 'lockedout')
                {
                   if($this.query.$i -eq $true){$c='darkred';$s='Locked'}else{$c='darkgreen';$s='Unlocked'}
                   print $this.user_props[$i] -nonewline -foregroundcolor darkyellow; print $s -foregroundcolor $c
                }

                else {print $this.user_props[$i] -nonewline -foregroundcolor darkyellow;print $this.query.$i}
            }
        }
        elseif($this.query.objectclass -eq 'computer')
        {
            foreach($i in $this.computer_props.keys)
            {
                print $this.computer_props[$i] -nonewline -foregroundcolor darkyellow;print $this.query.$i
            }

            if($this.verbose)
            {
                $gwmi = gwmi -class win32_computersystem -computername $this.query.samaccountname.replace("$","") | select-object username
                print "[VERBOSE] Logged in user: " -nonewline -foregroundcolor blue;print $gwmi.username
            }
        }
    }
}


# Contains lists and actions used in ArgumentParser
class ArgumentContainer
{
    [System.Collections.ArrayList]$arg_lst
    [string]$arg_str
    [hashtable]$namespace = @{}
}

# Parses arguments and adds them to namespace hashtable. 
class ArgumentParser : ArgumentContainer
{
    # get argument values with -
    [string]$RX_OPT_ARG = "^-{1}[a-zA-Z0-9]+"
    # get argument values with --
    [string]$RX_OPT_LARG = "^-{2}[a-zA-Z0-9]+"
    # detect strings in quotes
    [string]$RX_QUOTE = "([^""]*)"
    # bad characters not to be used in args
    [string]$RX_BAD_CHARS = "[\*\?\]\[\^\+\`\!\@\#\$\%\&]"
    # check for comma separated values
    [string]$RX_COMMAS = "(,[\w]+)|([\w]+,)"

    [void]parse_args()
    {
        # clear namespace at beginning of invocation
        $this.namespace.clear()

        $this.arg_str = $this.get_arg_str()
        $this.arg_lst = $this.arg_str.split(' ')

        if($this.arg_lst[0] -match $this.RX_OPT_ARG -or $this.arg_lst[0] -match $this.RX_OPT_LARG)
        {
            throw '[ERROR] ' + $this.arg_lst[0] + ' must be a mode switch'
        }

        # initialize pointers
        [int]$p1 = 0
        [int]$p2 = 0

        # iter through argument list
        foreach($v in $this.arg_lst)
        {
            # mode argument will always be at index 0
            if($p1 -eq 0)
            {
                $this.namespace.mode = $v
                $p1++
                continue
            }


            # match arguments to values and add to namespace
            if($v -match $this.RX_OPT_ARG -or $v -match $this.RX_OPT_LARG)
            {
                # detect empty value and assign true
                if($this.arg_lst[$p1 + 1] -match $this.RX_OPT_ARG)
                {
                    $this.namespace[$v] = $true
                }
                
                # detect empty value and assign true
                if($this.arg_lst[$p1 + 1] -eq $null)
                {
                    $this.namespace[$v] = $true
                    continue
                }
                # detect if argument contains a string value surrounded by quotations
                if($this.arg_lst[$p1 + 1].startswith('"'))
                {
                    # set p2 to p1
                    $p2 = $p1

                    # increment p2 until the other quote is found
                    do {$p2++} until ($this.arg_lst[$p2].endswith('"'))

                    # move pointer to beginning of string
                    $p1 += 1

                    # string value is between $p1 + 1 and $p2, assign to namespace
                    $this.namespace[$v] = $this.arg_lst[$p1..$p2]

                    # set p1 back
                    $p1 -= 1
                }
                
                # check for comma separated values
                elseif($this.arg_lst[$p1 + 1].contains(','))
                {
                    $p2 = $p1
                    $p1 += 1
                    $this.namespace[$v] = $this.arg_lst[$p1 + 1].split(',')
                    $p1 -= 1
                }

                else
                {
                    # assign value to namespace
                    $this.namespace[$v] = $this.arg_lst[$p1 + 1]
                }
            }

            $p1++
 
        }

    }

    # get input from user
    [string]get_arg_str() 
    {
        $h = get-host
        $this.arg_str = $h.UI.readline()
        return $this.arg_str
    }

}

# startup art and information
function startup
{
    $art_source = join-path -path "$PSScriptRoot" -childpath "startup"
    $art_count = (get-childitem $art_source | measure-object).count
    $n = get-random -maximum $art_count
    $get_art = join-path -path $art_source -childpath $n
    get-content -raw $get_art | print
    print "by Jared Freed | GNU General Public License | ver $ver"
    print "Host: " -nonewline; print "$(hostname)" -foregroundcolor darkyellow
    if($null -eq $dom){print "Domain: " -nonewline; print "No domain detected" -foregroundcolor darkyellow}
    else{print "Domain: " -nonewline; print $dom_forest -foregroundcolor darkgreen}
    print "PS version: " -nonewline; print $PSver -foregroundcolor blue
    print "Enter " -nonewline; print "help " -nonewline -foregroundcolor darkgreen; print 'for usage'
}

function main
{
    $parser = [ArgumentParser]::new()
    $handler = [DomainHandler]::new()
    startup

    do
    {
        print "$(whoami)@tkc2>" -nonewline
        $parser.parse_args()
        if($parser.namespace.mode -eq 'search')
        {
            $handler.search($parser.namespace.item('-f'), $parser.namespace.item('-q'), $parser.namespace.item('-v'))
            $handler.display_query()
        }
        elseif($parser.namespace.mode -eq 'unlock')
        {

        }
        elseif($parser.namespace.mode -eq 'modify')
        {

        }
        elseif($parser.namespace.mode -eq 'list')
        {

        }
        elseif($parser.namespace.mode -eq 'add')
        {

        }
        elseif($parser.namespace.mode -eq 'clear'){clear-host}

    } until ($parser.namespace.mode -eq 'quit')
}

main


