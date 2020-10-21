Function Show-Menu{
    #Dynamic Menu Display Starting At 1
    param (
            [Parameter(Mandatory=$true)]
            [string]$Title,
            [Parameter(Mandatory=$true)]
            [string]$Version,
            [Parameter(Mandatory=$true)]
            [System.Collections.Specialized.OrderedDictionary]$RVTools 
    )
    Clear-Host
        Write-Host "===================[ $Title ]====================[v$Version]"
        Write-Host "    ____"
        Write-Host " .-'   / "
        Write-Host ".'    /   /`."
        Write-Host "|    /   /  |  " 
        Write-Host "|    \__/   |  "
        Write-Host " .         .'  "
        Write-Host "   .     .'    "
        Write-Host "    | ][ |     " 
        $count = 1
        foreach ($tool in $RVTools.Values) {
        $bar =     "    | ][ |     : Press '$count' to ' "+ $tool
        Write-Host $bar
        $count++
        }
        Write-Host "    | ][ |     : Press Q to Close  "
        Write-Host "  .'  __   ."
        Write-Host "  |  /  \  |"
        Write-Host "  |  \__/  |"
        Write-Host "  `.       '"
        Write-Host "     ----'  "



}

Function Find-ImagePath{
    #Finds image.exe file depending on the system 32\64 bit and SPX and non SPX installs
    if (Test-Path 'C:\Program Files (x86)\StorageCraft\ShadowProtect\image.exe'){
        $CMD = 'C:\Program Files (x86)\StorageCraft\ShadowProtect\image.exe'
    }else{
        if (Test-Path 'C:\Program Files\StorageCraft\image.exe' ){
            $CMD = 'C:\Program Files\StorageCraft\image.exe'
        }else{
            if (Test-Path 'C:\Program Files (x86)\StorageCraft\ShadowProtect\spx\image.exe'){
                $CMD = 'C:\Program Files (x86)\StorageCraft\ShadowProtect\spx\image.exe'
            }else{
                if (Test-Path 'C:\Program Files\StorageCraft\spx\image.exe' ){
                    $CMD = 'C:\Program Files\StorageCraft\spx\image.exe'
                }else{
            
                }
            }
        }
    }
    return $CMD
}

Function Select-DriveLetter {
    #Collect all non a-c drives on the system and haves the end user pick one.
    #Can Also be overridden with a file path to return the filepath
    $drives = Get-Volume | Where-Object {$_.DriveLetter -match '^[d-z]$'} | Sort-Object -Property DriveLetter

    Write-Host "[Drive Letters]"  -ForegroundColor Cyan

    foreach ($drive in $drives){
        $echostring = "  ["+$drive.DriveLetter+"]"
        Write-Host $echostring -ForegroundColor Yellow
    }

    $dletter = Read-Host "Pick a Drive Letter or Provide a Path"



    #Test letters.
    if ($drives.DriveLetter -contains $dletter){
        $drive = Get-Volume -DriveLetter $dletter
        $drive = $drive.DriveLetter + ":\"
        return $drive

    }else{
        if ($dletter.Length -ge 3){
            return $dletter.Trim('"')
        }
        else{
            Write-Host "Drive Letter Not Found" -ForegroundColor Red
            Write-Host "Try a Different Letter" -ForegroundColor Cyan

            Start-Sleep -Seconds 5
            Show-Menu 
        }
    }

}

