function session([string]$target_host, [string]$proj, [string]$extra=$false)
{
    [string]$RX_IPV4 = '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'

    write-host '[Info] ' -nonewline -fore darkyellow; write-host "Testing connection to $target_host"
    
    if(test-connection -computername $target_host -quiet -count 1)
    {
        write-host '[ Ok ] ' -nonewline -fore darkgreen; write-host "$target_host is online"
        write-host "[Info] " -fore darkyellow -nonewline; write-host "Enabling WSM service" 
        WMIC /node:"$target_host" process call create "cmd.exe /c powershell enable-psremoting" >$null 2>&1
        write-host "[Info] " -fore darkyellow -nonewline; write-host "Waiting for WMIC changes to populate"
        $c = 1
        do
        { 
            write-host "[Info] " -fore darkyellow -nonewline; write-host "Attempting to establish session with $target_host ($c\10 attempts)"
            $session_check = new-pssession -computername $target_host -erroraction silentlycontinue; start-sleep(5)
            $c++
        } until($session_check -or $c -eq 10)
        remove-pssession $session_check

        $session = new-pssession -computername $target_host -credet


        write-host "[ Ok ] " -nonewline -fore darkgreen; write-host "WSM service enabled"
        
        write-host "[Info] " -nonewline -fore darkyellow; write-host "Copying default apps policy"
        copy-item "$PSScriptRoot\src\defs.xml" -destination "C:\Temp" -tosession $session
        
        # Apply the copied policy
        write-host "[Info] " -nonewline -fore darkyellow; write-host "Applying policy"
        invoke-command -session $session { dism /online /import-defaultappassociations:C:\Temp\def.xml } | out-null
        write-host "[ Ok ] " -nonewline -fore darkgreen; write-host "Policy applied"

        # test if resources are available
        $path1 = test-path -path "$PSScriptRoot\src\Apps"; $path2 = test-path -path "$PSScriptRoot\src\Web Resources"
        
        # setup shortcuts
        if($path1 -and $path2)
        {                
            $p=$proj.ToUpper()
            write-host "[Info] " -fore darkyellow -nonewline; write-host "Resources found"
            write-host "[Info] " -fore darkyellow -nonewline; write-host "Copying resources for $p"
            if($proj -match 'cfeec')
            {
                copy-item -recurse -force -path "$PSScriptRoot\src\Apps\CFEEC_Resources" -destination "C:\Users\Public\Desktop" -tosession $session
                copy-item -recurse -force -path "$PSScriptRoot\src\Web Resources" -destination "C:\Users\Public\Desktop" -tosession $session
            
            }
            elseif($proj -match 'opwdd')
            {
                copy-item -recurse -force -path "$PSScriptRoot\src\Apps\OPWDD_Resources" -destination "C:\Users\Public\Desktop" -tosession $session
                copy-item -recurse -force -path "$PSScriptRoot\src\Web Resources" -destination "C:\Users\Public\Desktop" -tosession $session
            }
            elseif($proj -match 'cyes')
            {
                copy-item -recurse -force -path "$PSScriptRoot\src\Apps\CYES_Resources" -destination "C:\Users\Public\Desktop" -tosession $session
                copy-item -recurse -force -path "$PSScriptRoot\src\Web Resources" -destination "C:\Users\Public\Desktop" -tosession $session
            }
            elseif($proj -match 'outreach')
            {
                copy-item -recurse -force -path "$PSScriptRoot\src\Apps\NYMC_Outreach" -destination "C:\Users\Public\Desktop" -tosession $session
                copy-item -recurse -force -path "$PSScriptRoot\src\Web Resources" -destination "C:\Users\Public\Desktop" -tosession $session
            }
            else{write-host '[Error] ' -fore darkred -nonewline; write-host "Invalid option '$proj'"}

            # remote invocations using the opened session
            invoke-command -session $session {copy-item -force -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Office 2013\Word 2013.lnk" -destination "C:\Users\Public\Desktop"}
            invoke-command -session $session {copy-item -force -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Office 2013\Excel 2013.lnk" -destination "C:\Users\Public\Desktop"}
            invoke-command -session $session {copy-item -force -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Office 2013\Outlook 2013.lnk" -destination "C:\Users\Public\Desktop"}
            invoke-command -session $session {copy-item -force -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Cisco\Cisco AnyConnect Secure Mobility Client\Cisco AnyConnect Secure Mobility Client.lnk" -destination "C:\Users\Public\Desktop"}
            invoke-command -session $session {copy-item -force -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\SupportPoint\SupportPoint.lnk" -destination "C:\Users\Public\Desktop"}
            invoke-command -session $session {copy-item -force -path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Acrobat Reader DC.lnk" -destination "C:\Users\Public\Desktop"}

            

            if($extra)
            {
                print "[Info] " -nonewline -fore darkyellow; print "Copying additional files" -nonewline
                copy-item -force -path "$PSScriptRoot\src\mobile-1.6.8-uasny.exe" -destination "C:\" -tosession $session
            }
            write-host "[ Ok ] " -nonewline -fore darkgreen; write-host "Shortcuts setup"
        }
        else
        {
            write-host "[Error] " -fore darkred -nonewline; write-host "Please ensure resources and apps are in the src folder"
        }
        
        write-host "[Info] " -fore darkyellow -nonewline; write-host "Cleaning up"
        invoke-command -computername $target_host -scriptblock {remove-item -path C:\Temp\defs.xml}
        remove-pssession $session
        write-host "[ Ok ] " -nonewline -fore darkgreen; write-host "Cleaned up session"
        write-host "[Info] " -fore darkyellow -nonewline; write-host "Disabling WSM service" 
        WMIC /node:$target_host process call create "cmd.exe /c powershell disable-psremoting" >$null 2>&1
        do
        { 
            $r=get-random -minimum 2 -maximum 5
            $session_check = new-pssession -computername $target_host -erroraction silentlycontinue; start-sleep($r)
            $c++
        } until( ! ($session_check) -or $c -eq 10)
        write-host "[ Ok ] " -fore darkgreen -nonewline; write-host "WSM service disabled" 
        write-host "[ Ok ] " -fore darkgreen -nonewline; write-host "Module execution complete on $target_host"
    }
    else
    {             
        $props = get-adcomputer -filter "name -eq '$target_host'" -properties name, ipv4address    
        write-host "[Error] " -nonewline -fore darkred; print "Host $target_host is down" -fore darkred
    }
}

function parse_sub_args([array]$sub_arg_lst)
{
    [hashtable]$sub_args = new-object hashtable

    foreach($arg_val in $sub_arg_lst)
    {
        try{$a = $arg_val.split('=')}
        catch{write-host '[Error] ' -fore darkred -nonewline; write-host "Invalid argument $arg_val"; break}
        
        $sub_args.add($a[0], $a[1])
    }

    return $sub_args
}


$sub_args = parse_sub_args($args[0])

if ($sub_args.item('host'))
{
    session -target_host $sub_args.item('host') -proj $sub_args.item('proj') -extra $sub_args.item('extra')
}
elseif ($sub_args.item('hostlist'))
{


}


