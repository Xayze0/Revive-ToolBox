# Script Parameters for Revive-ToolBox.ps1
<#
    Author             : Bryant Bennett
    Last Edit          : BB - 07/07/2020
#>

@{
    #-- Revive Image.exe Command Args
        RVImageCmdArg1 = "qp"
        RVImageCmdArg3 = 'd=$n'
        
        RVTools = [ordered]@{ RTCollectBackupSizes = "Collect Backup Sizes"; RTSPXErrors = "Find SPX Errors in logs"; RTRemoveOldInc = "Move unrequired .SPI Files" ; RTVerifyChain = "Verify Chains"}

        RVToolsIM = [ordered]@{RTIMUsageReport = "IM Usage Report (Under Construction)"}

        Title = "Revive-ToolBox"

        Version = "3.0.3"  

        Exclusions = "Old Chains","spf.tmp","bitmap","OldChains","Incrementals"
           
        IMLogQuerry = "Collapse Daily Exception: Monthly collapse aborted due to verification status of the following files: ReverifyQueued :"
}