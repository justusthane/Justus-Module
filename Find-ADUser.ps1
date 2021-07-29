function Find-ADUser {
<#
  .Synopsis
  Find-ADUser is a wrapper for Get-ADUser which searches a set of attributes using a single search string.

  
  .Description
  By default, only a default subset of properties are returned. Use the -Properties parameter to specify which properties to return, or * for all.

  It also adds a property called "MailboxLocation" that indicates whether the mailbox is on-prem or O365. This works by looking at the msExchRecipientDisplayType AD attribute, which doesn't seem to be well-documented, but after testing seems to work correctly.
  
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
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    # Specify the search string
    [string]$SearchString,
    # Specify which properties to return, or * for all
    # 
    [array]$Properties = ("DisplayName","SAMAccountName","Description","PasswordLastSet","PasswordExpired","Enabled","LockedOut")
  )
  $searchAttributes = "DisplayName -like '*$searchString*' `
    -or Name -like '*$searchString*' `
    -or proxyAddresses -like '*$SearchString*'"


  Get-ADUser -filter $searchAttributes -Properties $($Properties + "msExchRecipientDisplayType") | 
  Select-Object -Property $($Properties + @{l='MailboxLocation';e={If ($_.msExchRecipientDisplayType -eq "1073741824"){"On-prem"} ElseIf ($_.msExchRecipientDisplayType -eq "-2147483642"){"O365"}}})
}
