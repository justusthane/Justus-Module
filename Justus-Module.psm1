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

    Inspired by https://adamtheautomator.com/random-password-generator/
  #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    # The password length
    [int]$Length = 12,
    # The minimum number of special characters
    [int]$SpecialCharacters = 2,
    # Specify the number of passwords to generate (default 1)
    [int]$NumberOfPasswords = 1,
    # Set to $False to not avoid ambiguous characters ("liI1O0")
    [boolean]$AvoidAmbiguousCharacters = $True
  )

  # This is just here to make PSScriptAnalyzer happy. It complains about cmdlets that use the New- verb otherwise
  If ($PSCmdlet.ShouldProcess("New password")) {
    Add-Type -AssemblyName 'System.Web'
    For ($i = 0; $i -lt $NumberOfPasswords; $i++) {
      do {
        $password = [System.Web.Security.Membership]::GeneratePassword($Length,$SpecialCharacters)
      } while ($AvoidAmbiguousCharacters -And $password -Cmatch "[liI1O0]")

      $password
    }
  }
}
