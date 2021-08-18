function Test-Speed {
  <#
    .Synopsis
    Wrapper around Speedtest.net's commandline "speedtest.exe" tool that allows for multiple speed tests to be performed during a specified timeframe.

    .Description
    This cmdlet queries various sources (currently ARIN and cymru.com) for information about a given IP, including WHOIS and ASN info.

    This cmdlet is brittle as it relies on parsing HTML, and may break if the websites it scrapes change their format. If so, please submit an issue on the repo (https://github.com/justusthane/Justus-Module) and I'll fix it (or fix it yourself and submit a PR)

    Can accept multiple IP addresses in an array as pipeline input. See examples.

    .Example
    Import-Csv .\IOCs.csv | ? {$_.type -eq "ip-dst"} | select -expand value | get-ipinfo | ft

    Get list of IPs from CSV.
#>
    param (
# Specify the IP address(s)
        [DateTime]$StartTime = $(Get-Date),
        [int]$Interval = 1,
        [int]$Repetitions = 1,
        [int]$ServerID,
        [System.IO.FileInfo]$SpeedtestPath = "speedtest.exe"
        )

  $StartTime = Get-Date $StartTime
  $EndTime = Get-Date $EndTime

  while ($(Get-Date) -lt $StartTime) {
    Start-Sleep -seconds 10
  }

  for ($i = 1; $i -le $Repetitions; $i++) {
    # Don't sleep on the first loop. Otherwise, sleep for the specified interval.
    if ($i -ne 1) {
      Start-Sleep -Seconds $($Interval * 60)
    }
    $time = Get-Date
    $arguments = @("--format=csv","--output-header")
    If ($ServerID) {
      $arguments += "--server-id=$ServerID"
    }
    . $SpeedtestPath $arguments | ConvertFrom-Csv | Select-Object -Property *,@{l="Time";e={$time}} | Tee-Object -Variable results
    If (-Not($ServerID)) {
      $ServerID = $results."server id"
    }
  }



}
