using namespace System;
using namespace Systems.Collections.Generic
# Import-Module ActiveDirectory

function main
{

    $parser = [ArgumentParser]::new()
    $namespace = $parser.get_str()
    $namespace
    # do
    # {
    #     Write-Host "$(echo %cd%)>" -NoNewLine -ForegroundColor DarkCyan
        
    # } while($input -ne 'quit' -or $input -ne 'q')
}

class ArgumentParser
{
    [string]$stream
    [hashtable]$namespace
    [Collections.ArrayList]$argvs

    [string]get_str() 
    {
        $h = Get-Host
        $this.stream = $h.UI.ReadLine()
        return $this.stream
    }

    [Collections.ArrayList]add_argument([string]$arg, [string]$action, [bool]$mandatory)
    {
        $this.argvs = 
        return $this.argvs
    }

}

main
