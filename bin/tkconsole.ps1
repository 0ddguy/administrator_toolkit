# Administrator Toolkit
# by Jared Freed @ github.com/disastrpc
# This script provides a familiar CLI for performing active directory tasks like resetting passwords, unlocking accounts and modifying and 
# querying objects for information.

using module '.\modules\argparse\argparse.psd1'
using namespace System
using namespace Systems.Collections.Generic
using namespace System.Runtime.InteropServices

import-module activedirectory

$PSver = $PSversiontable.PSversion
$ver = '2.2.0'
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

    # filters to be used by ad searches, uses LDAP names
    [hashtable] $filters = @{
        1 = 'Name';
        2 = 'EmployeeID';
        3 = 'ComputerName';
        4 = 'IPv4Address';
    }

    # ordered dictionaries used in displaying queries
    [hashtable] $user_props = [ordered]@{
        'name' = 'Name';
        'employeeid' = 'EmployeeID';
        'title' = 'Title';
        'lockedout' = 'LockStatus';
        'emailaddress' = 'EmailAddress';
        'manager' = 'Supervisor';
        'department' = 'Department';
        'lastlogondate' = 'LastOnline';
        'memberof' = 'MemberOf';
    }

    [hashtable] $computer_props = [ordered]@{
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
            if(! $filter_key){Write-Output "[Error] Invalid filter $filter_key"}
            else
            {
                if($filter_key -eq 1 -or $filter_key -eq 2)
                {
                    $this.query = get-aduser -filter "$($this.filters[$filter_key]) -eq '$query'" -properties name, employeeid, lockedout, manager, lastlogondate, title, emailaddress, department, memberof, objectclass
                }
                elseif($filter_key -eq 3)
                {
                    #$this.query = get-adcomputer -filter "$($this.filters[$filter_key]) -eq '$query'" -properties samaccountname, description, ipv4address, operatingsystem, operatingsystemversion, dnshostname, enabled, canonicalname, objectclass
                    $this.query = Get-ADComputer -Identity $query -properties samaccountname, description, ipv4address, operatingsystem, operatingsystemversion, dnshostname, enabled, canonicalname, objectclass
                }
                elseif($filter_key -eq 4)
                {
                    $this.query = Get-ADComputer -Filter "$($this.filters[$filter_key]) -eq '$query'" -Properties IPv4Address, samaccountname, operatingsystemversion, operatingsystem, enabled, canonicalname, objectclass, description
                }

                if (! $this.query)
                {
                    [Console]::WriteLine("[Error] No results for filter $($this.filters[$filter_key]) and '$query'")
                }
            }
        }
        catch{[Console]::WriteLine("[Error] Unable to search for query '$query' using filter '$filter_key'")}
    }

    [void]unlock([int]$filter_key, [string]$query)
    {
        try{$this.query = get-aduser -filter "$($this.filters[$filter_key]) -eq '$query'" -property lockedout, employeeid, name}catch{}
        $c = ''; $s = ''
        if($query -match $this.RX_BAD_CHARS){Write-Output '[Error] Invalid character used'}
        else
        {
            try 
            {
                unlock-adaccount -identity $this.query.employeeid

                $id = $this.query.employeeid
                $name = $this.query.name
                $lock = $this.query.lockedout

                if($lock -eq $true){$s = 'Locked'}
                elseif($lock -eq $false){$s = 'Unlocked'}

                [Console]::WriteLine("[Success] Unlocked object: $name ($id)")
                [Console]::WriteLine("[Info] Object status: $s")

            } 
            catch {[Console]::WriteLine("[Error] Unable to unlock '$query' with filter '$($this.filters[$filter_key])', please ensure your account has sufficient permissions or that the user exists")}
        }
    }

    [void]reset([int]$filter_key, [string]$prompt, [bool]$whatif, [string]$query)
    {
        if($query -match $this.RX_BAD_CHARS){Write-Output "[Error] Invalid character used"}
        else
        {
            try
            {
                $this.prompt = $prompt; $this.whatif = $whatif
                $this.query = get-aduser -filter "$($this.filters[$filter_key]) -eq '$query'" -property lockedout, employeeid, name
                $name = $this.query.name; $id = $this.query.employeeid; $p = $this.prompt
                [Console]::Write("[Info] Changing password for $name ($id), enter 'c' to confirm: ")
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
                        if($null -eq $prompt){$this.prompt = $false}elseif($prompt){$this.prompt = $true}
            
                        if( ! $this.whatif)
                        {
                            set-adaccountpassword -identity $this.query.employeeid -newpassword $cred
                            set-aduser -identity $this.query.employeeid -changepasswordatlogon $this.prompt
                            Write-Output "[Info] ChangePasswordAtLogin property is $p"
                        }
                        elseif($this.whatif)
                        {
                            Write-Output "[Info] Performing 'whatif' operation"
                            set-adaccountpassword -whatif -identity $this.query.employeeid -newpassword $cred
                            set-aduser -whatif -identity $this.query.employeeid -changepasswordatlogon $this.prompt
                            Write-Output "[Info] ChangePasswordAtLogin property is $p"
                        }
                        Write-Output "[ Ok ] Password change complete"
                    }
                    else{Write-Output "[Error] Passwords don't match"}
                }
                else {Write-Output "[Info] Aborting..."}

            } catch {Write-Output "[Error] Error '$query'"}
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
        write-host $formatted_member
        return $formatted_member
    }

    # display stored query
    [void]display_query()
    {
        if($this.query.objectclass -eq 'user')
        {
            Write-Output "| Query results |"
            [hashtable] $display_query = @{}
            foreach ($i in $this.user_props.keys)
            {
                # # call upon format_member to format supervisor output
                # if($i -eq 'manager')
                # {
                #     $fi = $this.format_member($this.query.$i)
                #     $display_query[$this.user_props[$i]] = $fi
                # }
                # call upon format_member to format security groups
                if($i -eq 'memberof' -and $this.verbose)
                {
                    $fi = $this.format_member($this.query.$i)
                   
                    $display_query[$this.user_props[$i]] = $fi
                }
                else 
                {
                    $display_query[$this.user_props[$i]] = $this.query.$i                            
                } 
            }

            $query_object = [PSCustomObject]$display_query
            $query_object | Format-List -Property Name,EmployeeID,Supervisor,Title,Department,EmailAddress,LockStatus,LastOnline,MemberOf | Out-Host
        }
        elseif($this.query.objectclass -eq 'computer')
        {
            Write-Output "| Query results |"
            [hashtable] $display_query = @{}
            foreach($i in $this.computer_props.keys)
            {
                $display_query[$this.computer_props[$i]] = $this.query.$i                            
            }

            $query_object = [PSCustomObject]$display_query
            $query_object | Format-List | Out-Host
        }

        $this.query = $null
    }

    # The get_comp_user() method attempts to query AD computer objects and find the hostname for the provided user's computer. It is an inneficient method in a large environment without
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
    #     Write-Output $comp_lst
    #     foreach($comp in $comp_lst)
    #     {
    #         $reply = $null
    #         $reply = $ping.send($comp)
    #         if($reply.status -like 'Success')
    #         {
    #             $exp_proc = gwmi win32_process -computer $comp -filter "Name = 'explorer.exe'"
    #             foreach($p in $exp_proc)
    #             {
    #                 Write-Output $p 
    #                 $t = ($p.getowner()).user
    #                 if($t -eq $user)
    #                 {
    #                     Write-Output $user": "$comp
    #                 }
    #             }
    #         }
    #     }
    # }
    #
    # The method queries all computer objects on the domain and searches for the current user that is using the explorer.exe process. This is obviously very inneficient unless
    # filter are provided to narrow down the number of hosts that the script would need to iterate through. 
}

