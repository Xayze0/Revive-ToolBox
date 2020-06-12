function init-SSH{
    [CmdletBinding()]
    Param (
        $credential=(get-credential -Message "Please provide credential information." -UserName root),
        [parameter(Mandatory=$true)][string]$plinkLocation
    )
    Begin{}
    End{}
    Process {
        if ($plinkLocation -inotlike "*plink.exe") {
            write-host "Ongeldige locatie voor plink opgegeven."
            return
        }
        if (!(Test-Path $plinkLocation)) {
            write-host "Plink niet gevonden op " $plinkLocation
            return
        }
        if (!($credential)) {
            write-host "Geen credentials op gegeven."
            return
        }
        New-Variable -Name plinkLocation -Scope global -Value $plinkLocation -Force:$true
        New-Variable -Name plinkCredential -Scope global -Value $credential -Force:$true
    }
}