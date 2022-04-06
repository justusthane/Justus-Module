#function Check-LoadedModule {
#  Param( [parameter(Mandatory = $true)][alias("Module")][string]$ModuleName)
#    $LoadedModules = Get-Module | Select Name
#    if (!$LoadedModules -like "*$ModuleName*") {Import-Module -Name $ModuleName}
#}

function New-Array {
  <#
    .SYNOPSIS
    A cute little helper cmdlet that takes the pain out of generating new arrays on the fly.

    .DESCRIPTION

    You might sometimes have the need to generate an array on the fly, doing something like this:

    PS >"jbadergr","joesmith","fred flintstone" | find-aduser

    But who likes typing all those quotes and commas? Not me!

    This cmdlet allows you to the following instead:

    PS >New-Array | find-aduser

    It will then prompt you to add new array elements, one per line, no quotes or commas needed!

    .EXAMPLE
    New-Array | find-aduser

    ===OUTPUT===
    Enter array elements one line at a time. Press enter on an empty line when done.
    jbadergr
    joesmith
    fred flintstone


    DisplayName     : jbadergr (Justus Grunow)
    SAMAccountName  : jbadergr
    Description     : Support Staff Account 2021
    PasswordLastSet : 1/18/2021 12:15:54 PM
    PasswordExpired : False
    Enabled         : True
    LockedOut       : False
    MailboxLocation : O365

    DisplayName     : jsmith (Joe Smith)
    SAMAccountName  : jsmith
    Description     : Staff Account 2015
    PasswordLastSet : 2/22/2021 8:34:53 AM
    PasswordExpired : False
    Enabled         : True
    LockedOut       : False
    MailboxLocation : O365

    DisplayName     : fflintstone (Fred Flintstone)
    SAMAccountName  : fflintstone
    Description     : Staff Account 2015
    PasswordLastSet : 2/22/2021 8:34:53 AM
    PasswordExpired : False
    Enabled         : True
    LockedOut       : False
    MailboxLocation : O365
  #>
  [CmdletBinding(SupportsShouldProcess)]
  param()

  # This is just here to make PSScriptAnalyzer happy
  If ($PSCmdlet.ShouldProcess("New array")) {
  $array = @()

  Write-Information "Enter array elements one line at a time. Press enter on an empty line when done." -InformationAction Continue

  Do {
    $newElement = Read-Host
    If ($newElement) {$array += $newElement}
  } While ($newElement)

  $array
  }
}



function New-Password {
  <#
    .SYNOPSIS
    Generate random passwords

    .DESCRIPTION

    Generates random password(s) of the specified length. Change the length with the -Length paramater (default 12 chars).

    By default returns a single password, use the -NumberOfPasswords parameter to generate a list.

    By default it will avoid amibuous characters ("liI1O0"). This may incur a slight performance hit. To disable this behavior, use -AvoidAmbiguousCharacters $False

    By default displays passwords using Out-GridView so that they're not saved in terminal history. Use -GridView $False to output to terminal instead.

    Inspired by https://adamtheautomator.com/random-password-generator/
  #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    # The password length
    [int]$Length = 14,
    # The minimum number of special characters
    [int]$SpecialCharacters = 2,
    # Specify the number of passwords to generate (default 1)
    [int]$NumberOfPasswords = 1,
    # Set to $False to not avoid ambiguous characters ("liI1O0")
    [boolean]$AvoidAmbiguousCharacters = $True,
    # Set to $False to output to terminal rather than gridview
    [boolean]$GridView = $True,
    # Set to $True to output to VisiData. This is the recommended option if you have VisiData installed. See 'Get-Help Out-VisiData'
    # If you set the $Env:VisiData environment variable to $True, it will output to VisiData by default, but can be overwritten by setting
    # this parameter to $False
    $VisiData = $Env:VisiData
  )

  # This is just here to make PSScriptAnalyzer happy. It complains about cmdlets that use the New- verb otherwise
  If ($PSCmdlet.ShouldProcess("New password")) {
    Add-Type -AssemblyName 'System.Web'
    $passwords = @()
    For ($i = 0; $i -lt $NumberOfPasswords; $i++) {
      do {
        $password = [PSCustomObject]@{
          Password = [System.Web.Security.Membership]::GeneratePassword($Length,$SpecialCharacters)
        }
      } while ($AvoidAmbiguousCharacters -And $password -Cmatch "[liI1O0]")

      $passwords += $password
    } 
    If ($VisiData) {
      $passwords | Out-VisiData
    }
    ElseIf ($GridView) {
      $passwords | Out-GridView
    }
    Else {
      $passwords
    }
  }
}

function Select-Unique {
  <#
    .SYNOPSIS
    Select unique propertie(s) from object

    .DESCRIPTION
    Given an input object, returns only unique combinations of the specified properties.

    .EXAMPLE
    Get-Process | Select-Unique ProcessName

    Get list of each unique running process.

  #>
  param (
      [Parameter(ValueFromPipeline=$true,Mandatory=$True)]
      # Input object to filter
      [PSCustomObject]$Input,
      [Parameter(Position=0)]
      # Unique property(s) to select. If none are specified, all unique rows will be returned.
      [array]$Properties
    )

  BEGIN {
    }

  PROCESS {
      # There's probably a better way to do this, but I don't know it. I need to process the entire input object at once, rather than one row at a time,
      # so I'm building a new array using the input, and then processing it in the END block. Feels hacky and inefficient.
      $object += $Input
    }

  END {
      If (-Not($Properties)) {
        $Properties = $object | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"} | Select-Object -Expand Name
      }
      $object | Group-Object -Property $Properties | %{$_.Group | Select -Property $Properties -first 1 }
    }
}
