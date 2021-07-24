function Build-VMRDPConnections {
<#
  .Synopsis
  Generate RDP connection files and a spreadsheet for all powered-on Windows VMs, divided by resource pool.

  
  .Description
  This cmdlet fetches all powered on Windows servers from vSphere and creates an RDP file for each one, divided by resource pool. It also writes a spreadsheet for each resource pool, meant to facilitate performing and tracking Windows Updates.

  The RDP connection details can be customimzed by placing a "Default.rdp" file in the current directory. If that doesn't exist, it will check for ~\Documents\Default.rdp (which is the default location for RDP default settings). If neither exists, it will use its own defaults.

  OutputFolder defaults to current directory. Use -OutputFolder parameter to override.

  By default fetches all Resource Pools. Use -ResourcePools paramater to specify resource pool(s).

  Requires the PowerCLI module from VMware.


#>
  param (
    [ValidateScript({
      If (-Not ($_ | Test-Path) ) {
        throw "File does not exist"
      }
      If (-Not ($_ | Test-Path -PathType Container) ) {
        throw "Path must be a folder"
      }
      return $true
    })]
    # Specify output folder. Defaults to current folder.
    [System.IO.FileInfo]$OutputFolder = ".",
    [Parameter(Mandatory)]
    # Specify the vCenter server to connect to.
    [string]$vCenterServer,
    # Specify resource pool(s) to fetch. By default, fetches all resource pools.
    [array]$ResourcePools
  )

  # Look for default RDP settings in current folder and then in ~\Documents. If neither exists,
  # use built-in defaults.
  If (Test-Path "Default.rdp") {
    $rdpParameters = Get-Content "Default.rdp"
  } ElseIf (Test-Path "~\Documents\Default.rdp") {
    $rdpParameters = Get-Content "~\Documents\Default.rdp"
  } Else {
    $rdpParameters = (
      "screen mode id:i:1",
      "use multimon:i:0",
      "desktopwidth:i:800",
      "desktopheight:i:600",
      "session bpp:i:32",
      "compression:i:1",
      "keyboardhook:i:2",
      "connection type:i:7",
      "networkautodetect:i:1",
      "bandwidthautodetect:i:1",
      "displayconnectionbar:i:1",
      "enableworkspacereconnect:i:0",
      "disable wallpaper:i:1",
      "allow font smoothing:i:0",
      "allow desktop composition:i:0",
      "disable full window drag:i:1",
      "disable menu anims:i:1",
      "disable themes:i:0",
      "disable cursor setting:i:0",
      "bitmapcachepersistenable:i:1",
      "audiomode:i:0",
      "redirectprinters:i:0",
      "redirectcomports:i:0",
      "redirectsmartcards:i:1",
      "redirectclipboard:i:1",
      "redirectposdevices:i:0",
      "autoreconnection enabled:i:1",
      "authentication level:i:2",
      "prompt for credentials:i:0",
      "negotiate security layer:i:1",
      "remoteapplicationmode:i:0",
      "alternate shell:s:",
      "shell working directory:s:",
      "gatewayhostname:s:",
      "gatewayusagemethod:i:4",
      "gatewaycredentialssource:i:4",
      "gatewayprofileusagemethod:i:0",
      "promptcredentialonce:i:0",
      "gatewaybrokeringtype:i:0",
      "use redirection server name:i:0",
      "rdgiskdcproxy:i:0",
      "kdcproxyname:s:",
      "drivestoredirect:s:"
    )
  }


  #$resourcePools = ('Production (0 - VIP)',
  #                  'Production (1 - Gold)',
  #                  'Production (2 - Silver)',
  #                  'Production (3 - Bronze)',
  #                  'Test and Development',
  #                  'Utilities' )

  connect-viserver $vCenterServer

  # Transform the specified output path into an actual path object. Setting it to a different
  # variable is a bit of a hack - for some reason, setting it to itself doesn't work.
  $OutputFolderObj = Get-Item -Path "$OutputFolder"

  # If -ResourcePools parameter isn't specified, get all resource pools.
  If (! $ResourcePools) {
    $ResourcePools = Get-ResourcePool
  # If -ResourcePools is specified, then get those resource pools dammit.
  } Else {
    $ResourcePools = $ResourcePools | ForEach-Object { Get-ResourcePool $_ }
  }

  $ResourcePools | ForEach-Object { 
    Get-ResourcePool -Name $_ | ForEach-Object {
      # Check whether output folders already exist before attempting to create.
      If (Test-Path -Path "$($OutputFolderObj.FullName)\$($_.Name)" -PathType Container) {
        $directory = Get-Item -Path "$($OutputFolderObj.FullName)\$($_.Name)"
      } Else { 
        $directory = New-Item -ItemType Directory -Path $OutputFolderObj.FullName -Name $_.Name
      }
      # Initialize an empty array for the spreadsheet for the current resource pool
      $vmInfo = @()
      #Get all VMs in the current resource pool
      $_ | get-vm | ForEach-Object {
        If (($_.PowerState -eq "PoweredOn") -And ($_.GuestID -like "*Windows*")) {
          $vmInfo += $_ | select Name,"Downloading","Installing","Pending Reboot","Done","Notes","ERROR"
          $rdpParameters + "full address:s:$($_.Name)" | Out-File "$($directory.FullName)\$($_.Name).rdp"
        }
      }
      $vmInfo | sort Name | Export-Csv -Path "$($directory.FullName)\$($_.Name).csv" -NoTypeInformation
    }
  }
}

