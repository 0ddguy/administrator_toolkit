$computers = Get-ADComputer -SearchBase $searchbase -filter "enabled -eq 'true'"

function get_comp($username, $computers)
{
    foreach ($comp in $computers)
    {
        $Computer = $comp.Name
        write-host $Computer
        if(test-connection -computername $Computer -quiet)
        {
            #Get explorer.exe processes
            $proc = gwmi win32_process -computer $Computer -Filter "Name = 'explorer.exe'"
            #Search collection of processes for username
            ForEach ($p in $proc) 
            {
                $temp = ($p.GetOwner()).User
                if ($temp -eq $user)
                {
                    write-host "$user is logged on $Computer"
                    break
                }
            }
        }
    }
}

function parse_sub_args($arg_list)
{
    [hashtable]$sub_args = new-object hashtable
    foreach($arg_val in $arg_list)
    {
        try{$a = $arg_val.split('=')}
        catch{write-host '[Error] ' -fore darkred -nonewline; write-host "Invalid argument $arg_val"; break}
        
        $sub_args.add($a[0], $a[1])
    }

    return $sub_args
}

function parse_path([string]$path)
{
    [Systems.Collection.ArrayList]$CN = @()
    $path_arr = $path.split('/')
    $dom = get-addomain -current localcomputer
    $forest = $dom.forest.split('.')
    $len = $path_arr.count + $forest.count

    do 
    {
        if($len - 2 -eq 0)
        {
            $CN.add("DC="+$forest[0])
            $CN.add("DC="+$forest[1])
            $len = 0
        }
        else
        {
            $CN.add("OU="+$path[$len])
            $len--
        }

    } 
    until ($len -eq 0)

}
function main($a)
{
    $arg_list = $a.split(' ')
    write-host($arg_list)
    $sub_args = parse_sub_args($arg_list)
}

$a = $args[0]
main($a)


