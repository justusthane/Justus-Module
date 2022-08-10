function Get-DHCPScopeFromIPAddress {
  <#
    .Synopsis
    Find the DHCP scope that given IP address is part of.

    .Description
    This cmdlet communicates with the DHCP server specified in -ComputerName to determine what scope a given IP address is a member of.
    
    Can take a single IP address or an array, provided by -IPAddress or by pipeline

    .Example
    Get-DHCPScopeFromIPAddress -IPAddress 10.3.62.6 -computername dhcpserver01

#>
    param (
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
        # Specify the IP address(s)
        $IPAddress,
        # Specify the DHCP server hostname
        [string]$ComputerName
        )

    BEGIN {

    }

    PROCESS {
      $arguments = @{
        IPAddress = $IPAddress
        }

      If ($ComputerName) {
        $arguments.Add("ComputerName", $ComputerName)
        }

        $output = Get-DHCPServerv4Lease @arguments | ForEach { Get-DHCPServerv4Scope $_.ScopeID -ComputerName $arguments.ComputerName } 
        $output.PSObject.TypeNames.Insert(0, 'Justus-Module.Get-DHCPScopeFromIPAddress.Output')
        $output

    }

    END {
    }

}
