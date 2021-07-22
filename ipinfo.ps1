function ipinfo {
 param (
   $IPAddress
 )
 curl https://ipinfo.io/$IPAddress
}