Function Get-RVFiles{
    #Most Useful Function Here.
    #Collects a list of SPI or SPF files depending on switch used.
    #Some paramters allow for the return of the latest SPI files based on file's inumber
    #Also allows for providing of vol_letter in the form of C_VOL D_VOL to collect only items specific to the drive letter of the backed up server as all server letters just go under the same server name folder.
    [CmdletBinding()]
    param
    (
        [System.String[]]$SearchBase,
        
        [Parameter(Mandatory=$true,ParameterSetName="WithSPF")]
        [Switch]
        $SPF,

        [parameter(Mandatory=$true,ParameterSetName="WithSPI")]
        [Switch]
        $SPI,

        [Switch]
        $Latest,

        [parameter(Mandatory=$true)]
        [string[]]
        $Exclusions,

        [string[]]
        $VOL_Letter


    )
    PROCESS
    {
        if ($SPF){
            $filter=@("*.spf")
        }
        if ($SPI){
            $filter=@("*.spi")
        }
        if ($SearchBase){
            $SearchBase = $SearchBase
        }else{
            $SearchBase = Select-DriveLetter
        }

        #Starts Defining Filter Script elements based on paramters used
        $WhereString = @()
        foreach ($Exclusion in $Exclusions) {
            #Build the Where array                     
            $WhereString += "(`$_.FullName -notlike '*$Exclusion*')"         
        }

        if ($VOL_Letter){
            $WhereString += "(`$_.FullName -like '*$VOLLetter*')"
        }

        #Forms Script Block Object to be used as filter
        $WhereString = $WhereString -Join " -and " 
        $WhereBlock = [scriptblock]::Create($WhereString)
        $files = Get-ChildItem -recurse ($SearchBase) -include ($filter) -File | Where-Object -FilterScript $WhereBlock
        
        #If Latest Parameter is defined then return the latest based on the iNumber of the chain and return only that file.
        if ($Latest){
            $highesti = 1
            $highestFile = ""
            foreach ($file in $files) {
                $currenti = [int](($file.Name   -replace '.+?(?=[i]\d+)' , '' -replace "[^\d+]*$","").Substring(1)) 
                if ($currenti -gt $highesti){
                    $highestFile = $file
                    $highesti = $currenti

                }
            }
            return $highestFile
        }   
        
        #Else Return All Files you searched for.
        return $files
    }
}

