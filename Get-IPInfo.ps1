function Get-IPInfo {
 param (
   $IPAddress
 )
 curl https://ipinfo.io/$IPAddress | ConvertFrom-Json
}
