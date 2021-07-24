<#
  .Synopsis
  Find-ADUser is a wrapper for Get-ADUser which searches a set of attributes using a single search string.

  
  .Description
  By default, only a select subset of properties are returned. Use the -Properties parameter to specify which properties to return, or * for all.
  
  This cmdlet can also be handy for finding what user an email alias is attached to. Just specify the alias as the search string.

  .Example
  Find-ADUser jbad

  Search for a user by part of their name (note that wildcards are not necessary).

  .Example
  Find-ADUser -SearchString jbad -Properties DisplayName,SAMAccountName,MemberOf

  Specify which properties to return. By default, it returns DisplayName, Name, and SAMAccountName.
  
  .Example 
  Find-ADUser shurget@confederation

  DisplayName              Name     SAMAccountName
  -----------              ----     --------------
  jbadergr (Justus Grunow) jbadergr jbadergr

  Because the command also searches proxyAddresses, it can be used to find out what user a specific email address is attached to.


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
