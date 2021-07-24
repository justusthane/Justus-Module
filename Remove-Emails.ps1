function Remove-Emails {
  <#
    .Synopsis
    This cmdlet is designed to take a CSV of emails output from Barracuda and remove them
    from Exchange mailboxes, on-prem or O365.

    .Description
    In the event that a phishing email gets through Barracuda, you can export a CSV of the
    delivered messages (hint: export from appliance, not CPL). Running this cmdlet on the CSV
    will remove the delivered messages from each mailbox they were sent to.

    This is much faster than searching all mailboxes for a given email, as it only operates
    on mailboxes that actually received the email.

    It can be used for both on-prem Exchange and Exchange Online, but must be run separately for
    each premises. It will let you know if there are mailboxes in the other premise that also need to be searched.

    For on-prem, it must be run within the Exchange Management Shell. For Exchange Online/O365, it requires
    the Exchange Online Management module.

  #>
  param (
    [Parameter(Mandatory)]
    [ValidateScript({
      If (-Not ($_ | Test-Path) ) {
        throw "File does not exist"
      }
      If (-Not ($_ | Test-Path -PathType Leaf) ) {
        throw "Path must be a file"
      }
      return $true
    })]
    # Specify the path to the input CSV
    [System.IO.FileInfo]$InputCsv,
    # Only search mailboxes, do not remove emails.
    [switch]$WhatIf,
    # Don't prompt for each mailbox.
    [switch]$Force
  )

  $toDelete = Import-Csv $InputCsv | Where {$_.Action -eq "Allowed" -And $_."Delivery Status" -eq "Delivered" } 

  $onPrem = @()
  $offPrem = @()

  $toDelete | ForEach {
    If ((get-recipient $_.To).RecipientType -eq "UserMailbox") {
      $onPrem += $_
    }
    ElseIf ((get-recipient $_.To).RecipientType -eq "MailUser") {
      $offPrem += $_
    }
  }

  $onPrem | ForEach {
    $_ | select Time,From,To,Subject,Action,"Delivery Status"
  } | ft

  Write-Host "Emails matching the above will be deleted.`n"
  If ($WhatIf) { Write-Host "The script is in WhatIf mode. Items will not be deleted.`n" -ForegroundColor "Yellow" }
  Write-Host "Warning: This script only considers the received date, not the time. Any emails matching the sender and subject on this date will be deleted.`n" -ForegroundColor "Yellow"
  If ((-Not ($Force)) -And (-Not ($WhatIf))) { Write-Host "You did not specify -Force, so you will be prompted for each mailbox." }
  If ($(Read-Host -prompt "Proceed? [Y/N]") -ne "Y" ) {
    Write-Host "Aborting"
    break
  }
  
  $onPrem | ForEach {
    $Arguments = @{
      Identity = $_.To
      SearchQuery = "Received:$(Get-Date -Date $_.Time -Format 'yyyy-MM-dd') and From:$($_.From) and Subject:$($_.Subject)"
    }
    If ($WhatIf) {
      $Arguments.EstimateResultOnly = $True
    } Else {
      $Arguments.DeleteContent = $True
    }
    If ($Force) {
      $Arguments.Force = $True
    }
    Search-Mailbox @Arguments
  }
  Write-Host "The messages should have been deleted."
  If ($offPrem) { 
    Write-Host "Some mailboxes could not be searched due to being in the other premises." 
    Write-Host "The following mailboxes are located in the other premises and could not be searched. Please run this cmdlet again in the other premises to delete those messages:`n" -ForegroundColor "Yellow"
    Write-Host "E.g. If you're running this on Office365, please run again on-prem, or vice versa.`n"

    $offPrem | ForEach {
      $_.To
    }
  }

}
