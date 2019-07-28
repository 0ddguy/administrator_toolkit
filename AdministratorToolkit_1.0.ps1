$ver = '1.0'
#impose limit of 4 params 
#func search ID or name
#func add security group
Write-Host "== Administrator Toolkit - Ver $ver =="
Write-Host "By Jared Freed - 07/27/19/"
function Push_Console {
    do {
        Write-Host "$(hostname)/$(whoami)>" -NoNewLine
        $input = Parse
        if($input[0] -eq 'unlock') {
            try {
            $EID = $input[1] 
            Unlock -EID $EID
            } catch [System.Exception] {Write-Host "Invalid parameters, please try again"}
        } elseif($input[0] -eq 'reset') {
            try {
            $EID = $input[1]
            $pass = $input[2]
            Reset -EID $EID -pass $pass
            } catch [System.Exception] {Write-Host "Invalid parameters, please try again"}
        } elseif($input[0] -eq 'key'){
            try{Get_Key} catch [System.Exception] {Write-Host "Invalid parameters, please try again"}
        } elseif($input[0] -eq 'help') {
            try {ShowHelp} catch [System.Exception] {Write-Host "Invalid parameters, please try again"}
        } elseif($input[0] -eq 'clear') {try{Clear-Host}catch{[System.Exception] {Write-Host "Invalid parameters, please try again"}}
        } else {
            Write-Host "Invalid command"
            ShowHelp
        }
    } until ($input[0] -eq 'quit')
}

function Parse {

    $input = $Host.UI.ReadLine()
    $par = $input.Split(' ')
    $cmd = $par[0]
    $par1 = $par[1]
    $par2 = $par[2]
    $par3 = $par[3]

return $cmd,$par1,$par2,$par3
}
function Unlock {
    param (
        [Parameter(Mandatory=$true)]
        [String]$EID
    )
    Write-Host "ID provided is $EID"
    Write-Host "AD-Unlock goes here"
}
function Reset {
    param ([Parameter(Mandatory=$true, Position=0)]
        [String]$EID,
        [Parameter(Mandatory=$false, Position=1)]
        [String]$pass
    )

    Write-Host "Reset got ID $EID"
    Write-Host "Reset got $pass"

    if($pass -eq '') {
        Write-Host "No password supplied"
    } else {
        Write-Host "Password is $pass"
    }
}
function ShowHelp {

    Write-Host "====== Usage ======"
    Write-Host "clear - Clear screen"
    Write-Host "unlock <employee ID> <param> - Unlocks specified user"
    Write-Host "Optional params: -c (Check if account is locked)"
    Write-Host "reset <employee ID> <password> <param> - Resets password to specified value, if no password is provided defaults to Maximus1"
    Write-Host "Optional params: -u (Call upon the Unlock function to unlock account aswell"
    Write-Host ''
}

Push_Console
