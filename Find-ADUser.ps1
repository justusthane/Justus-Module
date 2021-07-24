<#
  .Synopsis
  Find-ADUser is a wrapper for Get-ADUser which searches a set of attributes using a single search string.

  
  .Description
  By default, only a select subset of properties are returned. Use the -Properties parameter to specify which properties to return, or * for all.

  .Example
  Find-ADUser jbad

  Search for a user by part of their name (not that wildcards are not necessary)

  .Example
  Find-ADUser -SearchString jbad -Properties DisplayName,SAMAccountName,MemberOf

  Specify which properties to return
  .Example 
  Find-ADUser shurget@confederation

  DisplayName              Name     SAMAccountName
  -----------              ----     --------------
  jbadergr (Justus Grunow) jbadergr jbadergr

  Because the command also searches proxyAddresses, it can be used to find out what user a specific email address is attached to:


#>
function Find-ADUser {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    # Specify the search string
    [string]$SearchString,
    # Specify which properties to return, or * for all
    # 
    [array]$Properties = ("DisplayName","Name","SAMAccountName")
  )
  $searchAttributes = "DisplayName -like '*$searchString*' `
    -or Name -like '*$searchString*' `
    -or proxyAddresses -like '*$SearchString*'"

  Get-ADUser -filter $searchAttributes -Properties $Properties | Select-Object -Property $Properties
}
