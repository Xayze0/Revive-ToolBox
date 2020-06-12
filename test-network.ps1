<#
.SYNOPSYS
    Test with vmkping all kernel ports
.DESCRIPTION

.NOTES
    Files needed:
        - parameters.ps1

    *** DISCLAIMER ***

    This software is provided "AS IS", without warranty of any kind, express or implied, 
    fitness for a particular purpose and noninfringement. 
    In no event shall the authors or copyright holders be liable for any claim, damages or other liability,
    whether in an action of contract, tort or otherwise, arising from, 
    out of or in connection with the software or the use or other dealings in the software.
#>
[CmdletBinding()]
Param(
    [switch]$showResult
)
begin {
     #-- Get Script Parameters
     $scriptPath=(get-item (Split-Path -Path $MyInvocation.MyCommand.Definition)).FullName
     $scriptName=Split-Path -Leaf $MyInvocation.MyCommand.path
 
     $VerbosePreference="SilentlyContinue"
     $WarningPreference="Continue"
     $DebugPreference="SilentlyContinue"
     $ErrorActionPreference="SilentlyContinue"
  
     if(!(Test-Path -Path $scriptPath\parameters.ps1 -IsValid)) {
         Write-Warning "Parameters.ps1 not found. Script will exit."
         exit
     }
     $P = & $scriptPath\parameters.ps1
 
     #-- connect to vCenter (if not already connected)
     $noConnection=$true
     if ($global:DefaultViserver) {
         if ($global:DefaultViserver.IsConnected -and $global:DefaultViserver.name -ilike $P.vCenterFQDN) {
             write-host "Already connected to vCenter" $P.vCenterFQDN -ForegroundColor Cyan
             $noConnection=$false
         } else {
             Disconnect-VIServer -Server $global.defaultViserver -Confirm:$false -Force
         }
     }
     if ($noConnection) {
         Connect-VIServer $P.vCenterFQDN
     }
     
 
    
    function vmkping {

        param(
            [object]$arguments,
            [switch]$willFail=$false,
            [string]$action
            )

            try {
                $pingFailed=$false
                write-verbose "vmkping arguments:"
                write-verbose  ("" | select @{N='Host';E={$arguments.host}},@{N='df';E={$arguments.df}},@{N='count';E={$arguments.count}},@{N='size';E={$arguments.size}},@{N='interface';E={$arguments.interface}} | ft -AutoSize | out-string)
                $answer=$esxcli.network.diag.ping.Invoke($arguments)
                }
            catch{
                write-host $arguments.interface ": Ping failed." -ForegroundColor Yellow
                $pingFailed=$true
                }
            if ($pingFailed) {
                $result= "" | select  @{N='vmk';E={$arguments.interface}},@{N='HostAddr';E={$arguments.host}},@{N='PacketLost';E={100}},@{N='ValidResult';E={$willFail}}
            } else {
                write-verbose "vmkping result:"
                write-verbose ($answer.trace | ft -AutoSize | out-string)
                $result=$answer.summary | select @{N='vmk';E={$arguments.interface}},HostAddr,PacketLost,Transmitted,@{N='ValidResult';E={!$willFail}}
            }
            return $result
        }

}

end {}  

