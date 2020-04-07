# argparse - A regex based command line argument parser
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

set-alias -name print -value write-host

class ArgumentContainer
{
    [System.Collections.ArrayList]$arg_list = @()
    [System.Collections.ArrayList]$argkeys = @()
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
}

# Parses arguments and adds them to namespace hashtable. 
class ArgumentParser : ArgumentContainer
{
    [void] parse_args([string]$arg_str)
    {
        # clear namespace at beginning of invocation
        $this.namespace.clear()

        $this.arg_str = $arg_str
        $this.arg_list = $this.arg_str.split(' ')

        # initialize pointers and flags
        [int]$p1 = 0
        [int]$p2 = 0
        [bool]$mf = $false
        [bool]$vf = $false
        [bool]$tf = $false

        # iter through argument list
        foreach($v in $this.arg_list)
        {
            # mode argument will always be at index 0
            if($p1 -eq 0 -and ! $mf)
            {
                # check if .val is after the first argument
                if($this.arg_list[$p1 + 1] -match $this.RX_OPT_ARG -or $this.arg_list[$p1 + 1] -match $this.RX_OPT_LARG){} # pass
                else
                {
                    # assign val and trigger flag
                    $this.namespace.val = $this.arg_list[$p1 + 1]
                    $vf = $true
                }

                $this.namespace.mode = $v
                $p1++
                $mf = $true
                continue
            }
            
            # grab .val value
            if($this.arg_list[$p1 + 1] -eq $null -and ! $vf)
            {
                $this.namespace.val = $v
                $vf = $true
                continue
            }

            # grab 'to' keyword value
            if($v -eq 'to' -and ! $tf)
            {   
                $p1 += 1
                if($this.arg_list[$p1].startswith('"'))
                {
                    $p2 = $p1
                    do {$p2++} until ($this.arg_list[$p2].endswith('"'))
                    $val = $this.arg_list[$p1..$p2].replace('"','')
                    $this.namespace.kw_to = $val
                    $tf = $true
                    $p1 -= 1
                    continue
                }
                else
                {
                    $this.namespace.kw_to = $this.arg_list[$p1]
                    $p1 -= 1
                    $tf = $true
                    continue
                }
            }

            # grab .val value in quotes if flag hasn't been triggered
            elseif(! $vf)
            {
                if($this.arg_list[$p1 + 1].startswith('"'))
                {
                    do {$p2++} until ($this.arg_list[$p2 + 1] -eq $null)
                    $p1 += 1
                    $val = $this.arg_list[$p1..$p2].replace('"','')
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
                if($this.arg_list[$p1 + 1] -match $this.RX_OPT_ARG -or $this.arg_list[$p1 + 1] -match $this.RX_OPT_LARG)
                {
                    $this.namespace[$v] = $true
                }

                # check if argument is followed by .val
                if($null -eq $this.arg_list[$p1 + 2])
                {
                    $this.namespace[$v] = $true
                }
                
                # detect if argument contains a string value surrounded by quotations
                elseif($this.arg_list[$p1 + 1].startswith('"'))
                {
                    # set p2 to p1
                    $p2 = $p1

                    # increment p2 until the other quote is found
                    do {$p2++} until ($this.arg_list[$p2].endswith('"'))

                    # move pointer to beginning of string
                    $p1 += 1

                    # string value is between $p1 + 1 and $p2, assign to namespace
                    $this.namespace[$v] = $this.arg_list[$p1..$p2]

                    # set p1 back
                    $p1 -= 1
                }
                
                # check for comma separated values
                elseif($this.arg_list[$p1 + 1].contains(','))
                {
                    $sub_lst = $this.arg_list[$p1 + 1]
                    $p2 = $p1
                    $p1 += 1
                    $this.namespace[$v] = $sub_lst.split(',')
                    $p1 -= 1
                }

                else
                {
                    # assign value to namespace
                    $this.namespace[$v] = $this.arg_list[$p1 + 1]
                }
            }
            
            $p1++

        }
        
    }
    [void] set_module_arg([string]$mod, [string]$key, [string]$val)
    {
        
        $fname = $mod + '-args' + '.dat'

        if($fname.startswith("ps-"))
        {
            $fname = $fname.replace('.ps1', '')
        }
        
        if( ! (test-path -path "$PSScriptRoot\tmp\$fname"))
        {
            try{new-item -path "$PSScriptRoot\tmp" -name "$fname" -itemtype 'file' -force >$null}
            catch{print "[Error] " -nonewline -fore darkred; print "Unable to create args file, make sure you have access to $PSScriptRoot\tmp"}
        }
    
        $content = $key + '=>' + $val
        try
        {

            # gather current args into list
            foreach($line in (get-content -path "$PSScriptRoot\tmp\$fname"))
            {
                $line = $line.split("=>")
                $this.argkeys.add($line[0])
            }

            if($key -in $this.argkeys)
            {
                print("triggered")
                set-content -path "$PSScriptRoot\tmp\$fname" -value (get-content -path "$PSScriptRoot\tmp\$fname" | select-string -pattern "$key" -notmatch >$null)
                add-content -path "$PSScriptRoot\tmp\$fname" -value $content >$null
            }
            else
            {
                add-content -path "$PSScriptRoot\tmp\$fname" -value $content >$null
            }
    
            print "Set: $key => $val"
        }
        catch{print "[Error] " -nonewline -fore darkred; print "Unable to set argument, make sure you have access to $PSScriptRoot\tmp"}
    }
    
    [void] unset_module_arg([string]$mod, [string]$key)
    {
        $fname = $mod + '-args' + '.dat'

        if($fname.startswith("ps-"))
        {
            $fname = $fname.replace('.ps1', '')
        }

        if (test-path -path "$PSScriptRoot\tmp\$fname")
        {
            try
            {
                if($key -eq 'all'){print "Unset all for module $mod"; remove-item -path "$PSScriptRoot\tmp\$fname"}
                else
                {
                    print "Unset: " -nonewline -fore darkyellow; print "$key"
                    set-content -path "$PSScriptRoot\tmp\$fname" -value (get-content -path "$PSScriptRoot\tmp\$fname" | select-string -pattern "$key" -notmatch)
                }
            }
            catch{print "[Error] " -nonewline -fore darkred; print "Unable to unset argument"}
        }
    }
    # prints options that have been set for a specific module
    [void] get_module_args([string]$mod)
    {
            $fname = $mod + '-args' + '.dat'

            if($fname.startswith("ps-"))
            {
                $fname = $fname.replace('.ps1', '')
            }

            if(test-path -path "$PSScriptRoot\tmp\$fname")
            {
                print "Arguments for $mod"
                foreach($line in get-content -path "$PSScriptRoot\tmp\$fname")
                {
                    print "| $line |"
                }
            }
            else{print "[Error] " -nonewline -fore darkred; print "Unable to read options, try running 'unset all' and resetting arguments"}
    }
    # get input from user
    [string] get_args() 
    {
        $h = get-host
        $this.arg_str = $h.UI.readline()
        return $this.arg_str
    }

}
