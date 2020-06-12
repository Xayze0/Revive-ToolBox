<#
.SYNOPSIS
   Small description - oneliner - 
.DESCRIPTION
   Script usage description [optional]
.EXAMPLE
    One or more examples for how to use this script
.NOTES
    File Name          : <filename>.ps1
    Author             : <Script Author>
    Prerequisite       : <Preruiqisites like
                         Min. PowerShell version : 2.0
                         PS Modules and version : 
                            PowerCLI - 6.0 R2
    Version/GIT Tag    : <GIT tag>
    Last Edit          : <Initials> - <date>

#>
[CmdletBinding()]
Param(
    #-- Define Powershell input parameters (optional)
    [string]$text
)

Begin{
    $ts_start=get-date #-- note start time of script
    #-- initialize environment
    $DebugPreference="SilentlyContinue"
    $VerbosePreference="Continue"
    $ErrorActionPreference="Continue"
    $WarningPreference="Continue"
    clear-host #-- clear CLi

	#-- determine script location and name
    $scriptPath=(get-item (Split-Path -Path $MyInvocation.MyCommand.Definition)).FullName
    $scriptname=(Split-Path -Leaf $MyInvocation.mycommand.path).Split(".")[0]
    
    #-- Load Parameterfile
    if (!(test-path -Path $scriptpath\parameters.ps1 -IsValid)) {
        write-warning "Cannot find parameters.ps1 file, exiting script."
        exit
    } 
    $P = & $scriptpath\parameters.ps1

    #-- load functions
    if (Test-Path -IsValid -Path($scriptpath+"\functions\functions.psm1") ) {
        write-host "Loading functions" -ForegroundColor cyan
        import-module ($scriptpath+"\functions\functions.psm1") -DisableNameChecking -Force:$true #-- the module scans the functions subfolder and loads them as functions
    } else {
        write-verbose "functions module not found."
        exit-script
    }
    
#region for Private script functions
    #-- note: place any specific function in this region

#endregion
}

End{
    #-- we made it, exit script.
    exit-script -finished_normal
}

Process{
#-- note: area to write script code.....
    write-host "hello world"
}