Process {
    $rapport=@()
    $esxiHosts=  get-vmhost | sort name | Out-GridView -OutputMode multiple
    foreach ($esxiHost in $esxiHosts) {
        write-host
        write-host "##############################################################" -ForegroundColor Cyan
        write-host "     "$esxihost.name -ForegroundColor Cyan
        write-host "##############################################################" -ForegroundColor Cyan
        $esxcli=get-esxcli -v2 -vmhost $esxiHost.name

        Write-host "Normal Ping"
        $action="Normal Ping"
        $arguments=$esxcli.network.diag.ping.CreateArgs()
        $arguments.ipv4=$true
        $arguments.df=$true
        $arguments.count=1
        $arguments.host=$P.vmkping.vmk0
        $arguments.interface="vmk0"
        $Rapport+=vmkping -arguments $arguments -action $action | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk1
        $arguments.interface="vmk1"
        $Rapport+=vmkping -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk2
        $arguments.interface="vmk2"
        $Rapport+=vmkping -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk3
        $arguments.interface="vmk3"
        $arguments.netstack="vmotion"
        $Rapport+=vmkping  -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk4
        $arguments.interface="vmk4"
        $arguments.netstack="vSphereProvisioning"
        $Rapport+=vmkping  -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk5
        $arguments.interface="vmk5"
        $arguments.netstack="defaultTcpipStack"
        $Rapport+=vmkping  -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        Write-host "Full Ping"
        $action="Full Ping"
        $arguments=$esxcli.network.diag.ping.CreateArgs()
        $arguments.ipv4=$true
        $arguments.df=$true
        $arguments.count=1
        $arguments.size=1500-28
        $arguments.host=$P.vmkping.vmk0
        $arguments.interface="vmk0"
        $Rapport+=vmkping  -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk1
        $arguments.interface="vmk1"
        $Rapport+=vmkping  -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk2
        $arguments.interface="vmk2"
        $Rapport+=vmkping  -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk3
        $arguments.interface="vmk3"
        $arguments.netstack="vmotion"
        $Rapport+=vmkping  -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk4
        $arguments.interface="vmk4"
        $arguments.netstack="vSphereProvisioning"
        $Rapport+=vmkping  -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk5
        $arguments.interface="vmk5"
        $arguments.netstack="defaultTcpipStack"
        $Rapport+=vmkping  -arguments $arguments | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        Write-host "Full Ping + 1"
        $action="Full Ping + 1"
        $arguments=$esxcli.network.diag.ping.CreateArgs()
        $arguments.ipv4=$true
        $arguments.df=$true
        $arguments.count=1
        $arguments.size=1501-28
        $arguments.host=$P.vmkping.vmk0
        $arguments.interface="vmk0"
        $Rapport+=vmkping  -arguments $arguments -willFail  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk1
        $arguments.interface="vmk1"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk2
        $arguments.interface="vmk2"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk3
        $arguments.interface="vmk3"
        $arguments.netstack="vmotion"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk4
        $arguments.interface="vmk4"
        $arguments.netstack="vSphereProvisioning"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk5
        $arguments.interface="vmk5"
        $arguments.netstack="defaultTcpipStack"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        Write-host "Jumbo"
        $action="Jumbo"
        $arguments=$esxcli.network.diag.ping.CreateArgs()
        $arguments.ipv4=$true
        $arguments.df=$true
        $arguments.count=1
        $arguments.size=9000-28
        $arguments.host=$P.vmkping.vmk0
        $arguments.interface="vmk0"
        $Rapport+=vmkping  -arguments $arguments -willFail  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk1
        $arguments.interface="vmk1"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk2
        $arguments.interface="vmk2"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk3
        $arguments.interface="vmk3"
        $arguments.netstack="vmotion"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk4
        $arguments.interface="vmk4"
        $arguments.netstack="vSphereProvisioning"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk5
        $arguments.interface="vmk5"
        $arguments.netstack="defaultTcpipStack"
        $Rapport+=vmkping  -arguments $arguments  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}
    <##
        Write-host "Jumbo + 1"
        $action="Jumbo + 1"
        $arguments=$esxcli.network.diag.ping.CreateArgs()
        $arguments.ipv4=$true
        $arguments.df=$true
        $arguments.count=1
        $arguments.size=9001-28
        $arguments.host=$P.vmkping.vmk0
        $arguments.interface="vmk0"
        $Rapport+=vmkping  -arguments $arguments -willFail  | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk1
        $arguments.interface="vmk1"
        $Rapport+=vmkping  -arguments $arguments -willFail | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk2
        $arguments.interface="vmk2"
        $Rapport+=vmkping  -arguments $arguments  -willFail | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}} 

        $arguments.host=$P.vmkping.vmk3
        $arguments.interface="vmk3"
        $arguments.netstack="vmotion"
        $Rapport+=vmkping  -arguments $arguments -willFail | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk4
        $arguments.interface="vmk4"
        $arguments.netstack="vSphereProvisioning"
        $Rapport+=vmkping  -arguments $arguments -willFail | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}

        $arguments.host=$P.vmkping.vmk5
        $arguments.interface="vmk5"
        $arguments.netstack="defaultTcpipStack"
        $Rapport+=vmkping  -arguments $arguments -willFail | select *,@{N='Action';E={$action}},@{N='vmHost';E={$esxiHost.name}}
        ##>
    }

    $rapport | ft -AutoSize
    #-- Grouping rapport on ValidResult, expected result is one group named True.
    write-host "Expected result is only one group 'True':"
    $rapport | Group-Object ValidResult
}