# TODO
# - Use ARIN's RDAP API instead of RWS, which is deprecated

function Get-IPInfo {
  <#
    .Synopsis
    Gets info about the provided IP address.

    .Description
    This cmdlet queries various sources (currently ARIN and asn.cymru.com, and optionally abuseipdb.com) for information about a given IP, including WHOIS and ASN info.

    Can accept multiple IP addresses in an array as pipeline input. See examples.

    If you pass in an AbuseIPDB API key using the -APIKeyAbuseIP parameter, it will also return reported abuse information. A free API key can be obtained by visiting abuseipdb.com.

    If called without an -IPAddress, it will return info about your own public address.

    This cmdlet is brittle as it relies on parsing HTML, and may break if the websites it scrapes change their format. If so, please submit an issue on the repo (https://github.com/justusthane/Justus-Module) and I'll fix it (or fix it yourself and submit a PR)

    .Example
    Get-IPInfo

    Return info about your own public IP.

    .Example
    Get-IPInfo 192.197.60.2 -APIKeyAbuseIP bc14402430203d51df58e83daf642871efc2b0a3221f73c96da249d2b68e35ae1d6633249daa5421

    Returns abuse info from abuseipdb.com. Go to abuseipdb.com to register for a free API key (up to 1000 checks/day).

    .Example
    Import-Csv .\IOCs.csv | ? {$_.type -eq "ip-dst"} | select -expand value | get-ipinfo | ft

    Get list of IPs from CSV.

#>
    param (
        [Parameter(ValueFromPipeline=$true)]
        # Specify the IP address(s)
        [array]$IPAddress,
        # Specify optional abuseipdb.com API key to return abuse info
        [string]$APIKeyAbuseIP,
        # Indicate that abuseipdb.com API key should be read from $Env:APIKeyAbuseIP environment variable. More convenient than providing it via the -APIKey parameter each time
        [switch]$EnvAPIKeyAbuseIP,
        # If fetching abuse info, specify the maximum report age to include (default 60 days)
        [int]$maxReportAge = 60,
        [string]$Property,
        [switch]$PassThru
        )

    BEGIN {
      # Initialize a lookup cache to store the results of each lookup. This way if the same IP address is looked up multiple times, it will return the previous result from the cache.
      $lookupCache = @{}

      # If -IPAddress isn't specified, fetch current public IP from icanhazip.com and use that instead.
      # I'm using icanhazip.com because despite the...dated...name, it's been taken over by Cloudflare
      # so I have confidence it will be around for a while.
      If (-Not($IPAddress)) {
        $IPAddress = $(Invoke-WebRequest http://icanhazip.com/).Content.Trim()
      }
      # If the -EnvApiKeyAbuseIP parameter is set, load the API key from the environment variable.
      If ($EnvAPIKeyAbuseIP) {
        $APIKeyAbuseIP = $Env:APIKeyAbuseIP
      }

    }

  PROCESS {
    #$IPAddress | ForEach-Object {

      If ($Property) {
        $strIPAddress = $IPAddress.$($Property)
      } Else {
        $strIPAddress = $IPAddress[0]
      }

      If ($lookupCache[$strIPAddress]) {
        $lookupCache[$strIPAddress]
      } Else {

        # Get the network info from ARIN
        $net = [xml]$(Invoke-WebRequest http://whois.arin.net/rest/ip/$strIPAddress) | Select-Object -expand Net
        # Get the organization associated with the network from ARIN
        # Some networks have "Customers" rather than "Organizations". This checks which exists and fetches the appropriate one.
        If ($net.orgRef."#text") {
          $org = [xml]$(Invoke-WebRequest $($net.orgRef."#text")) | Select-Object -expand Org
        } ElseIf ($net.customerRef."#text") {
          $org = [xml]$(Invoke-WebRequest $($net.customerRef."#text")) | Select-Object -expand customer
        }


        # Get associated ASN info from cymru.com.
        # whois.cymru.com doesn't supply an API we can use, so we'll scrape the HTML instead.
        # Fetch the website, and save session info (cookies, etc) to $webSession variable
        $response = Invoke-WebRequest https://whois.cymru.com/ -SessionVariable $webSession
        # Get the HTML form from the response
        $form = $response.Forms[0]
        # Fill out the form with the necessary info
        $form.Fields.bulk_paste = $strIPAddress
        $form.Fields.method_whois = "on"
        $form.Fields.method_peer = ""
        # Submit the form and get our response!
        $response = Invoke-WebRequest -Uri https://whois.cymru.com/cgi-bin/whois.cgi -WebSession $webSession -Method POST -Body $form.Fields
        # Parse the returned HTML for the info we're looking for. Matches are automatically saved to the $Matches variable which we use later.
        # Output is piped to Out-Null, otherwise it returns the string "True" to indicate that a match was found.
        $response.Content -match '(\d+?)\s+?\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+)' | Out-Null

        If ($PassThru) {
          $object = $IPAddress
          $propertyPrefix = "ipinfo_"
        }
        Else {
          $object = [PSCustomObject]@{}
          $propertyPrefix = ""
        }

        # Build a custom object with our collected info
        $object | 
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)IPAddress" -NotePropertyValue $strIPAddress |
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)Network" -NotePropertyValue "$($net.netBlocks.netBlock.startAddress)/$($net.netBlocks.netBlock.cidrLength)" |
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)Organization" -NotePropertyValue $org.name |
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)City" -NotePropertyValue $org.city |
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)Region" -NotePropertyValue $org.'iso3166-2' |
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)Country" -NotePropertyValue $org.'iso3166-1'.name |
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)ASN" -NotePropertyValue $Matches[1] |
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)ASNOrg" -NotePropertyValue $Matches[7] |
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)ASNRegistry" -NotePropertyValue $Matches[5] |
            Add-Member -PassThru -NotePropertyName "$($propertyPrefix)ASNRoute" -NotePropertyValue $Matches[3] |
            Add-Member -NotePropertyName "$($propertyPrefix)WHOIS" -NotePropertyValue "https://search.arin.net/rdap/?query=$strIPAddress" 

          

        # If an API key for AbuseIPDB is specified, fetch abuse info
        If ($APIKeyAbuseIP) {
          $abuseDB = Invoke-WebRequest -Headers @{accept="application/json";key=$APIKeyAbuseIP} -Uri https://api.abuseipdb.com/api/v2/check?ipAddress=$strIPAddress"&"verbose"&"maxAgeInDays=$maxReportAge |
            ConvertFrom-Json | select-object -expand data

          # And add the abuse info to the output $object
          $object | Add-Member -NotePropertyMembers @{
            ipinfo_AbuseDBUsageType = $abuseDB.usageType
            ipinfo_AbuseDBConfidenceScore = $abuseDB.abuseConfidenceScore
            ipinfo_AbuseDBDomain = $abuseDB.domain
            ipinfo_AbuseDBHostnames = $abuseDB.hostnames
            ipinfo_AbuseDBTotalReports = $abuseDB.totalReports
            ipinfo_AbuseDBLastReported = $abuseDB.lastReportedAt
            ipinfo_AbuseDBReports = $abuseDB.reports
          }

        }

        # Return the object.
        $lookupCache[$strIPAddress] = $object
        $object

      }

    #}
  }

  END {}
}
