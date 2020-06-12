<#
.SYNOPSYS
    Remove files/items in folder that are aged
.DESCRIPTION

.PARAMETER Age
    [int] max Age for item until it is removed.
.Parameter folder
    [string] Folder to clean up
.NOTES

    *** DISCLAIMER ***

    This software is provided "AS IS", without warranty of any kind, express or implied, 
    fitness for a particular purpose and noninfringement. 
    In no event shall the authors or copyright holders be liable for any claim, damages or other liability,
    whether in an action of contract, tort or otherwise, arising from, 
    out of or in connection with the software or the use or other dealings in the software.
#>
function remove-AgedItems {
    [cmdletbinding()]
    param (
        [int]$Age,
        [string]$folder
    )

    #-- input validation
    if ($age -lt 1) {
        write-host "Invalid age given $age [days], we will use 30 days as default."-ForegroundColor Yellow
        $age=30
        }
    if ($folder.Length -lt 3) {
        write-host "Folder to cleanup is invalid, exit script." -ForegroundColor Yellow
        return
    }
    if (!(test-path $folder)) {
        write-host "Failed to find $folder, exiting script."-ForegroundColor Yellow
        return
    }
    #-- select root folder and its childrens
    $rootFolder=Get-item $folder
    $childrens=get-childitem $rootFolder
    #-- log threshold date
    $thresholdDate=(get-date).AddDays(-1*$age)
    Write-host ("Files and folders in $folder that are created on or before {0:dd MMM yyyy} will be deleted." -f $thresholdDate)
    #-- check if there are childrens that are older then a certain age
    $currentDate=get-date
    $itemsToClean=$childrens | ?{((get-date) - $_.CreationTime ).days -ge $age} 
    if ($itemsToClean.count -le 0) {
        write-host "Nothing to cleanup in $folder" -ForegroundColor cyan
        return
    }
    #-- remove items
    $itemsToClean | Remove-Item -Recurse -Force -Confirm:$false
}    