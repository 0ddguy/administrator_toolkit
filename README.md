# Administrator Toolkit
## Toolkit for Active Directory Administration
The Administrator Toolkit is a custom tool written on PowerShell that provides a wrapper for many Active Directory PS Cmdlets allowing users to interact with the domain controller, computer objects, and user accounts more efficiently. It allows administrators to run automated scripts, and queries to nodes and user objects.

## Installing (Windows)

The utility includes its own installer, adding it to a system is as simple as running the install.bat file located in the root of the install folder. The toolkit will be installed in the C:\Administrator_Toolkit directory and a shortcut will be created on the desktop.
Because a lot of the cmdlets used perform administrative actions, the program needs to be started using an account with domain admin permissions.

## Usage
``` 
 | Modes |
 Syntax: <mode> <optional args> <value>
    search     			-> Search for users, computers or IPv4 addresses  
    unlock        		-> Unlock a provided account
    reset         		-> Reset an account password
    ping          		-> Check if a host is up
    run           		-> Run a module
    list          		-> List installed modules, filters and modes

 | Switches |
    -f            		-> Specify filter from below 
    -h            		-> Specify host to search for
    -v            		-> Enable verbose output
    -p            		-> For use with reset mode; sets change at next login property to true
    --what-if     		-> Perfom what if operation on mode

 | Filters |
    1             		-> Full name surrounded by quotations
    2             		-> Employee ID
    3             		-> Computer name
    4             		-> IPv4 address

 | Modules |
 Modules are stored in scriptroot/scripts directory and can be selected using the 'use' command and arguments can be passed using the 'set' command and the 'to' keyword:	
  Ex:
    use my-module
    set host to server1
    set port to 56
    set verbose to false
    run 

 | Module related commands |
    list modules		-> list available modules
    use <module>		-> load specified module
    options			-> show options for loaded module    
    set <arg> to <val>  	-> set arguments for loaded module
    unset <arg>			-> unset argument for loaded module
    run				-> run selected module

 | Usage examples |
    <mode> <options>
    Ex:
    search -f 2 123456
    search -f 1 "John Smith"
    unlock -f 2 123456
    ping google.com
    list modules
    search -f 4 10.10.10.10
    reset --what-if -f 1 -p "Alice Wellington"
```
