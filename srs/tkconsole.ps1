using namespace System;
using namespace Systems.Collections.Generic
# Import-Module ActiveDirectory

function main
{
    $parser = [ArgumentParser]::new()
    $parser.add_argument('-a')
    $parser.add_argument('-b')
    $parser.add_argument('-c')
    $parser.add_argument('--argument')
    $parser.add_argument('--argument2')
    write-host $parser.args_to_parse
    write-host $parser.largs_to_parse
}

class ArgumentContainer
{
    [System.Collections.ArrayList]$arg_lst
    [string]$arg_str
    [string]$prefix
    [string]$action
    [System.Collections.ArrayList]$args_to_parse = @()
    [System.Collections.ArrayList]$largs_to_parse = @()
    [hashtable]$namespace = @{}
}

class ArgumentParser : ArgumentContainer
{
    # Regular expression to match any string that begins with a - character or 
    # by the -- followed by any number of characters
    [string]$RX_OPT_ARG = "^-{1}[a-zA-Z0-9]+"
    [string]$RX_OPT_LARG = "^-{2}[a-zA-Z0-9]+"
    [string]$RX_ARG = ""

    # use rx and match args and long args. arguments to parse for get added to ArgumentContainer.
    [void]add_optional_argument([string]$arg, [string]$dest, [bool]$required=$false)
    {
        if($arg -match $this.RX_OPT_ARG)
        {
            $this.args_to_parse.add($arg)
        }

        elseif($arg -match $this.RX_OPT_LARG)
        {
            $this.largs_to_parse.add($arg)
        }

    }
    
    [void]add_argument([string]$arg)
    {

    }


    # get input from user and return
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


