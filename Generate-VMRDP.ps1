$rdpParameters = @"
screen mode id:i:1
use multimon:i:0
desktopwidth:i:800
desktopheight:i:600
session bpp:i:32
winposstr:s:0,1,1230,102,1920,700
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:2
prompt for credentials:i:0
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:4
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:0
promptcredentialonce:i:0
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
username:s:confederationc.on.ca\jbadergr
drivestoredirect:s:
"@

function Generate-VMRDP {
  param (
    [Parameter(Mandatory)]
    [ValidateScript({
      If (-Not ($_ | Test-Path) ) {
        throw "File does not exist"
      }
      If (-Not ($_ | Test-Path -PathType Container) ) {
        throw "Path must be a folder"
      }
      return $true
    })]
    [System.IO.FileInfo]$OutputFolder
  )

  $resourcePools = ('Production (0 - VIP)',
                    'Production (1 - Gold)',
                    'Production (2 - Silver)',
                    'Production (3 - Bronze)',
                    'Test and Development',
                    'Utilities' )

  connect-viserver cc-vmcentre

  $resourcePools | ForEach-Object { 
    Get-ResourcePool -Name $_ | ForEach-Object {
      # TODO: Check if directories already exist before trying to create them
      $directory = New-Item -ItemType Directory -Path $OutputFolder -Name $_.Name
      $vmInfo = @()
      $_ | get-vm | ForEach-Object {
        If (($_.PowerState -eq "PoweredOn") -And ($_.GuestID -like "*Windows*")) {
          "$($_.Name) is a powered on Windows server"
          $vmInfo += $_ | select Name,"Downloading","Installing","Pending Reboot","Done","Notes","ERROR"
          $rdpParameters + "`nfull address:s:$($_.Name)" | Out-File "$($directory.FullName)\$($_.Name).rdp"
        }
      }
      $vmInfo | sort Name | Export-Csv -Path "$($directory.FullName)\$($_.Name).csv" -NoTypeInformation
    }
  }
}

