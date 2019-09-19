using namespace System;
using namespace Systems.Collections.Generic
# Import-Module ActiveDirectory

function main
{
    $parser = [ArgumentParser]::new()
    $parser.add_positional_argument('arg')
    $parser.add_positional_argument('arg2')
    $parser.add_positional_argument('arg3')
    $parser.add_optional_argument('-a')
    $parser.add_optional_argument('-b')
    write-host $parser.positional_argvs 
    write-host $parser.optional_argvs
    # do
    # {
    #     Write-Host "$(echo %cd%)>" -NoNewLine -ForegroundColor DarkCyan
    #
    # } while($input -ne 'quit' -or $input -ne 'q')
}

class _ArgumentContainer
{
    [string]$argument_string
    [string]$prefix
    [actions]$action_container
    [hashtable]$namespace
    [Collections.ArrayList]$positional_argvs = @()
    [Collections.ArrayList]$optional_argvs = @()
}

class ArgumentParser : _ArgumentContainer
{

    [string]parse_arguments() 
    {
        $h = get-host
        $this.argument_string = $h.UI.ReadLine()
        return $this.argument_string
    }
}

class Actions : _ArgumentContainer
{
    [string]$dest
    [string]$type
}

class DestAction : Action
{
    
}

main


