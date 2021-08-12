function Find-ADUser {
<#
  .Synopsis
  Find-ADUser is a wrapper for Get-ADUser which searches a set of attributes using a single search string.

  .Description
  By default, only a default subset of properties are returned. Use the -Properties parameter to specify which properties to return, or * for all.

  It also adds a property called "MailboxLocation" that indicates whether the mailbox is on-prem or O365. This works by looking at the msExchRecipientDisplayType AD attribute, which doesn't seem to be well-documented, but after testing seems to work correctly.

  This cmdlet can also be handy for finding what user an email alias is attached to. Just specify the alias as the search string.

  The cmdlet will also accept an array of search strings, to search for multiple users at once.

  .Example
  Find-ADUser jbad

  Search for a user by part of their name (note that wildcards are added automatically and are not necessary).

  .Example
  Find-ADUser jbadergr,swoobec

  Search for multiple users by passing an array.

  .Example
  "jbadergr","swoodbec" | Find-ADUser

  Also accepts pipeline input.

  .Example
  Find-ADUser -SearchString jbad -Properties DisplayName,SAMAccountName,MemberOf

  Specify additional properties to return. Can specify * for all.

  .Example
  Find-ADUser shurget@confederation

  DisplayName              Name     SAMAccountName
  -----------              ----     --------------
  jbadergr (Justus Grunow) jbadergr jbadergr

  Because the command also searches proxyAddresses, it can be used to find out what user a specific email address is attached to.


#>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory,ValueFromPipeline=$true)]
    # Specify the search string, or array of search strings.
    [array]$SearchString,
    # Specify which properties to return, or * for all
    #
    [array]$Properties = @()
  )

  BEGIN {
  $AdditionalProperties = ("DisplayName","SAMAccountName","Description","PasswordLastSet","PasswordExpired","Enabled","LockedOut") + $Properties

  $searchAttributes = "DisplayName -like '*$searchString*' `
    -or Name -like '*$searchString*' `
    -or proxyAddresses -like '*$SearchString*'"
  }


  PROCESS {
    $SearchString | ForEach-Object {
    $searchAttributes = "DisplayName -like '*$_*' `
      -or Name -like '*$_*' `
      -or proxyAddresses -like '*$_*'";
    Get-ADUser -filter $searchAttributes -Properties $($AdditionalProperties + "msExchRecipientDisplayType") |
    Select-Object -Property $($AdditionalProperties + @{l='MailboxLocation';e={If ($_.msExchRecipientDisplayType -eq "1073741824"){"On-prem"} ElseIf ($_.msExchRecipientDisplayType -eq "-2147483642"){"O365"}}})
    }
  }

  END {}
}
