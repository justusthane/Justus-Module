function Find-AzureADDevice {
  <#
    .SYNOPSIS
    Searches AD for a computer (or computers) and returns the corresponding AzureAD devices.

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

    .EXAMPLE
    Find-AzureADDevice fflab-c166* | ft ComputerName,DisplayName,IsManaged,ProfileType

    ComputerName  DisplayName    IsManaged ProfileType
    ------------  -----------    --------- -----------
    FFLAB-C166-07 FFLAB-C166-07       True RegisteredDevice
    FFLAB-C166-08 FFLAB-C166-08       True RegisteredDevice
    FFLAB-C166-09 MININT-2M3M7FQ      True RegisteredDevice
    FFLAB-C166-10 MININT-G7QBGH2      True RegisteredDevice
    FFLAB-C166-11 FFLAB-C166-11       True RegisteredDevice
    FFLAB-C166-12 FFLAB-C166-12       True RegisteredDevice
    FFLAB-C166-13 MININT-HU9MN1A      True RegisteredDevice
    FFLAB-C166-14 MININT-H7O02VG      True RegisteredDevice
    FFLAB-C166-15 FFLAB-C166-15       True RegisteredDevice
    FFLAB-C166-16 MININT-LG397OO      True RegisteredDevice

    An example showing how it can be used for finding machines when the Azure hostname doesn't match the AD hostname.

    .EXAMPLE
    Find-AzureADDevice fflab-166* | ft ComputerName,DisplayName,IsManaged,ProfileType

    ComputerName DisplayName   IsManaged ProfileType
    ------------ -----------   --------- -----------
    FFLAB-166-01 FFLAB-166-01       True RegisteredDevice
    FFLAB-166-02 FFLAB-166-02       True RegisteredDevice
    FFLAB-166-03 FFLAB-166-03$
    FFLAB-166-04 FFLAB-166-04       True RegisteredDevice
    FFLAB-166-05 FFLAB-166-05$
    FFLAB-166-06 FFLAB-166-06$
    FFLAB-166-07 FFLAB-166-07       True RegisteredDevice
    FFLAB-166-08 FFLAB-166-08       True RegisteredDevice
    FFLAB-166-09 FFLAB-166-09$
    FFLAB-166-10 FFLAB-166-10       True RegisteredDevice
    FFLAB-166-11 FFLAB-166-11$
    FFLAB-166-12 FFLAB-166-12$

    Useful for finding machines that aren't registered in Azure properly.
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

