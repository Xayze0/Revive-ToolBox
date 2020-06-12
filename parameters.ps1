# Script Parameters for <scriptname>.ps1
<#
    Author             : <Script Author>
    Last Edit          : <Initials> - <date>
#>

@{
    #-- Revive Image.exe Command Args
        RVImageCmdArg1 = "qp"
        RVImageCmdArg2 = 'd=$n'
        
        RVTools = [ordered]@{ RTCollectBackupSizes = "Collect Backup Sizes"; RTSPXErrors = "Find SPX Errors in logs"; RTRemoveOldInc = "Move unrequired .SPI Files" ; RTVerifyChain = "Verify Chains"}

        Title = "Revive-ToolBoxx"

        Version = "3.0.0"
                    
}