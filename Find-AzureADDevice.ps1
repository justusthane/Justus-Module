function Find-AzureADDevice {
  <# 
    .SYNOPSIS
    Returns the matching Azure AD Devices for an AD computer (or array of AD computers)

    .DESCRIPTION
    It can sometimes be difficult to match Azure AD Devices with AD Computers, as the hostnames don't always match, and searching by GUID is cumbersome.

    This cmdlet takes a search string (wildcards permitted), or an array of search strings, gets the matching AD Computer objects, and then returns the corresponding Azure AD Devices.

    Requires AzureAD PowerShell module. Install with `Install-Module AzureAD`. Must be connected to AzureAD before running. Use `Connect-AzureAD`

    .EXAMPLE
    Find-AzureADDevice justus-desktop

    Find a specific computer.

    .EXAMPLE
    Find-AzureADDevice fflab-c166-*

    Search using a wildcard to get a list of computers.

    .EXAMPLE
    Find-AzureADDevice fflab-c166-*,justus-desktop

    Provide an array to search for multiple strings.

    .EXAMPLE
    "justus-desktop","fflab-tt-01" | Find-AzureADDevice

    Also accepts pipeline input.

  #>
  Param (
    [Parameter(Mandatory,ValueFromPipeline=$true)]
    # Specify a single search string, or an array of search strings. Wildcards permitted.
    [array]$SearchString
  )
  Begin {
    }

  Process {
    $SearchString | ForEach-Object { get-adcomputer -filter 'name -like $_' } | 
    ForEach-Object { $ComputerName = $_.Name; get-azureaddevice -filter "deviceId eq guid'$($_.ObjectGuid)'" | 
    Select-Object @{l="ComputerName";e={$ComputerName}},* -ExcludeProperty AlternativeSecurityIds,DevicePhysicalIds }
  }

  End {}
}

