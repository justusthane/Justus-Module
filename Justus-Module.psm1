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

  $array = @()

  Write-Host "Enter array elements one line at a time. Press enter on an empty line when done."


  Do {
    $newElement = Read-Host
    If ($newElement) {$array += $newElement}
  } While ($newElement)

  $array
}



