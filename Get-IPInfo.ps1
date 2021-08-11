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

# whois.cymru.com doesn't supply an API we can use, so we'll scrape the HTML instead.
# Fetch the website, and save session info (cookies, etc) to $webSession variable
    $response = Invoke-WebRequest https://whois.cymru.com/ -SessionVariable $webSession
# Get the HTML form from the response
    $form = $response.Forms[0]
# Fill out the form with the necessary info
    $form.Fields.bulk_paste = $IPAddress
    $form.Fields.method_whois = "on"
    $form.Fields.method_peer = ""
# Submit the form and get our response!
    $response = Invoke-WebRequest -Uri https://whois.cymru.com/cgi-bin/whois.cgi -WebSession $webSession -Method POST -Body $form.Fields
# Parse the returned HTML for the info we're looking for. Matches are automatically saved to the $Matches variable which we use later.
# Output is piped to Out-Null, otherwise it returns the string "True" to indicate that a match was found.
    $response.Content -match '(\d+?)\s+?\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+?)\s+\|\s(.+)' | Out-Null

# Build a custom object with our collected info
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

# Return the object.
  $object
}
