Function Show-Menu{
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
        Write-Host "    | ][ |"
        Write-Host "    | ][ |" 
        Write-Host "    | ][ |"   
        Write-Host "    | ][ |"
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
    #collect non a-c drives on the system and haves the end user pick one.
    $drives = Get-Volume | Where-Object {$_.DriveLetter -match '^[d-z]$'} | Sort-Object -Property DriveLetter

    Write-Host "[Drive Letters]"  -ForegroundColor Cyan

    foreach ($drive in $drives){
        $echostring = "  ["+$drive.DriveLetter+"]"
        Write-Host $echostring -ForegroundColor Yellow
    }

    $dletter = Read-Host "Pick a Drive Letter"



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
        $VOLLetter


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

        $WhereString = @()
        foreach ($Exclusion in $Exclusions) {
            #Build the Where array                     
            $WhereString += "(`$_.FullName -notlike '*$Exclusion*')"         
        }

        if ($VOLLetter){
            $WhereString += "(`$_.FullName -like '*$VOLLetter*')"
        }

        $WhereString = $WhereString -Join " -and " 
        $WhereBlock = [scriptblock]::Create($WhereString)
        $files = Get-ChildItem -recurse ($SearchBase) -include ($filter) -File | Where-Object -FilterScript $WhereBlock
        
    

        if ($Latest){
            $highesti = 1
            $highestFile = ""
            foreach ($file in $files) {
                #$file.Name   -replace '.+?(?=[i]\d+)' , '' -replace "[^\d+]*$","" 
                $currenti = [int](($file.Name   -replace '.+?(?=[i]\d+)' , '' -replace "[^\d+]*$","").Substring(1)) 
                if ($currenti -gt $highesti){
                    $highestFile = $file

                }
            }
            return $highestFile
        }   
        
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
    Clear-Host
    Write-Host "[ [Tool] Find SPX Errors in logs]" -ForegroundColor DarkCyan
    Write-Host "[....Collecting Log Files....]" -ForegroundColor Cyan

    Get-WinEvent -LogName Application -FilterXPath "*[System[TimeCreated[timediff(@SystemTime) <= 2592000000]]]" `
    | Where-Object {($_.ProviderName -eq "ShadowProtectSPX") -and ($_.LevelDisplayName -ne "Information")} `
    | Format-table -Property timecreated,message, @{name='Job Result'; expression={ if ($_.LevelDisplayName -eq "Information"){"Success"}else{"Error"} }} `

    Write-Host "[....Complete....]" -ForegroundColor Green
}

Function RTCollectBackupSizes  {
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
        #what if 0 files??

        $serverspath = $files[0] | Split-Path -Parent | Split-Path -Parent 


        $Servers = Get-ChildItem -Path $serverspath

        foreach ($Server in $Servers){
            Write-Host "  "
            Write-Host "  "
            Write-Host "---$server------------------------------" -ForegroundColor Green
        
            $Backups = Get-ChildItem $Server.FullName | Where-Object {!($_.PSIsContainer)}

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
    [CmdletBinding()]
    param
    (
        [string[]]
        $Exclusions
    )

    Clear-Host
    Write-Host "[ [Tool] Move unrequired INC to :\$(Get-Date -Format MM.dd.yyyy).]" -ForegroundColor DarkCyan
    $cmd = Find-ImagePath
    
    
    #Collect SPF Files
    Write-Host "[Collecting SPF Files]" -ForegroundColor Cyan
    $files = Get-RVFiles -SPF -Exclusions $Exclusions
    
    #What if 0 ???
    $percentEach1 = 100/$files.Count
    
    for ($i = 0 ; $i -lt $files.Count ; $i++){ 
        $file = $files[$i]
    
        $pc1 = [System.Math]::Round(($percentEach1*$i),2)
        $op1msg = "SPF File : " + $file.Name
        Write-Progress -Activity "Moving Unrequired Chain Files" -Status 'Progress->' -PercentComplete $pc1 -CurrentOperation $op1msg 
        
        $volLetter = $file.Name.Substring($file.Name.IndexOf('_VOL') - 1 ,1)+"_VOL"
    
        #collect all the spi files and find the latest one.
        $LatestSPI = Get-RVFiles -SPI -SearchBase $file.PSParentPath -Latest -Exclusions $Exclusions -VOLLetter $volLetter
        
        #run comand to get a list of files to keep.
        $return = & $CMD $p.RVImageCmdArg1 $latestSPI.FullName $p.RVImageCmdArg3
    
        #Test to see if if there is a return a null return mean bad test
        if ($return -ne $null){
            #init var
            $output = @()
            
            #Cleanup output of command
            Foreach ($line in $return){
                if ($line -ne ""){
                    $clean = (Remove-StringSpecialCharacter -String $line -SpecialCharacterToKeep ':','.','"','_',' ','-','\').trim('"')
                    $output += ($clean.split('\')[$clean.split('\').count -1] ).Split('.')[0]
                }
            }
                
        
            #make a folder for old items to go to
            $folder =  $LatestSPI.PSParentPath +"\"+(Get-Date -Format MM.dd.yyyy)
            if (!(Test-Path -Path $folder)){ New-Item -ItemType Directory -Path $folder}
            
            #Itterate SPFs and move unneded items to the folder made above
            $filesinVol = (Get-ChildItem $file.PSParentPath -Filter "*$volLetter*")
        
            for ($v = 0 ; $v -lt $filesinVol.count; $v++){
                $item = $filesinVol[$v]
        
                $teststr = $item.Name.Split('.')[0]
                
                #If our test file is not in the required list
                if (!($output.Contains($teststr))){
                    #Move to new folder.
                    $Destination = $item.FullName.Substring(0,2)+"\$(Get-Date -Format MM.dd.yyyy)\"+ $item.FullName.Substring(3)
                    if (!(Test-Path ($Destination.Split('\')[0..($Destination.Split('\').Count - 2)] -join '\'))){
                        New-Item -ItemType Directory ($Destination.Split('\')[0..($Destination.Split('\').Count - 2)] -join '\') | Out-Null
                    }
                    Move-Item -Path $item.FullName -Destination $Destination | Out-Null
                }
        
            }

        }

    }
    
}

Function RTVerifyChain {
    Clear-Host  
    Write-Host "[ [Tool] Verify Chains ]" -ForegroundColor DarkCyan
    

    #Collect SPF Files
    Write-Host "[Collecting SPF Files]" -ForegroundColor Cyan
    $files = Get-RVFiles -SPF 

    $CMD = Find-ImagePath

    #Itterate SPF Files 
    for ($i = 0 ; $i -lt $files.Count ; $i++){ 
        $file = $files[$i]

        #Generate Line Item Output
        $out = "[" + $file.FullName.Split('\')[ $file.FullName.Split('\').COUNT - 3 ] + " \ " + $file.FullName.Split('\')[ $file.FullName.Split('\').COUNT - 2 ]+ " \ " +$file.FullName.Split('\')[ $file.FullName.Split('\').COUNT - 1 ]+"]" 
        
        Write-Host $out -ForegroundColor Cyan

        $volLetter = $file.Name.Substring($file.Name.IndexOf('_VOL') - 1 ,1)+"_VOL"
        

        #collect all the spf and spi files and sort by date modified oldest to newest
        $vcTargets = Get-ChildItem $file.PSParentPath | Where-Object {($_.Name -like "*$volLetter*.spi") -or ($_.Name -like "*$volLetter*.spf") } 

       
        ### Start-MultiThread.ps1 ###
        #Start all jobs
        ForEach($target in $vcTargets){
            #<#
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


            }  -ArgumentList $CMD,$p.RVImageCmdArg1,$target.Name,$p.RVImageCmdArg3,$target.FullName | Out-Null
            #>
        }
        
        ### FIND ME
        #its not so bad, as i think i can edit the return and include the testing as part of this job op. then return a dictionary of SPI i number and true false.
        #then order the list and fin the time before the first failure.
        

        #Wait for all jobs
        Get-Job | Wait-Job | Out-Null
        $DataSet = @()
        
        #Get all job results
        $DataSet += Get-Job  | Receive-Job -Keep
        Get-Job | Remove-Job

        #Order Dataset
        $DataSet = $DataSet | Sort-Object -Property Currenti,FileNameLength
        

        
        if ($DataSet.Count -eq 1){
            #If DataSet is only 1 item
            if ($DataSet.TF -eq 0){
                #Whole Chain is good
                Write-Host "     [Chain Good]" -ForegroundColor Green
            }else{
                Write-Host "     [Chain Unusable]" -ForegroundColor Red
            }
        }
        else{
            ##If More than 1 DataSet is Returned
            if (!($DataSet.TF.Contains(1))){
                #Whole Chain is good
                Write-Host "     [Chain Good]" -ForegroundColor Green
            }
            else{
                if ($DataSet.TF[0] -eq 1){
                    Write-Host "     [Chain Unusable]" -ForegroundColor Red
        
                }else{
                    #Order Dataset by 
                    $DSIndex = $DataSet.TF.IndexOf(1)
                    $vcmsg = $DataSet[$DSIndex].FileName
                    Write-Host "     [Chain Broken] Last Known Good $vcmsg" -ForegroundColor Yellow
        
                }

            }
        }
        


        

    }

    $SPIsMissingSPFs = [System.Collections.ArrayList]@()

    $uSPINames = Get-ChildItem $files[0].PSParentPath -Recurse | Where-Object {($_.Name -like "*$volLetter*.spi")} | Select-Object @{N='Name'; E={$_.Name.Substring(0,$_.Name.IndexOf('-i'))}} -Unique
    $uSPFnames = Get-ChildItem $files[0].PSParentPath -Recurse | Where-Object {($_.Name -like "*$volLetter*.spf")} | Select-Object @{N='Name'; E={$_.name.Substring(0,$_.name.Length-4)}} -Unique

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
