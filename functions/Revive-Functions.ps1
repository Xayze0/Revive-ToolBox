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

        [System.String[]]$Exclusions,
        
        [Parameter(Mandatory=$true,ParameterSetName="WithSPF")]
        [Switch]
        $SPF,

        [parameter(Mandatory=$true,ParameterSetName="WithSPI")]
        [Switch]
        $SPI,

        [Switch]
        $Latest

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

        if ($Exclusions){
            $WhereString = @()    
            foreach ($Exclusion in $Exclusions) {
                #Build the Where array                     
                $WhereString += "(`$_.FullName -notlike '*$Exclusion*')"        
                $WhereString += "-and"                        
                        
            }
            $WhereBlock = [scriptblock]::Create( $WhereString.Trim("-and") )
            $files = Get-ChildItem -recurse ($SearchBase) -include ($filter) -File | Where-Object -FilterScript $WhereBlock
        }else{
            $files = Get-ChildItem -recurse ($SearchBase) -include ($filter) -File
        }
        

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
        Write-Verbose -Message "Original String: $Str"
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
    Clear-Host
    Write-Host "[ [Tool] Collect Backup Sizes]" -ForegroundColor DarkCyan

    $files = Get-RVFiles -SPF 

    $twoless = ($files[0]).FullName.Split('\').count - 3

    $serverspath = (($files[0]).FullName.Split('\')[0..$twoless]) -join '\'

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
        
    }

    Write-Host "[....Complete....]" -ForegroundColor Green

}

Function RTRemoveOldInc {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$RVImageCmdArg1,
        [Parameter(Mandatory=$true)]
        [String]$RVImageCmdArg3
        


    )

    Clear-Host
    Write-Host "[ [Tool] Move unrequired INC to :\$(Get-Date -Format MM.dd.yyyy).]" -ForegroundColor DarkCyan
    $cmd = Find-ImagePath
    
    
    #Collect SPF Files
    $files = Get-RVFiles -SPF
    Write-Host "[Collecting SPF Files]" -ForegroundColor Cyan
    
    $percentEach1 = 100/$files.Count
    
    for ($i = 0 ; $i -lt $files.Count ; $i++){ 
        $file = $files[$i]
    
        $pc1 = [System.Math]::Round(($percentEach1*$i),2)
        $op1msg = "SPF File : " + $file.Name
        Write-Progress -Activity "Moving Unrequired Chain Files" -Status 'Progress->' -PercentComplete $pc1 -CurrentOperation $op1msg 
        
        $volLetter = $file.Name.Substring($file.Name.IndexOf('_VOL') - 1 ,1)+"_VOL"
    
        #collect all the spf files and find the latest one.
        $LatestSPI = Get-RVFiles -SPI -SearchBase $file.PSParentPath -Latest
        

        $latestSPIPath = $latestSPI.FullName
            
        #run comand to get a list of files to keep.
        $return = & $CMD $RVImageCmdArg1 $latestSPIPath $RVImageCmdArg3 
    
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
            $folder =  $latestSPIPath[0]+":\"+(Get-Date -Format MM.dd.yyyy)
            if (!(Test-Path -Path $folder)){ New-Item -ItemType Directory -Path $folder}
            
            #make a log of SPF files found
            $spfLogPath = $latestSPIPath[0]+":\"+(Get-Date -Format MM.dd.yyyy) + "\_DiscoveredspfLog.txt"
            if (!(Test-Path -Path $spfLogPath)){ New-Item -ItemType File -Path $spfLogPath }
            if (Test-Path -Path $spfLogPath){ $file.FullName | Out-File -FilePath $spfLogPath -Append }
                                                
                
            #Itterate SPFs and move unneded items to the folder made above
            $filesinVol = (Get-ChildItem $file.PSParentPath -Filter "*$volLetter*")
        
            for ($v = 0 ; $v -lt $filesinVol.count; $v++){
                $item = $filesinVol[$v]
        
                $teststr = $item.Name.Split('.')[0]
        
                if (!($output.Contains($teststr))){
                    #Move to new folder.
                    $Destination = $item.FullName.Substring(0,2)+"\$(Get-Date -Format MM.dd.yyyy)\"+ $item.FullName.Substring(3)
                    if (!(Test-Path ($Destination.Split('\')[0..($Destination.Split('\').Count - 2)] -join '\'))){
                        New-Item -ItemType Directory ($Destination.Split('\')[0..($Destination.Split('\').Count - 2)] -join '\')
                    }
                    Move-Item -Path $item.FullName -Destination $Destination
                }
        
            }

        }

    }
    
}

Function RTVerifyChain {
    Clear-Host  
    Write-Host "[ [Tool] Verify Chains ]" -ForegroundColor DarkCyan
    $cmd = Find-ImagePath

    #Collect SPF Files
    $files = Get-RVFiles -SPF 
    Write-Host "[Collecting SPF Files]" -ForegroundColor Cyan




    #Itterate SPF Files
    for ($i = 0 ; $i -lt $files.Count ; $i++){ 
        $file = $files[$i]

        #Generate Line Item Output
        $out = "[" + $file.FullName.Split('\')[ $file.FullName.Split('\').COUNT - 3 ] + " \ " + $file.FullName.Split('\')[ $file.FullName.Split('\').COUNT - 2 ]+ " \ " +$file.FullName.Split('\')[ $file.FullName.Split('\').COUNT - 1 ]+"]" 
        Write-Host $out -ForegroundColor Cyan
 
        $volLetter = $file.Name.Substring($file.Name.IndexOf('_VOL') - 1 ,1)+"_VOL"

        Get-RVFiles 

        #collect all the spf and spi files and sort by date modified oldest to newest
        $vcTargets = Get-ChildItem $file.PSParentPath | Where-Object {($_.Name -like "*$volLetter*.spi") -or ($_.Name -like "*$volLetter*.spf") } |Sort-Object -Property LastWriteTime
    
        #test Latest SPF, because if the latest spf is good, the whole chain is good, also i suspect this is the most common result, so testing this first saves time.
        $k = $vcTargets.Count - 1
        $vcTarget = $vcTargets[$k]
        $return = & $CMD $arg1 $vcTarget.FullName $arg3  

        #We know the chain is bad if the return in Null, if we get anythin the chain is good, just how the image.exe command returns good or bad chains.
        if ($return -ne $null){
            Write-Host "     [Chain Good]" -ForegroundColor Green
        }
        else{
            #Next we check the oldest file and if it returns null, we know the whole chain is bad. Also i suspect the 2nd most likley outcome.
            $vcTarget = $vcTargets[0]
            $return = & $CMD $arg1 $vcTarget.FullName $arg3

            if ($return -ne $null){
                #Finally is the latest file is bad and the oldest is good we itterate files till we find a failure. and output the last known good file.
                $vcStatusGood = $true
                for ($j = 0 ; ($vcStatusGood -eq $true) -and ($j -le $vcTargets.Count) ; $j++){
                    $vcTarget = $vcTargets[$j]
                    $return = & $CMD $arg1 $vcTarget.FullName $arg3  
                    #Write-Host $return
                    if ($return -eq $null){
                        $vcStatusGood = $false
                        $l = $j - 1
                        $vcmsg = $vcTargets[$l]
                        Write-Host "     [Chain Broken] Last Known Good $vcmsg" -ForegroundColor Yellow
                    }
                }

            
            }else{
                Write-Host "     [Chain Unusable]" -ForegroundColor Red

            }
            

        }


    }

    $SPIsMissingSPFs = [System.Collections.ArrayList]@()

    $uSPFnames = Get-Spf $dl | Select-Object @{N=’Name’; E={$_.name.Substring(0,$_.name.Length-4)}} -Unique
    $uSPINames = Get-Spi $dl | Select-Object @{N=’Name’; E={$_.Name.Substring(0,$_.Name.IndexOf('-i'))}} -Unique

    foreach ($SPIName in $uSPINames){
        if ($uSPFnames.Name -contains $SPIName.Name){
            #
        }
        else{
            $missingFile = Get-ChildItem -Path $dl -Recurse | Where-Object {$_.Name -like "*$($SPIName.Name)*.spi*"} | Select-Object -First 1
            [void]$SPIsMissingSPFs.Add($missingFile.FullName)
        }

    }

    if ($SPIsMissingSPFs.Count -ne 0){
        Write-Host "[Found the following .SPI Chains with no matching .SPF]" -ForegroundColor Yellow
        foreach ($spi in $SPIsMissingSPFs){
            $out = "[" + $spi.Split('\')[ $spi.Split('\').COUNT - 3 ] + " \ " + $spi.Split('\')[ $spi.Split('\').COUNT - 2 ]+ " \ " +($spi.Split('\')[ $spi.Split('\').COUNT - 1 ]).Substring(0,($spi.Split('\')[ $spi.Split('\').COUNT - 1 ]).IndexOf('-i')+5)+"]" 
            Write-Host $out -ForegroundColor yellow
        }
    }

}
