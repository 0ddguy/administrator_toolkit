# Administrator Toolkit
## Toolkit for Active Directory Administration
The Administrator Toolkit is a custom tool written on PowerShell to streamline Active Directory tasks like resetting passwords, unlocking accounts and querying user and computer objects. The tool uses a command-line interface with a combination of filters and switches to perform various on the Domain Controller.

# Installation and Usage
## Clone Git repo:
```
git clone https://github.com/disastrpc/administrator_toolkit.git
```
## Linux:
**Install PowerShell packages:**

**Ubuntu**
```
sudo apt-get install -y powershell && sudo apt-get install -y powershell-preview
```
**CentOS, RedHat**
```
sudo yum install -y powershell && sudo yum install -y powershell-preview
```
**Fedora**
```
sudo dnf install -y powershell && sudo dnf install -y powershell-preview
```
**Download with:**
```
wget https://github.com/disastrpc/administrator_toolkit/archive/master.zip
```
## Installing (Windows)

The utility includes its own installer, adding it to a system is as simple as running the install.bat file located in the root of the install folder. The toolkit will be installed in the C:\Administrator_Toolkit directory and a shortcut will be created on the desktop.
Because a lot of the cmdlets used perform administrative actions, the program needs to be started using an account with domain admin permissions.

## Usage
```
Modes:
    search      -> Search for users, computers or IPv4 addresses  
    unlock      -> Unlock a provided account
    reset       -> Reset an account password
    ping        -> Check if a host is up

 Filters:
    -f          -> Specify filter from below 
    1           -> Full name surrounded by quotations
    2           -> Employee ID
    3           -> Computer name
    4           -> IPv4 address

 Switches:
    -q          -> Specify string to query for
    -h          -> Specify host to search for
    -v          -> Enable verbose output
    -p          -> For use with reset mode; sets change at next login property to true
    --what-if   -> Perfom what if operation on mode

 Usage:
    <mode> <options>
    Ex:
    search -f 2 -q 123456
    search -f 1 -q "John Smith"
    unlock -f 2 -q 123456
    ping -h google.com
    search -f 4 -q 10.10.10.10
    reset --what-if -f 1 -q "Alice Wellington" -p
```
