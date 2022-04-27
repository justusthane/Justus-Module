# TODO
# - If an API lookup fails, return the cached record even if it's stale
# - Use ARIN's RDAP API instead of RWS, which is deprecated

function Get-IPInfo {
  <#
    .Synopsis
    Gets info about the provided IP address.

    .Description
    This cmdlet queries various sources (currently ARIN and asn.cymru.com, and optionally abuseipdb.com) for information about a given IP, including WHOIS and ASN info. It caches results (by default) for 24 hours to increase lookup speed and reduce API usage.

    Can accept an array of IP addresses or an object as pipeline input. See examples.

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
    Import-Csv .\IOCs.csv | Get-IPInfo -Property "IP address"

    In this example, the CSV contains a column mamed "IP address" which contains the 
    IP addresses we want to look up.

    .Example
    Import-Csv .\IOCs.csv | Get-IPInfo -Property "IP address" -PassThru | export-csv .\IOCs-with-IPInfo.csv

    The -PassThru takes the input object, adds the IP lookup info to it, and passes the whole thing back out
    the other side. This is useful for e.g. adding IP lookup info to an existing spreadsheet.

    Note that the property names are prepended with "ipinfo_" to avoid conflicts with existing column names.
    This prefix can be changed using the "-PropertyPrefix" parameter.

#>
    param (
        [Parameter(ValueFromPipeline=$true)]
        # Specify the IP address(s)
        $IPAddress,
        # Specify optional abuseipdb.com API key to return abuse info
        [string]$APIKeyAbuseIP,
        # Indicate that abuseipdb.com API key should be read from $Env:APIKeyAbuseIP environment variable. More convenient than providing it via the -APIKey parameter each time
        [switch]$EnvAPIKeyAbuseIP,
        # If fetching abuse info, specify the maximum report age to include (default 60 days)
        [int]$maxReportAge = 60,
        # If piping in an object or hashtable with multiple properties (rather than a simple array of IP addresses), specify which property
        # contains the IP address
        [string]$Property,
        # Take the input object, add the IP lookup results, and spit the whole thing back out the other side. This is useful for e.g. adding IP lookup info to an existing spreadsheet.
        [switch]$PassThru,
        # When using -PassThru, by default the IPInfo property names are prefixed with "ipinfo_" to avoid conflicts with existing property names in the input object. This parameter
        # can be used to change the prefix, or to eliminate it with -Property Prefix ""
        [string]$PropertyPrefix = "ipinfo_",
        # By default, cached results are considered good for 24 hours. If a cached result is greater than 24 hours old, a new lookup will be preformed and the results cached. The lifetime can
        # be changed with this parameter.
        [int]$CacheLifetimeHours = 24
        )

    BEGIN {
      # Initialize a lookup cache to store the results of each lookup. This way if the same IP address is looked up multiple times, it will return the previous result from the cache.
      If (Test-Path $env:TEMP\Justus-Module_get-ipinfo.tmp) {
        $lookupCache = Import-Clixml $env:TEMP\Justus-Module_get-ipinfo.tmp
      } Else {
        $lookupCache = @{}
      }

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

      # If a -Property is specified, then assume that we're dealing with an input object
      # rather than just a simple array of IP addresses, and we need to know which property
      # of the input object contains the IP address.
      If ($Property) {
        $strIPAddress = $IPAddress.$($Property)
      # Otherwise just use the full input string as the IP address.
      } Else {
        $strIPAddress = $IPAddress
      }

      # Perform the lookup if the lookup is not already cached. Also perform the lookup if it IS cached, but an AbuseIPDB lookup is requested and THAT isn't cached. Also perform the lookup if it's cached, but the existing lookupCachewas performed more than $CacheLifetimeHours hours ago.
      If ((-Not ($lookupCache[$strIPAddress])) -Or ($APIKeyAbuseIP -And (-Not ($lookupCache[$strIPAddress].PSObject.Properties.name -contains "AbuseDBTotalReports"))) -Or ($lookupCache[$strIPAddress].LookupTimestamp -lt $(Get-Date).AddHours(-$CacheLifetimeHours))) {
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


        # Build a custom object with our collected info
        $objIPInfo = [PSCustomObject]@{ 
            IPAddress = $strIPAddress
            Network = "$($net.netBlocks.netBlock.startAddress)/$($net.netBlocks.netBlock.cidrLength)"
            Organization = $org.name
            City = $org.city
            Region = $org.'iso3166-2'
            Country = $org.'iso3166-1'.name
            ASN = $Matches[1]
            ASNOrg = $Matches[7]
            ASNRegistry = $Matches[5]
            ASNRoute = $Matches[3]
            WHOIS = "https://search.arin.net/rdap/?query=$strIPAddress"
        }

        # If an API key for AbuseIPDB is specified, fetch abuse info
        If ($APIKeyAbuseIP) {
          $abuseDB = Invoke-WebRequest -Headers @{accept="application/json";key=$APIKeyAbuseIP} -Uri https://api.abuseipdb.com/api/v2/check?ipAddress=$strIPAddress"&"verbose"&"maxAgeInDays=$maxReportAge |
            ConvertFrom-Json | select-object -expand data

          # And add the abuse info to the output $object
          $objIPInfo | Add-Member -NotePropertyMembers @{
            AbuseDBUsageType = $abuseDB.usageType
            AbuseDBConfidenceScore = $abuseDB.abuseConfidenceScore
            AbuseDBDomain = $abuseDB.domain
            AbuseDBHostnames = $abuseDB.hostnames
            AbuseDBTotalReports = $abuseDB.totalReports
            AbuseDBLastReported = $abuseDB.lastReportedAt
            AbuseDBReports = $abuseDB.reports
          }

        }

        # Cache the results
        $objIPInfo | Add-Member -NotePropertyName "LookupTimestamp" -NotePropertyValue $(Get-Date)
        $lookupCache[$strIPAddress] = $objIPInfo

      } Else {
        $objIPInfo = $lookupCache[$strIPAddress]
      }

      # If an AbuseIPDB API key has not been specified, then exclude those properties from the output.
      # This prevents them being returned if they were looked up previously and cached.
      If (-Not($EnvAPIKeyAbuseIP)) {
        $objIPInfo = $objIPInfo | Select -Property * -ExcludeProperty AbuseDB*
      }

      If ($PassThru) {
        # If we're passing through an input object, create a copy of it so we can modify it
        # and pass it back out.
        # We're making the copy in this dumb way, because if we just do
        # $objReturn = $IPAddress, then PowerShell overwrites the content of the input object.
        # This is because objects are passed by reference, not by value.
        $objReturn = New-Object PSObject
        $IPAddress.PSObject.Properties | ForEach {
          If ($_.MemberType -eq "NoteProperty") {
            $objReturn | Add-Member -NotePropertyName $_.Name -NotePropertyValue $_.Value
          }
        }

        # If we're passing through an input object, prepend a string to the property names so
        # we don't clash with existing properties in the input object.
        $objIPInfo.PSObject.Properties | ForEach-Object {
          $objReturn | Add-Member -NotePropertyName "$($PropertyPrefix)$($_.Name)" -NotePropertyValue $_.Value 
        }
        $objReturn
      }
      Else {
        $objIPInfo
      }

  }

  END {
        $lookupCache | Export-Clixml $env:TEMP\Justus-Module_get-ipinfo.tmp -Force 
    }

}