# startup art and information
function startup
{
    $art_source = Join-Path -path "$PSScriptRoot" -childpath "startup\art"
    $module_source = Join-Path -path "$PSScriptRoot" -childpath "modules"
    $art_count = ((get-childitem $art_source | measure-object).count) - 1
    $module_count = (get-childitem $module_source -attributes !directory+!compressed | measure-object).count
    $n = get-random -maximum $art_count
    $get_art = Join-Path -path $art_source -childpath $n
    Get-Content -raw $get_art | Write-Output
    Write-Output "by Jared Freed | GNU General Public License | $ver"
    Write-Output "Host: $(hostname)"
    if($null -eq $dom){Write-Output "Domain: No domain detected"}
    else{Write-Output "Domain: $dom_forest"}
    Write-Output "Loaded modules: $module_count"
    Write-Output "PS version: $PSver"
    Write-Output "Enter 'help' for usage"
}

# Main program logic
function main
{
    $parser = [ArgumentParser]::new()
    $handler = [DomainHandler]::new()
    
    [string]$mod = ''

    startup

    do
    {
        if($mod)
        {
            $selected_module = $mod.replace('.ps1','')
            [Console]::Write("$(whoami)@tkc2 => ($selected_module)>")
        }
        else
        {
            [Console]::Write("$(whoami)@tkc2>")
        }
        $parser.parse_args($parser.get_args())

        # these loops check if keys and values contain bad characters
        foreach($key in $parser.namespace.keys)
        {
            if($key -match $parser.RX_BAD_CHARS)
            {
                Write-Output "[Error] Invalid character used"
                continue
            }
        }

        foreach($val in $parser.namespace.values)
        {
            if($val -match $parser.RX_BAD_CHARS)
            {
                Write-Output "[Error] Invalid character used"
                continue
            }
        }

        # switch for all program modes
        switch ($parser.namespace.mode)
        {
            "search" 
            {
                $handler.search($parser.namespace.item('-f'), $parser.namespace.val, $parser.namespace.item('-v'))
                $handler.display_query()
            }
            "unlock"
            {
                $handler.unlock($parser.namespace.item('-f'), $parser.namespace.val)
            }
            "reset"
            {
                $handler.reset($parser.namespace.item('-f'), $parser.namespace.item('-p'), $parser.namespace.item('--whatif'), $parser.namespace.val)
            }
            "ping"
            {
                $h = $parser.namespace.val
                Write-Output "[Info] Pinging $h"
                $r = Test-Connection -computername $parser.namespace.val -count 1 -quiet
                if($r){Write-Output "[Ping] $h is up"}
                else{Write-Output "[Ping] $h is down"}
            }
            "help"
            {

                $_source = Join-Path -path "$PSScriptRoot" -childpath "startup"
                $source = Join-Path -path $_source -childpath 'help'
                Get-Content -raw $source | Write-Output               
            }
            "list"
            {
                if($parser.namespace.val -eq 'modules')
                {
                    $items = get-childitem -depth 0 -attributes !directory+!compressed -path "$PSScriptRoot\modules"
                    Write-Output "Available modules: " 
                    foreach($i in $items)
                    {
                        Write-Output " "$match[0]
                    }
                }
                elseif($parser.namespace.val -eq 'args')
                {
                    if( ! $mod){Write-Output "[Error] No module selected"}
                    else
                    {
                        $parser.get_module_args($mod)
                    }
                }
            }
            "use"
            {
                $f = $false
                foreach($i in get-childitem -depth 0 -attributes !directory+!compressed -path "$PSScriptRoot\modules")
                {
                    $file = Split-Path $i -Leaf
                    if($file -eq ($parser.namespace.val + '.ps1'))
                    {
                        Write-Output "[ Ok ] Loaded module $($parser.namespace.val)"       
                        $mod = $file       
                        $f = $true
                        break
                    }
                }

                if( ! $f){Write-Output "[Error] Module $($parser.namespace.val) not found"}
            }
            "options"
            {

                $a_mod = $mod.split('.')

                # reassemble string
                $mod_help = $a_mod[0] + '-help'
                $mod_help_source = Join-Path "$PSScriptRoot\modules\help" -childpath $mod_help
                Get-Content -raw $mod_help_source | Write-Output

            }
            "set"
            {
                $parser.set_module_arg($mod, $parser.namespace.val, $parser.namespace.kw_to)
            }
            "unset"
            {
                $parser.unset_module_arg($mod, $parser.namespace.val)
            }
            "run"
            {
                $fname = $mod + '-args' + '.dat'

                $fname = $fname.replace('.ps1','')
                

                if( ! (test-path -path "$PSScriptRoot\tmp\$fname")){Write-Output "[Info] No arguments selected, set some arguments using 'set'"}
                else
                {
                    [hashtable]$mod_args = $parser.parse_module_args($mod)
                    [System.Collections.ArrayList]$parsed_args = @()

                    foreach($key in $mod_args.keys)
                    {                     
                        [string]$val = $mod_args[$key]
                        $arg = "$key=$val"
                        $parsed_args.add($arg)>$null
                    }

                    $fpath = $mod
                    Write-Output "Info: running module $mod"
                    Write-Output "Params: $parsed_args"
                    & $PSScriptRoot\modules\$fpath $parsed_args
                }
            }
            "clear" 
            {
                Clear-Host
            }
            default {Write-Output "Error: Mode '$($parser.namespace.mode)' not found"}

        }

    } until ($parser.namespace.mode -eq 'quit')
}

main


