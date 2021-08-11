# TODO
# - Use ARIN's RDAP API instead of RWS, which is deprecated

function Get-IPInfo {
  <#
    .Synopsis
    Gets info about the provided IP address.

    .Description
    This cmdlet queries various sources (currently ARIN and cymru.com) for information about a given IP, including WHOIS and ASN info.

    This cmdlet is brittle as it relies on parsing HTML, and may break if the websites it scrapes change their format. If so, please submit an issue on the repo (https://github.com/justusthane/Justus-Module) and I'll fix it (or fix it yourself and submit a PR)

    Can accept multiple IP addresses in an array as pipeline input. See examples.

    .Example
    Import-Csv .\IOCs.csv | ? {$_.type -eq "ip-dst"} | select -expand value | get-ipinfo | ft

    Get list of IPs from CSV.
#>
    param (
    [Parameter(Mandatory,ValueFromPipeline=$true)]
# Specify the IP address(s)
        [array]$IPAddress
        )

    BEGIN {}

    PROCESS {
      $IPAddress | ForEach-Object {
    # Get the network info from ARIN
    $net = [xml]$(Invoke-WebRequest http://whois.arin.net/rest/ip/$_) | Select-Object -expand Net
    # Get the organization associated with the network from ARIN
    # Some networks have "Customers" rather than "Organizations". This checks which exists and fetches the appropriate one.
    If ($net.orgRef."#text") {
      $org = [xml]$(Invoke-WebRequest $($net.orgRef."#text")) | Select-Object -expand Org
    } ElseIf ($net.customerRef."#text") {
      $org = [xml]$(Invoke-WebRequest $($net.customerRef."#text")) | Select-Object -expand customer
    }


# whois.cymru.com doesn't supply an API we can use, so we'll scrape the HTML instead.
# Fetch the website, and save session info (cookies, etc) to $webSession variable
    $response = Invoke-WebRequest https://whois.cymru.com/ -SessionVariable $webSession
# Get the HTML form from the response
    $form = $response.Forms[0]
# Fill out the form with the necessary info
    $form.Fields.bulk_paste = $_
    $form.Fields.method_whois = "on"
    $form.Fields.method_peer = ""
# Submit the form and get our response!
    $response = Invoke-WebRequest -Uri https://whois.cymru.com/cgi-bin/whois.cgi -WebSession $webSession -Method POST -Body $form.Fields
# Parse the returned HTML for the info we're looking for. Matches are automatically saved to the $Matches variable which we use later.
# Output is piped to Out-Null, otherwise it returns the string "True" to indicate that a match was found.
    $response.Content -match '(\d+?)\s+?\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+)' | Out-Null

# Build a custom object with our collected info
    $object = [PSCustomObject]@{
      IPAddress = $_
      Network = "$($net.netBlocks.netBlock.startAddress)/$($net.netBlocks.netBlock.cidrLength)"
        Organization = $org.name
        City = $org.city
        Region = $org.'iso3166-2'
        Country = $org.'iso3166-1'.name
        ASN = $Matches[1]
        ASNOrg = $Matches[7]
        ASNRegistry = $Matches[5]
        ASNRoute = $Matches[3]
        WHOIS = "https://search.arin.net/rdap/?query=$_"

    }

# Return the object.
  $object
    }
    }

    END {}
}
