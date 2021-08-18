function Test-Speed {
  <#
    .Synopsis
    Wrapper around Speedtest.net's commandline "speedtest.exe" tool that allows for multiple speed tests to be performed during a specified timeframe.

    .Description
    Run multiple speed tests using Speedtest.net's commandline speedtest.exe tool. You must specify *either* -Repetitions *or* -EndTime. All other parameters are optional. 

    It has the functionality to, for example, run a speed test every 10 minutes between 3:00am and 5:00am, or run 30 speed tests every five minutes starting now.

    See `Get-Help Test-Speed -Examples` for more.

    Requires speedtest.net's speedtest.exe, which can be downloaded here: https://www.speedtest.net/apps/cli (choose the Download for Windows option, obviously). After downloading, speedtest.exe must exist in your PATH, OR you can specify the full path to the exe using the -SpeedtestExe parameter.
    .Example
    Test-Speed -Interval 5 -Repetitions 10 | Tee-Object -Variable results

    Run speed every five minutes, ten times in a row, and save the results to $results as well as printing them to screen.

    .Example
    Test-Speed -Interval 0.5 -EndTime "3:36pm"

    Run a speed test every 30 seconds from now until 3:36pm

    .Example
    Test-Speed -Interval 10 -StartTime "2:00am" -EndTime "5:00am"

    Run a speed test every 10 minutes between 2:00am and 5:00am

    .Example
    Test-Speed -Interval 10 -StartTime "2021/08/19 3:00am" -EndTime "2021/08/19 7:00am"
    
    .Example
    Test-Speed -Repetitions 5 -ServerID 11355

    Specify speedtest.net server to use. A list of nearby servers can be obtained by running `speedtest.exe -L`.

    If a server isn't specified, speedtest.exe will automatically choose a nearby server on the first loop, and will use the same server for each subsequent loop.
#>
    param (
        # Specify the end time. Accepts any format accepted by "Get-Date", e.g. "3:00am" or "2021/04/06 3:00pm". Specify this parameter OR -Repetitions, but not both.
        [Parameter(Mandatory = $true, ParameterSetName = "EndTime")]
        [DateTime]$EndTime,
        # Specify the number of repetitions to perform. Specify this parameter OR -EndTime, but not both.
        [Parameter(Mandatory = $true, ParameterSetName = "Repetitions")]
        [int]$Repetitions,
        [Parameter(ParameterSetName = "EndTime")]
        [Parameter(ParameterSetName = "Repetitions")]
        # Specify the interval between tests in minutes. Defaults to 1.
        [int]$Interval = 1,
        [Parameter(ParameterSetName = "EndTime")]
        [Parameter(ParameterSetName = "Repetitions")]
        # Specify the start time. Accepts any format accepted by "Get-Date", e.g. "3:00am" or "2021/04/06 3:00pm". Defaults to NOW.
        [DateTime]$StartTime = $(Get-Date),
        [Parameter(ParameterSetName = "EndTime")]
        [Parameter(ParameterSetName = "Repetitions")]
        # Specify speedtest.net server ID to use. Otherwise automatically chooses one.
        [int]$ServerID,
        [Parameter(ParameterSetName = "EndTime")]
        [Parameter(ParameterSetName = "Repetitions")]
        # Full path to speedtest.exe, if not in PATH. E.g. "C:\speedtest\speedtest.exe"
        [System.IO.FileInfo]$SpeedtestExe = "speedtest.exe"
        )

  $StartTime = Get-Date $StartTime
  If ($EndTime) {$EndTime = Get-Date $EndTime}

  while ($(Get-Date) -lt $StartTime) {
    Start-Sleep -seconds 10
  }

  for ($i = 1; (($i -le $Repetitions) -or ($(get-date) -lt $EndTime)); $i++) {
    # Don't sleep on the first loop. Otherwise, sleep for the specified interval.
    if ($i -ne 1) {
      Start-Sleep -Seconds $($Interval * 60)
    }
    $time = Get-Date
    $arguments = @("--format=csv","--output-header")
    If ($ServerID) {
      $arguments += "--server-id=$ServerID"
    }
    . $SpeedtestExe $arguments | ConvertFrom-Csv | Select-Object -Property *,@{l="Time";e={$time}} | Tee-Object -Variable results
    If (-Not($ServerID)) {
      $ServerID = $results."server id"
    }
  }



}
