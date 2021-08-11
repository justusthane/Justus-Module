function Get-IPInfo {
<#
  .Synopsis
  Gets info about the provided IP address.

  .Description
  This cmdlet queries various sources (currently ARIN and cymru.com) for information about a given IP, including WHOIS and ASN info.
  #>
 param (
   # Specify the IP address
   [string]$IPAddress
 )
 $net = [xml]$(Invoke-WebRequest http://whois.arin.net/rest/ip/$IPAddress) | Select-Object -expand Net
 $org = [xml]$(Invoke-WebRequest $($net.orgRef."#text")) | Select-Object -expand Org
 $response = Invoke-WebRequest https://whois.cymru.com/ -SessionVariable $webSession
 $form = $response.Forms[0]
 $form.Fields.bulk_paste = $IPAddress
 $form.Fields.method_whois = "on"
 $form.Fields.method_peer = ""
 $response = Invoke-WebRequest -Uri https://whois.cymru.com/cgi-bin/whois.cgi -WebSession $webSession -Method POST -Body $form.Fields
 $response.Content -match '(\d+?)\s+?\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+)' | Out-Null


 $object = [PSCustomObject]@{
   Network = "$($net.netBlocks.netBlock.startAddress)/$($net.netBlocks.netBlock.cidrLength)"
   Organization = $net.orgRef.name
   City = $org.city
   Region = $org.'iso3166-2'
   Country = $org.'iso3166-1'.name
   ASN = $Matches[1]
   ASNOrg = $Matches[7]
   ASNRegistry = $Matches[5]
   ASNRoute = $Matches[3]

 }
 $object
}
