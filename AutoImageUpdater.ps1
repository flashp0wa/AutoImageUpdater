<#
.SYNOPSIS

.DESCRIPTION
The script updates the os image with the updates you define below in the variables. The updates are filtered by name. In our case we wish to filter Windows 10 Version 1909 x64 Update packages.
The SoftwareUpdateGroup variable defines from which group You wish to read out the updates You wish to apply.
The ImageName variable defines to which image You wish to apply the update.
If the OS Image update has been finished the script will refresh Operating System Upgrade Package on the distribution points

.PARAMETER DemoParam1
    

.PARAMETER DemoParam2
    

.EXAMPLE
   

.EXAMPLE
    

.NOTES
    Author: flashp0wa
    Last Edit: 11/17/2020
    Version 1.0

#>

#Create Tracelog
$global:LOGFILE = "C:\Windows\AutoImageUpdater.log"
$global:bVerbose = $True


function Write-TraceLog
{                                       
    [CmdletBinding()]
    PARAM(
     [Parameter(Mandatory=$True)]                     
	    [String]$Message,                     
	    [String]$LogPath = $LOGFILE, 
     [validateset('Info','Error','Warn')]   
	    [string]$severity,                     
	    [string]$component = $((Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name),
        [long]$logsize = 5 * 1024 * 1024,
        [switch]$Info
	)                

    $Verbose = [bool]($PSCmdlet.MyInvocation.BoundParameters['Verbose'])
    Switch ($severity)
    {
        'Error' {$sev = 3}
        'Warn'  {$sev = 2}
        default {$sev = 1}
    }

    If (($Verbose -and $bVerbose) -or ($Verbose -eq $false)) {
	    $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"                     
	    $WhatTimeItIs= Get-Date -Format "HH:mm:ss.fff"                     
	    $Dizzate= Get-Date -Format "MM-dd-yyyy"                     
	
	    "<![LOG[$Message]LOG]!><time=$([char]34)$WhatTimeItIs$($TimeZoneBias.bias)$([char]34) date=$([char]34)$Dizzate$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$sev$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $LogPath -Append -NoClobber -Encoding default
    }

    If ($bVerbose) {write-host $Message}

    $LogPath = $LogPath.ToUpper()
    $i = Get-Item -Path $LogPath
    #$i.Length
    #$i.Length
    If ($i.Length -gt $logsize)
    {
        $backuplog = $LogPath.Replace(".LOG", ".LO_")
        If (Test-Path $backuplog)
        {
            Remove-Item $backuplog
        }
        Move-Item -Path $LogPath -Destination $backuplog
    } 

}

Import-Module 'E:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location CAS:

Write-TraceLog -Message "Starting Script" -severity Info -component "AutoImageUpdater"

#Variables
$OSVersion = "Windows 10 Version 1909"
$Architecture = "x64"
$SoftwareUpdateGroup = "Name of the software update group from you wish to apply the updates"
$ImageName = "Name of the OS image where you apply the updates to"
$OSUpgradePackageID = "Package ID of software update package"
$Year = (Get-Date).Year
$Month = (Get-Date).Month - 1

if ($Month = 1) {
    $Year = $Year-1
    $Month = 12
}

$MonthlyUpdates = Get-CMSoftwareUpdate -UpdateGroupName $SoftwareUpdateGroup -Fast | Where-Object {$_.localizeddisplayname -like "$Year-$Month*$OSVersion*$Architecture*"}

New-CMOperatingSystemImageUpdateSchedule -Name $ImageName -SoftwareUpdate $MonthlyUpdates -RunNow -ContinueOnError $True -UpdateDistributionPoint $True

Write-TraceLog -Message "Update started" -severity Info -component "AutoImageUpdater"
Write-TraceLog -Message "Waiting for the update to be finished...Sleeping now for 10 minuntes" -severity Info -component "AutoImageUpdater"
Start-Sleep -Seconds 600

#Checking here the "Last Update" date of the OS Image, if the OS Image update finished and started to distribute script will exit loop and will update Operating System Upgrade Packages

$ImageDPUpdateDateBeforePatch = (Get-CMOperatingSystemImage -Name "$ImageName").sourcedate

do {
    Write-TraceLog -Message "Still updating...Sleeping now for 10 minutes" -severity Info -component "AutoImageUpdater"
    Start-Sleep -Seconds 600
    $ImageDPUpdateDateAfterPatch = (Get-CMOperatingSystemImage -Name "$ImageName").sourcedate
} while ($ImageDPUpdateDateBeforePatch -eq $ImageDPUpdateDateAfterPatch)

Write-TraceLog -Message "Update finished...OS Image distribution point update started" -severity Info -component "AutoImageUpdater"

Update-CMDistributionPoint -OperatingSystemInstallerId $OSUpgradePackageID
Write-TraceLog -Message "Operating System Upgrade Package distribution point update started" -severity Info -component "AutoImageUpdater"

Send-MailMessage -To "X" -From "X"  -Subject "OS Image Update Notification" -Body "The patches of the last month have been applied to the image. Distribution points updated. Gimme a hug." -SmtpServer "X" -Port 25









