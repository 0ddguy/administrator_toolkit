using namespace System;
using namespace Systems.Collections.Generic
# import-module activedirectory
$PSver = $PSversiontable.PSversion
$ver = '2.0'
# $dom = get-addomain -current localcomputer
# load startup art

class DomainHandler
{
    [void]search([int]$filter, [string]$crit)
    {
        write-host $filter $crit
    }

    [void]unlock([int]$filter, [string]$crit)
    {
        write-host $filter $crit
    }
}

# Contains lists and actions used in ArgumentParser
class ArgumentContainer
{
    [System.Collections.ArrayList]$arg_lst
    [System.Collections.ArrayList]$arg_lst_to_consume
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

    [void]parse_args()
    {
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
    $art_count = (dir $art_source | measure).count
    $n = get-random -maximum $art_count
    $get_art = join-path -path $art_source -childpath $n
    get-content -raw $get_art | write-host
    write-host "by Jared Freed | GNU General Public License | ver $ver"
    write-host "Host: " -nonewline -foregroundcolor darkyellow; write-host "$(hostname)"
    if($dom -eq $null){write-host "Domain: " -foregroundcolor darkyellow -nonewline; write-host "No domain detected"}
    else{write-host "Domain: $dom" -foregroundcolor darkyellow}
    write-host "PS version: $PSver" -foregroundcolor darkblue
    write-host "Enter " -nonewline; write-host "help " -nonewline -foregroundcolor darkgreen; write-host 'for usage'
}

function main
{
    $parser = [ArgumentParser]::new()
    $handler = [DomainHandler]::new()
    startup

    do
    {
        write-host "$(whoami)@tkc>" -nonewline
        $parser.parse_args()
        if($parser.namespace.mode -eq 'search')
        {
            $handler.search($parser.namespace.item('-f'), $parser.namespace.item('-i'))
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


