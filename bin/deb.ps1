# Administrator Toolkit
# by Jared Freed @ github.com/disastrpc
# This program provides a familiar CLI for performing active directory tasks like resetting passwords, unlocking accounts and modifying and 
# querying objects for information.

using namespace System;
using namespace Systems.Collections.Generic
using namespace System.Runtime.InteropServices
import-module activedirectory

# more familiar
set-alias -name print -value write-host

$PSver = $PSversiontable.PSversion
$ver = 'v2.1.0-initial'
$dom = get-addomain -current localcomputer
$dom_forest = $dom.forest

class DomainHandler
{   
    # Grab strings for memberof display
    [string]$RX_CN = "N=(.*)"
    [string]$RX_BAD_CHARS = "[\*\?\]\[\^\+\`\!\@\#\$\%\&]"
    [bool]$verbose = $false
    [bool]$prompt = $false
    [bool]$whatif = $false
    [PScustomobject]$query

 
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
        'samaccountname' = 'Hostname: ';
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
        try
        {
            $this.verbose = $verbose
            $filter = $this.filters[$filter_key]
            if(! $filter){print "[Error] " -fore darkred -nonewline; print "Invalid filter $filter_key"}
            else
            {
                if($filter_key -eq 1 -or $filter_key -eq 2)
                {
                    $this.query = get-aduser -filter "$filter -eq '$query'" -properties name, employeeid, lockedout, manager, lastlogondate, title, emailaddress, department, memberof, objectclass
                }
                elseif($filter_key -eq 3 -or $filter_key -eq 4)
                {
                    $this.query = get-adcomputer -filter "$filter -eq '$query'" -properties samaccountname, description, ipv4address, operatingsystem, operatingsystemversion, dnshostname, enabled, canonicalname, objectclass
                }

                if (! $this.query)
                {
                    print "[Error] " -fore darkred -nonewline; print "No results for $filter and '$query'"
                }
            }
        }
        catch{print "[Error] " -nonewline -fore darkred; print "Unable to search for query '$query' using filter '$filter_key'"}
    }

    [void]unlock([int]$filter_key, [string]$query)
    {
        $filter = $this.filters[$filter_key]
        $this.query = get-aduser -filter "$filter -eq $query" -property lockedout, employeeid, name
        $c = ''; $s = ''
        if($query -match $this.RX_BAD_CHARS){print '[Error] Invalid character used' -fore darkred}
        else
        {
            try 
            {
                unlock-adaccount -identity $this.query.employeeid

                $id = $this.query.employeeid
                $name = $this.query.name
                $lock = $this.query.lockedout
                if($lock -eq $true){$c = 'darkred'; $s = 'Locked'}
                elseif($lock -eq $false){$c = 'darkgreen'; $s = 'Unlocked'}
                print "[Success]" -fore darkgreen -nonewline; print " Unlocked object: " -nonewline;print "$name ($id)" -fore blue
                print "[Info]" -fore darkyellow -nonewline; print " Object status: $s"
            } 
            catch {print "[Error] Unable to unlock '$query' with filter '$filter', please ensure your account has sufficient permissions or that the user exists" -fore darkred}
        }
    }

    [void]reset([int]$filter_key, [string]$query, [string]$prompt, [bool]$whatif)
    {
        if($query -match $this.RX_BAD_CHARS){print '[Error] Invalid character used' -fore darkred}
        else
        {
            try
            {
                $this.prompt = $prompt; $this.whatif = $whatif

                $filter = $this.filters[$filter_key]
                $this.query = get-aduser -filter "$filter -eq $query" -property lockedout, employeeid, name
                $name = $this.query.name; $id = $this.query.employeeid; $p = $this.prompt

                print "[Info] " -fore darkyellow -nonewline; print "Changing password for " -nonewline;print "$name ($id)" -nonewline -fore darkyelllow;print ", enter 'c' to confirm: " -nonewline
                $h = get-host
                $c = $h.ui.readline()
                if($c -ceq 'c')
                {

                    $cred = read-host "Enter password" -assecurestring
                    $cred_comp = read-host "Confirm password" -assecurestring

                    # Decrypt password into temporary variable to compare
                    $t = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($cred))
                    $t2 = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($cred_comp))
                    # check if passwords match
                    if($t -ceq $t2)
                    {
                        # Clear temporary variables from memory
                        if($t){$t=$null};if($t2){$t2=$null}

                        # Check if property must be set to true
                        if($prompt -eq $null){$this.prompt = $false}elseif($prompt){$this.prompt = $true}
            
                        if(-not $this.whatif)
                        {
                            set-adaccountpassword -identity $this.query.employeeid -newpassword $cred
                            set-aduser -identity $this.query.employeeid -changepasswordatlogon $this.prompt
                            print "[Info] " -fore darkyellow -nonewline; print "ChangePasswordAtLogin property is " -nonewline;print $p -fore darkyellow
                        }
                        elseif($this.whatif)
                        {
                            print '[Info] ' -fore darkyellow -nonewline; print "Performing 'whatif' operation"
                            set-adaccountpassword -whatif -identity $this.query.employeeid -newpassword $cred
                            set-aduser -whatif -identity $this.query.employeeid -changepasswordatlogon $this.prompt
                            print "[Info] " -fore darkyellow -nonewline; print "ChangePasswordAtLogin property is " -nonewline;print $p -fore darkyellow
                        }
                        print "[Info] " -nonewline -fore darkyellow; print "WhatIf operation for $name ($id) completed"
                    }
                    else{print "[Error] Passwords don't match" -fore darkred}
                }
                else {print "[Info] " -fore darkyellow -nonewline; print "Aborting..."}

            } catch {print "[Error] Could not parse query '$query'" -fore darkred}
        }
    }

    # return arraylist containing all properties of a provided member
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

    # display stored query
    [void]display_query()
    {

        if($this.query.objectclass -eq 'user')
        {
            print "| Query results |" -foregroundcolor darkcyan
            foreach ($i in $this.user_props.keys)
            {
                # call upon format_member to format supervisor output
                if($i -eq 'manager')
                {
                    $fi = $this.format_member($this.query.$i)
                    print $this.user_props[$i] -nonewline -fore darkyellow; print $fi[0]
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

                else 
                {
                    print $this.user_props[$i] -nonewline -foregroundcolor darkyellow;print $this.query.$i
                } 
            }
        }
        elseif($this.query.objectclass -eq 'computer')
        {
            print "| Query results |" -foregroundcolor darkcyan
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

        $this.query = $null
    }

    # This method attempts to query AD computer objects and find the hostname for the provided user's computer. It is an inneficient method in a large enviroment without
    # specifing an OU to search in. A workaround would be to enable a startup script for users in VBS like so:
    #
    # Courtesy of Cazi @ https://community.spiceworks.com/how_to/34096-show-user-s-logged-on-computer-name-in-active-directory
    #
    # Option Explicit
    # Const ADS_PROPERTY_UPDATE = 2 
    # Dim objSysInfo, objUser, objNetwork, strComputer, strDescription

    # Set objSysInfo = CreateObject("ADSystemInfo")
    # Set objUser = GetObject("LDAP://" & objSysInfo.UserName)

    # Set objNetwork = CreateObject("Wscript.Network")
    # strComputer = objNetwork.ComputerName

    # strDescription = "Logged on to " & strComputer & " at " & Date & " " & Time

    # objUser.Put "description", strDescription
    # objUser.SetInfo
    # 
    # Users would have to have delegated permissions to update their own description field. The script would have the user update it with the current 
    # hostname and time logged in, this information can be easily queried with the get-aduser cmdlet. 
    # As an alternative, the method below will be more efficient once the code to specify an OU is added:

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
}

# Notes on ArgumentParser class:
# The ArgumentParser class will work standalone with any other program (it will be released separately as a module once its more refined).
# A parser object can be created with the default constructor. Calling upon the get_args() method will invoke the Host.UI.Readline method,
# this can be used in conjunction with parse_args() to provide CLI-like argument parsing while on a loop. But any space separated string 
# parameter can be supplied to parse_args().

# function add_numbers([int]$n1, [int]$n2)
# { 
#   return $n1 + $n2
# }
#
# $parser = [ArgumentParser]::new()
# $parser.parse_args($parser.get_args())
# if($parser.namespace.mode -eq 'add')
# {
#   add_numbers($parser.namespace.value('-n1'), $parser.namespace.value('-n2'))
# }

# The first key on the table will always be the mode argument, all following arguments need to be prefixed with a '-' or '--'. Long string arguments 
# can be separated by " " and multiple values can be separated by commas (1,2,3). Separated values will be assigned as a list to the key and 
# can be accessed with $parser.namespace['key'][index].
# Contains lists and actions used in ArgumentParser

class ArgumentContainer
{
    [System.Collections.ArrayList]$arg_lst
    [string]$arg_str
    [hashtable]$namespace = @{}
    # get argument values with -
    [string]$RX_OPT_ARG = "^-{1}[a-zA-Z0-9]+"
    # get argument values with --
    [string]$RX_OPT_LARG = "^-{2}[a-zA-Z0-9]+"
    # detect strings in quotes
    [string]$RX_QUOTE = "([^""]*)"
    # bad characters not to be used in args
    [string]$RX_BAD_CHARS = "[\*\?\]\[\^\+\`\!\@\#\$\%\&\|]"
    # check for comma separated values
    [string]$RX_COMMAS = "(,[\w]+)|([\w]+,)"
    # handle file extensions
    [string]$RX_FILE_EXT = "(.+?)(\.[^.]*$|$)"

    [int]$pos_args = 0
}

# Parses arguments and adds them to namespace hashtable. 
class ArgumentParser : ArgumentContainer
{

    [void]parse_args([string]$arg_str)
    {
        # clear namespace at beginning of invocation
        $this.namespace.clear()

        $this.arg_str = $arg_str
        $this.arg_lst = $this.arg_str.split(' ')

        if($this.arg_str -match $this.RX_BAD_CHARS)
        {
            throw '[Error] Invalid character used'
        }
        elseif($this.arg_lst[0] -match $this.RX_OPT_ARG -or $this.arg_lst[0] -match $this.RX_OPT_LARG)
        {
            throw '[Error] ' + $this.arg_lst[0] + ' must be a mode switch'
        }
        else
        {
            # initialize pointers and flags
            [int]$p1 = 0
            [int]$p2 = 0
            [bool]$mf = $false
            [bool]$vf = $false
            [bool]$tf = $false

            # iter through argument list
            foreach($v in $this.arg_lst)
            {

                # mode argument will always be at index 0
                if($p1 -eq 0 -and ! $mf)
                {
                    # check if .val is after the first argument
                    if($this.arg_lst[$p1 + 1] -match $this.RX_OPT_ARG){}
                    else
                    {
                        # assign val and trigger flag
                        $this.namespace.val = $this.arg_lst[$p1 + 1]
                        $vf = $true
                    }

                    $this.namespace.mode = $v
                    $p1++
                    $mf = $true
                    continue
                }
                
                # grab .val value
                if($this.arg_lst[$p1 + 1] -eq $null -and ! $vf)
                {
                    $this.namespace.val = $v
                    $vf = $true
                    continue
                }

                # grab 'to' keyword value
                if($v -eq 'to' -and ! $tf)
                {   $p1 += 1
                    $this.namespace.kw_to = $this.arg_lst[$p1]
                    $p1 -= 1
                    $tf = $true
                    continue
                }

                # grab .val value in quotes if flag hasn't been triggered
                elseif(! $vf)
                {
                    if($this.arg_lst[$p1 + 1].startswith('"'))
                    {
                        do {$p2++} until ($this.arg_lst[$p2 + 1] -eq $null)
                        $p1 += 1
                        $val = $this.arg_lst[$p1..$p2].replace('"','')
                        $this.namespace.val = $val
                        $vf = $true
                        $p1 -= 1
                        continue
                    }
                }

                # match arguments to values and add to namespace
                if($v -match $this.RX_OPT_ARG -or $v -match $this.RX_OPT_LARG)
                {
                    # detect empty value and assign true
                    if($this.arg_lst[$p1 + 1] -match $this.RX_OPT_ARG -or $this.arg_lst[$p1 + 1] -match $this.RX_OPT_LARG)
                    {
                        $this.namespace[$v] = $true
                    }
                    
                    # detect if argument contains a string value surrounded by quotations
                    elseif($this.arg_lst[$p1 + 1].startswith('"'))
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
                        $sub_lst = $this.arg_lst[$p1 + 1]
                        $p2 = $p1
                        $p1 += 1
                        $this.namespace[$v] = $sub_lst.split(',')
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
    }

    # get input from user
    [string]get_args() 
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
    $module_source = join-path -path "$PSScriptRoot" -childpath "scripts"
    $art_count = (get-childitem $art_source | measure-object).count
    $module_count = (get-childitem $module_source | measure-object).count - 2
    $n = get-random -maximum $art_count
    $get_art = join-path -path $art_source -childpath $n
    get-content -raw $get_art | print
    print "by Jared Freed | GNU General Public License | $ver"
    print "Host: " -nonewline; print "$(hostname)" -fore darkyellow
    if($null -eq $dom){print "Domain: " -nonewline; print "No domain detected" -fore darkyellow}
    else{print "Domain: " -nonewline; print $dom_forest -fore darkgreen}
    print "Loaded modules: " -nonewline; print $module_count -fore blue
    print "PS version: " -nonewline; print $PSver -fore blue
    print "Enter " -nonewline; print "help " -nonewline -fore darkgreen; print 'for usage'
}

function set_module_args([string]$mod, [string]$key, [string]$val)
{
    $fname = $mod + '-args' + '.dat'

    if( ! (test-path -path "$PSScriptRoot\tmp\$fname"))
    {
        try{new-item -path "$PSScriptRoot\tmp" -name "$fname" -itemtype 'file' -force >$null}
        catch{print "[Error] " -nonewline -fore darkred; print "Unable to create args file, make sure you have access to $PSScriptRoot\tmp"}
    }

    $content = $key + '=>' + $val

    try
    {
        add-content -path "$PSScriptRoot\tmp\$fname" -value $content
    }
    catch{print "[Error] " -nonewline -fore darkred; print "Unable to set argument, make sure you have access to $PSScriptRoot\tmp"}
}

# if print is set to true print set values for the selected module, otherwise return a hashtable containing arguments => values
function get_module_args([string]$mod, [string]$key)
{
    $fname = $mod + '-args' + '.dat'

    try
    {   
        if($print)
        {
            print "Arguments for $mod" -fore blue
            foreach($line in get-content -path "$PSScriptRoot\tmp\$fname")
            {
                print $line
            }
        }
    } catch{print "[Error] " -nonewline -fore darkred; print "Unable to read options, try running 'unset all' and resetting arguments"}
}

function parse_module_args([string]$mod)
{
    $fname = $mod + '-args' + '.dat'

    [hashtable]$module_args = @{}

    foreach($line in get-content -path "$PSScriptRoot\tmp\$fname")
    {

        $_args = $line.split('=>')
        $module_args[$_args[0]] = $_args[2]
    }
    return $module_args
}

function main
{
    $parser = [ArgumentParser]::new()
    $handler = [DomainHandler]::new()
    
    [string]$mod = ''

    startup

    [Array]$mode = @(
        'search',
        'unlock',
        'reset',
        'modify',
        'set',
        'help',
        'ping',
        'exec',
        'list',
        'man',
        'load',
        'options',
        'unset',
        'run'
    )

    # unset variables at beggining of program
    remove-item -path "$PSScriptRoot\tmp\*.dat"

    do
    {
        if($mod){print "$(whoami)@tkc2 " -nonewline -fore blue; $mod_disp=$mod.replace('.ps1',''); print "=> ($mod_disp)>" -nonewline}else{print "$(whoami)@tkc2>" -nonewline -fore blue}
        $parser.parse_args($parser.get_args())
        # catch{print "[Error] " -nonewline -fore darkred; print "Unable to parse arguments, enter 'help' for usage"}

        # unlock mode
        if($parser.namespace.mode -eq $mode[0])
        {   
            $handler.search($parser.namespace.item('-f'), $parser.namespace.val, $parser.namespace.item('-v'))
            $handler.display_query()
        }
        elseif($parser.namespace.mode -eq $mode[1])
        {
            $handler.unlock($parser.namespace.item('-f'), $parser.namespace.item('-q'))
        }
        elseif($parser.namespace.mode -eq $mode[2])
        {
            $handler.reset($parser.namespace.item('-f'), $parser.namespace.item('-q'), $parser.namespace.item('-p'), $parser.namespace.item('--what-if'))
        }

        # exec modules
        elseif($parser.namespace.mode -eq $mode[7])
        {
            if($parser.namespace.item('-M'))
            {
                if ( ! ($parser.namespace.item('-M') -match $parser.RX_BAD_CHARS) -and ! ($parser.namespace.item('--arg-list') -match $parser.RX_BAD_CHARS))
                {
                    $m = $parser.namespace.item('-M'); $m += '.ps1'
                    $script = $parser.namespace.item('-M')
                    $arg = $parser.namespace.item('--arg-list')
                    & $PSScriptRoot\scripts\$script $arg
                }
                else {print '[Error] ' -nonewline -fore darkred; print 'Invalid character used'}
            }
        }

        # ping mode
        elseif($parser.namespace.mode -eq $mode[6])
        {
            $h = $parser.namespace.item('-h')
            print "[Info] " -nonewline -fore darkyellow; print " Pinging $h"
            $r = test-connection -computername $parser.namespace.item('-h') -count 1 -quiet
            if($r){print "[Ping] " -nonewline -fore darkyellow; print " $h is up"}
            else{print "[Ping] " -nonewline -fore darkyellow; print " $h is down"}
        }

        # help mode
        elseif($parser.namespace.mode -eq $mode[5])
        {
            if($parser.namespace.item('-M'))
            {
                $mod_help = $parser.namespace.item('-M') + '-help'
                $mod_help_source = join-path "$PSScriptRoot\scripts\help" -childpath $mod_help
                get-content -raw $mod_help_source | print
            }
            else
            {
                print "------------------------ Help ------------------------ " -fore blue
                $_source = join-path -path "$PSScriptRoot" -childpath "cfg"
                $source = join-path -path $_source -childpath 'help'
                get-content -raw $source | print
            }
        }

        # list mode
        elseif($parser.namespace.mode -eq $mode[8])
        {
            if($parser.namespace.val -eq 'filters')
            {
                print "Filters: " -fore darkyellow
                foreach($i in $handler.filters.keys)
                {
                    $v = $handler.filters[$i]
                    print " $i  =>  $v"
                }
            }
            elseif($parser.namespace.val -eq 'modules')
            {
                $items = get-childitem -depth 0 -attributes !directory -path "$PSScriptRoot\scripts"
                foreach($i in $items)
                {
                    print "Available modules: " -fore darkyellow
                    $match=$i -match $parser.RX_FILE_EXT
                    print " "$matches[1]
                }
            }
            elseif($parser.namespace.val -eq 'options')
            {
                if( ! $mod){print "[Error] " -fore darkred -nonewline; print "No module selected, select a module using 'load'"}
                else
                {
                    get_module_args -mod $mod -key $parser.namespace.kw_to
                }
            }
            elseif($ ! $parser.namespace.val){print " Modes: " -fore darkyellow; foreach($i in $mode){print $i}}

        }

        # loading module
        elseif($parser.namespace.mode -eq $mode[10])
        {
            $items = get-childitem -depth 0 -attributes !directory -path "$PSScriptRoot\scripts"
            foreach($i in $items)
            {
                if($i -match $parser.namespace.val)
                {
                    $mod = $parser.namespace.val
                    print "[ Ok ] " -fore darkgreen -nonewline; print "Loaded module $mod"
                    break
                }
            }
            if(! $mod){print "[Error] " -fore darkred -nonewline; print "Module '$mod' not found"}
        }

        # options mode
        elseif($parser.namespace.mode -eq $mode[11])
        {
            if($mod)
            {
                $mod_help = $mod + '-help'
                $mod_help_source = join-path "$PSScriptRoot\scripts\help" -childpath $mod_help
                get-content -raw $mod_help_source | print
            }
            else{print "[Info] " -fore darkyellow -nonewline; print "No module loaded"}
        }
        # set module options
        elseif($parser.namespace.mode -eq $mode[4])
        {
            set_module_args -mod $mod -key $parser.namespace.val -val $parser.namespace.kw_to
        }
        # run selected module
        elseif($parser.namespace.mode -eq $mode[13])
        {
            $fname = $mod + '-args' + '.dat'

            if( ! (test-path -path "$PSScriptRoot\tmp\$fname")){print "[Info] " -fore darkyellow -nonewline; print "No arguments selected, set some arguments using 'set'"}
            else
            {
                [hashtable]$mod_args = parse_module_args -mod $mod
                [System.Collections.ArrayList]$parsed_args = @()

                foreach($key in $mod_args.keys)
                {                     
                    [string]$val = $mod_args[$key]
                    $arg = "$key=$val"
                    $parsed_args.add($arg)
                }
                $fpath = $mod + '.ps1'
                print "Info: running module $mod"
                & $PSScriptRoot\scripts\$fpath $parsed_args
            }
        }
        elseif($parser.namespace.mode -eq 'clear'){clear-host}
        else{$m = $parser.namespace.mode; print "Error: Mode '$m' not found"}

    } until ($parser.namespace.mode -eq 'quit')
}

main


