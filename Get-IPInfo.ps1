function Get-IPInfo {
<#
  .Synopsis
  Gets info about the provided IP address from ipinfo.info

  .Description
  This cmdlet is a very simple wrapper that curls ipinfo.io for the specified IP address. If no IP address is specified using the -IPAddress parameter, then it returns info about your IP address.
  #>
 param (
   # Specify the IP address
   [string]$IPAddress
 )
 curl https://ipinfo.io/$IPAddress | ConvertFrom-Json
}
