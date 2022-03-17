# TODO

function Out-VisiData {
  <#
    .Synopsis

    A simple cmdlet that allows output of other cmdlets (e.g. Get-Process) to be piped into the excellent VisiData a Excel-like TUI experience for analyzing data on the command line on Windows machines.
    
    On *nix, piping is supported by VisiData natively.

    This makes an excellent (and much better) alternative to PowerShell's Out-GridView cmdlet.

    .Description

    Requires VisiData to be installed, which can be installed with:

    > pip install visidata
    > pip install windwows-curses

    .Example
    Get-Process | Out-VisiData


#>
    param (
        [Parameter(ValueFromPipeline=$true,Mandatory=$True)]
        # Specify the IP address(s)
        $Input
        )

    BEGIN {
        $tempFile = New-TemporaryFile
    }

  PROCESS {
    $Input | Export-CSV -Path $tempFile.FullName -NoTypeInformation -Append
  }

  END {
      VisiData.exe $tempFile.FullName -f csv
      Remove-Item -Path $tempFile.FullName -Force
    }
}
