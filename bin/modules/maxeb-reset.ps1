# WIP!

[void] [System.Reflection.Assembly]::LoadWithPartialName("'System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("'Microsoft.VisualBasic")

# workaround for IE's low integrity mode, this makes it so that the script does not have to be run with administrative privileges
# it takes the handle for the IE process as a parameter and returns the reconnected IE instance
# security zones allow data to be sent from a medium level to a low level zone but data cannot be sent from a low level to a medium level zone
function reconnectIEHandle() 
{
    param($handle)

    # create a shell com object
    $shellapp = new-object -comobject shell.application 
    try
    {
        $err = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
        # find the IE window handle to be returned
        $ieobj = $shellapp.windows() | ?{$_.HWND -eq $handle}
    } 
    catch 
    {
        # if not found in the first try wait for 500 ms and retry
        sleep -milliseconds 500
        try 
        {
            $ieobj = $shellapp.windows() | ?{$_.HWND -eq $handle}
            $ieobj.visible = $true
        } 
        catch 
        {
            $ieobj = $null
        }     
    } 
    finally 
    { 
        $ErrorActionPreference = $err
        $shellapp = $null
    }
    return $ieobj
} 

# check if IE process is busy
function checkBusy()
{
    [cmdletbinding()]
    param(
        [parameter(
            mandatory,
            valuefrompipeline
        )]
        $ieobj
    )

    while ($ieobj.busy) 
    {
        sleep -milliseconds 100
    }
}

# Session ID needs to be passed to the URL in order for the login form to be proccesed, even if the cookie value changes upon login
$session_id = ''

# # get user credentials, password is passed in as an encrypted string and decrypted only upon authentication
# write-host "Enter your MaxEB username: " -nonewline
# $uname = $host.UI.ReadLine()
# write-host "Enter your MaxEB password: " -nonewline
# $pass = $host.UI.ReadLineAsSecureString()

$uname = ''
$depass = ''

# create IE object and get the window handle
$handle = ($ie = new-object -ComObject "InternetExplorer.Application").HWND
$ie | checkBusy
$ie.visible = $true
$ie.navigate("https://nyeb.maximus.com/eb/pages/main.jsf;jsessionid=$session_id")

# reconnect process handle
$ie = reconnectIEHandle -handle $handle
$ie | checkBusy
$doc = $ie.Document
$ie | checkBusy

# fill out login forms for username and password
$uname_form = $doc.IHTMLDocument3_GetElementsByTagName("input") | ? {$_.name -eq 'loginform:username'}
$pass_form = $doc.IHTMLDocument3_GetElementsByTagName("input") | ? {$_.name -eq 'loginform:password'}
$sub = $doc.IHTMLDocument3_GetElementsByTagName("input") | ? {$_.name -eq 'loginform:j_id31'}
$uname_form.value = $uname

# decrypt password, $depass gets assigned null after authentication 
# $depass = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($pass))
$pass_form.value = $depass; $depass = $null
$sub.click()
$ie = reconnectIEHandle -handle $handle
$ie | checkBusy
$doc = $ie.Document
$ie | checkBusy
# $doc.IHTMLDocument3_GetElementsByTagName("input") | select-object type,name
$ie | checkBusy
$search_form = $doc.IHTMLDocument3_GetElementsByTagName("input") | ? {$_.name -eq 'sysadmin_staff_search_form:staffNumber'}
$ie | checkBusy
$search_form.value = "247618"
$ie | checkBusy
$sub = $doc.IHTMLDocument3_GetElementsByTagName("input") | ? {$_.name -eq 'sysadmin_staff_search_form:submit'}
$sub.click()
$ie | checkBusy
$doc = $ie.Document
$ie | checkBusy
Invoke-RestMethod -Uri https://nyeb.maximus.com/eb/pages/main.jsf








