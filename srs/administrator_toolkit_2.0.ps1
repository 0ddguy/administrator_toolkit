using namespace System;
using namespace Systems.Collections.Generic
# Import-Module ActiveDirectory

function main
{
    $parser = [ArgumentParser]::new()
    $parser.add_argument('-a')
    $parser.add_argument('--argument')
    write-host $parser.arg_lst
    # Write-Host $parser.argument_string
    # do
    # {
    #     Write-Host "$(echo %cd%)>" -NoNewLine -ForegroundColor DarkCyan
    #
    # } while($input -ne 'quit' -or $input -ne 'q')
}

class ArgumentContainer
{
    [System.Collections.ArrayList]$arg_lst
    [string]$arg_str
    [string]$prefix
    [System.Collections.ArrayList]$args_to_parse = @()
    [System.Collections.ArrayList]$largs_to_parse = @()
    [hashtable]$namespace = @{}
}

class ArgumentParser
{

    [ArgumentContainer]$container

    # Match any string that begins with a - characters followed by any number of characters
    [string]$RX_ARG = "^-{1}[a-zA-Z0-9]+"
    [string]$RX_LARG = "^-{2}"

    [void]add_argument([string]$arg)
    {
        write-host $arg
        if($arg -match $this.RX_ARG)
        {
            write-host $arg
            write-host $this.container.args_to_parse.GetType()
            $this.container.args_to_parse.add($arg)
        }
        elseif($arg -match $this.RX_LARG)
        {
            write-host $arg
            $this.container.args_to_parse.add($arg)
        }
    }

    [string]get_arg_string() 
    {
        $h = get-host
        $this.arg_str = $h.UI.readline()
        return $this.container.arg_str
    }

    [System.Collections.ArrayList]parse_str_args()
    {

        return $Null
    }


}


main


