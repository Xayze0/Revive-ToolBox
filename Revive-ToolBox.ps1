<#
SYNOPSIS
    Collection Of Tools For Revive Managment Tasks
DESCRIPTION
    #--
EXAMPLE
    #--
NOTES
    File Name          : Revive-ToolBox.ps1
    Author             : Bryant Bennett
    Prerequisite       : Preruiqisites like
                         Min. PowerShell version : 2.0
                         PS Modules and version : 
    Last Edit          : BB - 07/07/2020

#>
[CmdletBinding()]
Param(
    #-- 
)

Begin{
    $ts_start=get-date #-- note start time of script
    #-- initialize environment
    $DebugPreference="SilentlyContinue"
    $VerbosePreference="Continue"
    $ErrorActionPreference="Continue"
    $WarningPreference="Continue"
    clear-host 

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
    #--

#endregion
}



Process{
    #--
    $CMD = Find-ImagePath

    do{
        Show-Menu -Title $P.Title -Version $p.Version -RVTools $p.RVTools
        $UserInput = Read-Host "Please make a selection"

        #Can I make this a Dynamic Switch???
        #Updated
        switch ($UserInput)
        {
                '1' {
                    RTCollectBackupSizes -Exclusions $p.Exclusions
              } '2' {
                    RTSPXErrors 
              } '3' {
                    RTRemoveOldInc -Exclusions $p.Exclusions -RVCMDarg1 $p.RVImageCmdArg1 -RVCMDarg3 $p.RVImageCmdArg3
              } '4' {
                    RTVerifyChain -Exclusions $p.Exclusions -RVCMDarg1 $p.RVImageCmdArg1 -RVCMDarg3 $p.RVImageCmdArg3
              } '5' {
                    Write-Host "These are not the droids your looking for"
              } '6' {
                    Write-Host "These are not the droids your looking for"
              } 'q' {
                   return
              }
        }
        Pause
   }until ($UserInput -eq 'q')
}


End{
    #-- 
    exit-script -finished_normal
}
#####
