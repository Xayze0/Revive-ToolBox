# Script Parameters for <scriptname>.ps1
<#
    Author             : <Script Author>
    Last Edit          : <Initials> - <date>
#>

@{
    #-- default script parameters
        LogPath="D:\beheer\logs"
        LogDays=5 #-- Logs older dan x days will be removed

    #-- Syslog settings
        SyslogServer="syslog.shire.lan" #-- syslog FQDN or IP address

    #-- disconnect viServer in exit-script function
        DisconnectviServerOnExit=$true

    #-- vSphere vCenter FQDN
        vCenter="value" #-- vCenter FQDN

    #-- settings for functino set-emailAlarmActions
    emailAlarm=@{
        CSVfile="VMware\alarmDefinitions.csv"
        Profiles=@{
            disabled=@{
                disabled=$true
                }
            High=@{
                disabled=$false
                emailTo=@("operations@vdl.nl")
                repeatMinutes=240 #-- 60 * 4 uur
                emailSubject="[HIGH] NLDC01VS011 alarm notification"
                }
            Medium=@{
                disabled=$false
                emailTo=@("operations@vdl.nl")
                repeatMinutes=1440 #-- 60 [min] * 24 [uur]
                emailSubject="[MEDIUM] NLDC01VS011 alarm notification"
                }
            Low=@{
                disabled=$false
                emailTo=@("operations@vdl.nl")
                repeatMinutes=0 #-- don't repeat
                emailSubject="[LOW] NLDC01VS011 alar mnotification"
                }
            noEmail=@{
                disabled=$false
                }
            }
        }
}