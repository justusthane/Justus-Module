<#
  .Synopsis
  Find-ADUser is a wrapper for Get-ADUser which searches a set of attributes using a single search string.

  By default, only a select subset of properties are returned
  
  .Description
  A description
#>
function Find-ADUser {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    # Specify the search string
    [string]$SearchString,
    [array]$Properties = ("DisplayName","Name","SAMAccountName")
  )
  $searchAttributes = "DisplayName -like '*$searchString*' `
    -or Name -like '*$searchString*' `
    -or proxyAddresses -like '*$SearchString*'"

  Get-ADUser -filter $searchAttributes -Properties $Properties | Select-Object -Property $Properties
}
