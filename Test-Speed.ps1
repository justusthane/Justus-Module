function Test-Speed {
  <#
    .Synopsis
    Wrapper around Speedtest.net's commandline "speedtest.exe" tool that allows for multiple speed tests to be performed during a specified timeframe.

    .Description
    Run multiple speed tests using Speedtest.net's commandline speedtest.exe tool. Running without any parameters will run a single speed test immediately.

    Alternatively, you may specify *either* a number of repetitions to perform (-Repetitions) *or* time to stop at (-EndTime), but not both. You may also provide a -StartTime along with either option to delay the start.

   This provides the ability to, for example, run a speed test every 10 minutes between 3:00am and 5:00am, or run 30 speed tests every five minutes starting now.

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
    Test-Speed -Repetitions 5 -ServerID 10300

    Specify speedtest.net server to use. A list of nearby servers can be obtained by running `speedtest.exe -L`.

    If a server isn't specified, speedtest.exe will automatically choose a nearby server on the first loop, and will use the same server for each subsequent loop.
#>
    [cmdletbinding(DefaultParametersetname="Repetitions")]
    param (
        # Specify the end time. Accepts any format accepted by "Get-Date", e.g. "3:00am" or "2021/04/06 3:00pm". Specify this parameter OR -Repetitions, but not both.
        [Parameter(Mandatory = $true, ParameterSetName = "EndTime")]
        [DateTime]$EndTime,
        # Specify the number of repetitions to perform. Specify this parameter OR -EndTime, but not both.
        [Parameter(ParameterSetName = "Repetitions")]
        [int]$Repetitions = 1,
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

  # Pass the input of the -StartTime and -EndTime (if specified) paramaters to Get-Date. This causes the provided 
  # string to be evaluated by Get-Date and enables natural language formats such as "3:05am" or "2021/05/24 12pm" to be used.
  $StartTime = Get-Date $StartTime
  If ($EndTime) {$EndTime = Get-Date $EndTime}

  # Arguments to pass to speedtest.exe
  $arguments = @("--format=csv","--output-header")

  # Properties to select from speedtest.exe results
  $properties = @(
    @{l="Time";e={$time}},
    @{l="ServerName";e={$_."server name"}},
    @{l="ServerID";e={$_."server id"}},
    @{l="Latency";e={$_."latency"}},
    @{l="Jitter";e={$_."jitter"}},
    @{l="PacketLoss";e={$_."packet loss"}},
    @{l="Download(Mb)";e={$_."download bytes"/1024/1024}},
    @{l="Upload(Mb)";e={$_."upload bytes"/1024/1024}},
    @{l="ShareURL";e={$_."share url"}}
  )

  # If it ain't time to start yet sleep a while
  while ($(Get-Date) -lt $StartTime) {
    Start-Sleep -seconds 10
  }

  # Do the magic. This loop works whether -Repetitions or -EndTime is provided, because if $Repetitions is $Null,
  # then "$ -le $Repetitions" will continue to evaluable to $False, but "Get-Date -lt $EndTime" will be $True once
  # the current time is past the end time.
  for ($i = 1; (($i -le $Repetitions) -or ($(get-date) -lt $EndTime)); $i++) {
    # Don't sleep on the first loop. Otherwise, sleep for the specified interval.
    if ($i -ne 1) {
      Start-Sleep -Seconds $($Interval * 60)
    }
    
    # Get the current time
    $time = Get-Date

    # If the -ServerID parameter has been specified, then add "--server-id" to the list of parameters to 
    # pass to speedtest.exe. Otherwise it will automatically choose a server.
    If ($ServerID) {
      $arguments += "--server-id=$ServerID"
    }

    # Call speedtest.exe with the specifified arguments and convert the output from CSV to a PowerShell object, then
    # customize the resulting properties, then
    # Tee the results (print them to screen and also save them to $results variable so we can get the server ID later.
    . $SpeedtestExe $arguments | ConvertFrom-Csv | Select-Object -Property $properties | Tee-Object -Variable results
    
    # If -ServerID parameter has not been specified, then set $ServerID to the server automatically selected in the first loop so that
    # the script uses the same server for each repetition.
    If (-Not($ServerID)) {
      $ServerID = $results."server id"
    }
  }
}