Function Remove-StringSpecialCharacter{
<#
.SYNOPSIS
    This function will remove the special character from a string.

.DESCRIPTION
    This function will remove the special character from a string.
    I'm using Unicode Regular Expressions with the following categories
    \p{L} : any kind of letter from any language.
    \p{Nd} : a digit zero through nine in any script except ideographic 

    http://www.regular-expressions.info/unicode.html
    http://unicode.org/reports/tr18/

.PARAMETER String
    Specifies the String on which the special character will be removed

.SpecialCharacterToKeep
    Specifies the special character to keep in the output

.EXAMPLE
    PS C:\> Remove-StringSpecialCharacter -String "^&*@wow*(&(*&@"
    wow
.EXAMPLE
    PS C:\> Remove-StringSpecialCharacter -String "wow#@!`~)(\|?/}{-_=+*"

    wow
.EXAMPLE
    PS C:\> Remove-StringSpecialCharacter -String "wow#@!`~)(\|?/}{-_=+*" -SpecialCharacterToKeep "*","_","-"
    wow-_*

.NOTES
    Francois-Xavier Cat
    @lazywinadmin
    www.lazywinadmin.com
    github.com/lazywinadmin
#>
    [CmdletBinding()]
    param
    (
    [Parameter(ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [Alias('Text')]
    [System.String[]]$String,

    [Alias("Keep")]
    #[ValidateNotNullOrEmpty()]
    [String[]]$SpecialCharacterToKeep
    )
    PROCESS
    {
    IF ($PSBoundParameters["SpecialCharacterToKeep"])
    {
        $Regex = "[^\p{L}\p{Nd}"
        Foreach ($Character in $SpecialCharacterToKeep)
        {
        IF ($Character -eq "-"){
            $Regex +="-"
        } else {
            $Regex += [Regex]::Escape($Character)
        }
        #$Regex += "/$character"
        }
    
        $Regex += "]+"
    } #IF($PSBoundParameters["SpecialCharacterToKeep"])
    ELSE { $Regex = "[^\p{L}\p{Nd}]+" }

    FOREACH ($Str in $string)
    {
        #Write-Verbose -Message "Original String: $Str"
        $Str -replace $regex, ""
    }
    } #PROCESS
}

Function RTSPXErrors{
    #Looks over event log to find SPX errors.
    Clear-Host
    Write-Host "[ [Tool] Find SPX Errors in logs]" -ForegroundColor DarkCyan
    Write-Host "[....Collecting Log Files....]" -ForegroundColor Cyan

    Get-WinEvent -LogName Application -FilterXPath "*[System[TimeCreated[timediff(@SystemTime) <= 2592000000]]]" `
    | Where-Object {($_.ProviderName -eq "ShadowProtectSPX") -and ($_.LevelDisplayName -ne "Information")} `
    | Format-table -Property timecreated,message, @{name='Job Result'; expression={ if ($_.LevelDisplayName -eq "Information"){"Success"}else{"Error"} }} `

    Write-Host "[....Complete....]" -ForegroundColor Green
}

Function RTCollectBackupSizes  {
    #Collects the space used on the disk by each server and outlines the entire space used and the size of the latest BU1
    #Used mostly to assist with QR Process.
    #This is where this whole script started.
    [CmdletBinding()]
    param
    (
        [string[]]
        $Exclusions
    )
    PROCESS
    {
        Clear-Host
        Write-Host "[ [Tool] Collect Backup Sizes]" -ForegroundColor DarkCyan
    

        $files = Get-RVFiles -SPF -Exclusions $Exclusions
        #what if 0 files???

        $serverspath = ($files[0].FullName).Split('\')[0..(($files[0].FullName).Split('\').Count -3)] -join '\'


        $Servers = Get-ChildItem -Path $serverspath

        foreach ($Server in $Servers){
            Write-Host "  "
            Write-Host "  "
            Write-Host "---$server------------------------------" -ForegroundColor Green
        
            $Backups = Get-ChildItem $Server.FullName | Where-Object { ((!($_.PSIsContainer)) -and ($_.Name -notlike ".remote")) }

                $manyNames = @()

                foreach ($Backup in $Backups){
                    if ($Backup.Name.Split('_')[1].length -eq 1){
                        $manyNames+= $Backup.Name.Split('_')[1]
                    }else {
                        $manyNames+= $Backup.Name.Split('_')[0]
                    }
                    $Drives = $manyNames | Select-Object -uniq

                }

                foreach ($Drive in $Drives){
                    $ispswithF = Get-ChildItem $server.FullName | Where-Object { ($_.Name -like "*_$Drive*_VOL*.spi") -or ($_.Name -like "$Drive*_VOL*.spi") -or ($_.Name -like "$Drive*_VOL*.spf") -or ($_.Name -like "*_$Drive*_VOL*.spf") }

                    $totalSizeGB = [Math]::Round((($ispswithF | Measure-Object -Sum Length).Sum / 1GB),2)

                    Write-Host "  "
                    Write-Host "|$Drive :"

                    foreach ($isp in ($ispswithF | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1)){

                        $latestSize = [Math]::Round((($isp | Measure-Object -Sum Length).Sum / 1GB),2).ToString() + " GBs"

                        if ($latestSize -eq "0 GBs"){
                            $latestSize = [Math]::Round((($isp | Measure-Object -Sum Length).Sum / 1MB),2).ToString()  + " MB"
                        }

                        $Statement = "|  " +$isp.LastWriteTime + " |  "+ $latestSize
                        Write-Host $Statement

                    }





                    Write-Host "|$Drive : All Backups $totalSizeGB GBs"
                }
            Write-Host "[....Complete....]" -ForegroundColor Green
            
        }
    }

}

Function RTRemoveOldInc {
    #Moves unrequired Incremental files to the Root of the drive where the backup is stored. :\MM.dd.yyyy
    #I set it to move them as automating deletion of somethign so important as backups is not something this script is set so iron clad and unbreakable yet to do. And Revive staff can decide to remove after.
    #This functions maintains the folder structure for easy restore.
    [CmdletBinding()]
    param
    (
        [string[]]
        $Exclusions,
        [string]
        $RVCMDarg1,
        [string]
        $RVCMDarg3
    )

    Clear-Host
    Write-Host "[ [Tool] Move unrequired INC to :\$(Get-Date -Format MM.dd.yyyy).]" -ForegroundColor DarkCyan
    $cmd = Find-ImagePath
    
    
    #Collect SPF Files
    Write-Host "[Collecting SPF Files]" -ForegroundColor Cyan
    $files = Get-RVFiles -SPF -Exclusions $Exclusions
    
    #What if 0 ???

    #Itterate SPF Files
    for ($i = 0 ; $i -lt $files.Count ; $i++){ 
        $file = $files[$i]
    
        #Collect chain specific to that vol letter
        $volLetter = $file.Name.Substring($file.Name.IndexOf('_VOL') - 1 ,1)+"_VOL"
    
        #collect all the spi files specific to that chain and find the latest one.
        $LatestSPI = Get-RVFiles -SPI -SearchBase $file.PSParentPath -Latest -Exclusions $Exclusions -VOL_Letter $volLetter
        
        #run comand to get a list of files to keep.
        $return = & $CMD $RVCMDarg1 $latestSPI.FullName $RVCMDarg3
    
        #Test to see if if there is a return a null return mean bad test
        if ($return -ne $null){
            
            #Cleanup the output of image.exe command
            $output = @()
            Foreach ($line in $return){
                if ($line -ne ""){
                    $clean = (Remove-StringSpecialCharacter -String $line -SpecialCharacterToKeep ':','.','"','_',' ','-','\').trim('"')
                    $output += ($clean.split('\')[$clean.split('\').count -1] ).Split('.')[0]
                }
            }
                
            #make a folder for old items to go to
            $folder =  $LatestSPI.DirectoryName+"\"+(Get-Date -Format MM.dd.yyyy)
            if (!(Test-Path -Path $folder)){ New-Item -ItemType Directory -Path $folder | Out-Null } 
            
            #Itterate SPFs and move unneded items to the folder made above
            $filesinVol = Get-RVFiles -SPI -Exclusions $Exclusions -VOL_Letter $volLetter -SearchBase $file.PSParentPath
            for ($v = 0 ; $v -lt $filesinVol.count; $v++){
                $item = $filesinVol[$v]
        
                $teststr = $item.Name.Split('.')[0]
                
                #If our test file is not in the required list
                if (!($output.Contains($teststr))){
                    #Move to new folder.
                    Get-ChildItem $LatestSPI.DirectoryName | Where-Object { ($_.Name -like "$teststr.spi") `
                                                                            -or `
                                                                            ($_.Name -like "$teststr.md5") `
                                                                            -or `
                                                                            ($_.Name -like "$teststr.spi.bitmap") `
                                                                            } `
                                                                            | Move-Item -Destination $folder | Out-Null
                    
                }
        
            }

        }

        else {
            Write-Host "Error Finding Output of image.exe"
        }
    }
    
}

Function RTVerifyChain {
    #Used to verify Chain Health.
    #This function tests the latest spi file based on iNumber and if it is good (image.exe command returns something) then it states the whole chain is good. It does this first as this is the likliest outcome and is faster code.
    #If the latest fails it starts a PS Job for each SPI and SPF in that chain and collects the reurn as a powershell object
    <# Dataset
        'FileName'=FileName
        'FileNameLength'=Length of the filename, used some areas where spi files will have the same iNumber but they may be consolidated daily\monthly -cd -cm and the longer the name the later in the chain it is 
            #These two properties for a uniqe key and no two should be the same.

        'TF'= return a 0 if the image is good returns a 1 if the image is bad.
        'currenti'=returns the iNumber of the file, used for ordering chains and reporting the last known good one.
        'return'=actual return of image.exe
    #>
    #Lastly this function looks for orphaned spi files that dont have an SPF and reports if found.
    [CmdletBinding()]
    param
    (
        [string[]]
        $Exclusions,
        [string]
        $RVCMDarg1,
        [string]
        $RVCMDarg3
    )
    $CMD = Find-ImagePath

    Clear-Host  
    Write-Host "[ [Tool] Verify Chains ]" -ForegroundColor DarkCyan
    
    #Collect SPF Files
    Write-Host "[Collecting SPF Files]" -ForegroundColor Cyan
    $files = Get-RVFiles -SPF -Exclusions $Exclusions 

    #Itterate SPF Files 
    for ($i = 0 ; $i -lt $files.Count ; $i++){ 
        $file = $files[$i]

        #Generate Line Item Output
        $out = "[" + $file.FullName.Split('\')[ $file.FullName.Split('\').COUNT - 3 ] + " \ " + $file.FullName.Split('\')[ $file.FullName.Split('\').COUNT - 2 ]+ " \ " +$file.FullName.Split('\')[ $file.FullName.Split('\').COUNT - 1 ]+"]" 
        Write-Host $out -ForegroundColor Cyan

        #Collect volletter of the spf.
        $volLetter = $file.Name.Substring($file.Name.IndexOf('_VOL') - 1 ,1)+"_VOL"

        #Test Latest SPI
        $LatestSPI = Get-RVFiles -SPI -SearchBase $file.PSParentPath -Exclusions $Exclusions -VOL_Letter $volLetter -Latest
        $imageReturn = & $CMD $RVCMDarg1 $latestSPI.FullName $RVCMDarg3 
        if ($imageReturn -ne $null){
            Write-Host "     [Chain Good]" -ForegroundColor Green
        }else {
            ### Start-MultiThread Jobs###
            Write-Host "     [Testing All SPI Files .... May Take Some Time]" -ForegroundColor Yellow    

            #collect all the spf and spi files for each vol
            $vcTargets = Get-ChildItem $file.PSParentPath | Where-Object {($_.Name -like "*$volLetter*.spi") -or ($_.Name -like "*$volLetter*.spf") } 

            #Start all jobs passing required arguments
            ForEach($target in $vcTargets){
                Start-Job -ScriptBlock {
                    $imageReturn = & $using:CMD $args[1] $args[4] $args[3]
                    
                    if ($imageReturn -ne $null){
                        [int]$imageReturnTF = 0
                    }else {
                        [int]$imageReturnTF = 1
                    }

                    if ($args[2] -like "*.spf*"){
                        $currenti = 0
                    }else{
                        $currenti = [int](($args[2] -replace '.+?(?=[i]\d+)' , '' -replace "[^\d+]*$","").Substring(1)) 
                    }


                    $pso = New-Object psobject -Property    @{  'FileName'=$args[2];
                                                                'FileNameLength'=$args[2].length;
                                                                'TF'=$imageReturnTF;
                                                                'currenti'=$currenti;
                                                                'return'=$imageReturn;
                                                            }
                    return $pso


                }  -ArgumentList $CMD,$RVCMDarg1,$target.Name,$RVCMDarg3,$target.FullName | Out-Null

            }
            
            #Wait for all jobs
            Get-Job | Wait-Job | Out-Null

            #Init DataSet
            $DataSet = @()
            
            #Get all job results
            $DataSet += Get-Job  | Receive-Job -Keep
            Get-Job | Remove-Job

            #Order Dataset - Agian off two properties Currenti and FileNameLenght to for a uniqe key for each.
            $DataSet = $DataSet | Sort-Object -Property Currenti,FileNameLength
            
            if ($DataSet -isnot [array]){
                #If DataSet is only 1 item
                
                if ($DataSet.TF -eq 0){
                    #Whole Chain is good
                    Write-Host "     [Chain Good]" -ForegroundColor Green
                }else{
                    #Whole Chain is Bad
                    Write-Host "     [Chain Unusable]" -ForegroundColor Red
                }
            }
            else{
                #If More than 1 DataSet is Returned
                
                #Test the SPF
                if ($DataSet.TF[0] -eq 1){
                    Write-Host "     [Chain Unusable]" -ForegroundColor Red
        
                #find the last known good SPI
                }else{
                    $DSIndex = $DataSet.TF.IndexOf(1)
                    $vcmsg = $DataSet[$DSIndex].FileName
                    Write-Host "     [Chain Broken] Last Known Good $vcmsg" -ForegroundColor Yellow
        
                }

            }
            
        }

    }

    #Test if there are spi files without an SPF
    $SPIsMissingSPFs = [System.Collections.ArrayList]@()

    $uSPINames = Get-ChildItem $files.PSParentPath -Recurse | Where-Object {($_.Name -like "*$volLetter*.spi")} | Select-Object @{N='Name'; E={$_.Name.Substring(0,$_.Name.IndexOf('-i'))}} -Unique
    $uSPFnames = Get-ChildItem $files.PSParentPath -Recurse | Where-Object {($_.Name -like "*$volLetter*.spf")} | Select-Object @{N='Name'; E={$_.name.Substring(0,$_.name.Length-4)}} -Unique

    foreach ($SPIName in $uSPINames){
        if ($uSPFnames.Name -contains $SPIName.Name){
            #
        }
        else{
            $missingFile = Get-ChildItem $file.PSParentPath | Where-Object {$_.Name -like "*$($SPIName.Name)*.spi*"} | Select-Object -First 1
            [void]$SPIsMissingSPFs.Add($missingFile.FullName)
        }

    }

    if ($SPIsMissingSPFs.Count -ne 0){
        Write-Host "[Found the following .SPI Chains with no matching .SPF]" -ForegroundColor DarkMagenta
        foreach ($spi in $SPIsMissingSPFs){
            $out = "[" + $spi.Split('\')[ $spi.Split('\').COUNT - 3 ] + " \ " + $spi.Split('\')[ $spi.Split('\').COUNT - 2 ]+ " \ " +($spi.Split('\')[ $spi.Split('\').COUNT - 1 ]).Substring(0,($spi.Split('\')[ $spi.Split('\').COUNT - 1 ]).IndexOf('-i')+5)+"]" 
            Write-Host $out -ForegroundColor DarkMagenta
        }
    }


}
