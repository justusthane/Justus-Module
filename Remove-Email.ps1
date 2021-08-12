function Remove-Email {
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

  [CmdletBinding(SupportsShouldProcess)]
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
    # Specify -Force to prevent prompting for each mailbox
    [switch]$Force
  )

  $toDelete = Import-Csv $InputCsv | Where-Object {$_.Action -eq "Allowed" -And $_."Delivery Status" -eq "Delivered" -And ( $_.To -Like "*@confederationcollege.ca" -Or $_.To -Like "*@confederationc.on.ca" ) }

  $onPrem = @()
  $offPrem = @()

  # Loop through each row of the CSV and determine if the mailbox is in the current prem or other prem.
  $toDelete | ForEach-Object {
    If ((get-recipient $_.To).RecipientType -eq "UserMailbox") {
      $onPrem += $_
    }
    ElseIf ((get-recipient $_.To).RecipientType -eq "MailUser") {
      $offPrem += $_
    }
  }

  $onPrem | ForEach-Object {
    $_ | Select-Object @{l="Time";e={Get-Date -Date $_.Time -Format 'yyyy-MM-dd'}},From,To,Subject,Action,"Delivery Status"
  } | Format-Table

  If ($WhatIfPreference) {
    Write-Information -InformationAction Continue "The script is in WhatIf mode, so no emails will be deleted.`n"
  }
  Else {
    Write-Information -InformationAction Continue "Emails matching the above will be deleted.`n"
  }
  
  If ($offPrem) {
    Write-Information -InformationAction Continue "Additional mailboxes were found in the other premises. Please run script again there when done.`n"
  }
  Write-Warning "This script only considers the received date, not the time. Any emails matching the sender and subject on this date will be deleted.`n"
  If ((-Not ($Force)) -And (-Not ($WhatIfPreference))) { Write-Information -InformationAction Continue "You did not specify -Force, so you will be prompted for each mailbox." }
  If ($(Read-Host -prompt "Proceed? [Y/N]") -ne "Y" ) {
    Write-Information -InformationAction Continue "Aborting"
    break
  }

  # These are needed to add "Yes to all"/"No to all" functionality
  $yesToAll = $false
  $noToAll = $false

  $onPrem | ForEach-Object {
    If ($Force -Or $WhatIfPreference -Or $PSCmdlet.ShouldContinue($_.To,"Delete messages",[ref]$yesToAll,[ref]$noToAll)) {
    $Arguments = @{
      Identity = $_.To
      SearchQuery = "Received:$(Get-Date -Date $_.Time -Format 'yyyy-MM-dd') and From:$($_.From) and Subject:$($_.Subject)"
      # We take care of prompting in the script, so supress Search-Mailbox's prompt
      Force = $True
      WarningAction = "SilentlyContinue"
    }

    # If -WhatIf parameter is specified, show results only
    If ($WhatIfPreference) {
      $Arguments.EstimateResultOnly = $True
    } 
    # Otherwise delete
    Else {
      $Arguments.DeleteContent = $True
    }
    Search-Mailbox @Arguments
    }
  }
  If (-Not ($WhatIfPreference)) {
    Write-Information -InformationAction Continue "The messages should have been deleted."
  }
  If ($offPrem) {
    Write-Information -InformationAction Continue "Some mailboxes could not be searched due to being in the other premises."
    Write-Information -InformationAction Continue "The following mailboxes are located in the other premises and could not be searched. Please run this cmdlet again in the other premises to delete those messages:`n"
    Write-Information -InformationAction Continue "E.g. If you're running this on Office365, please run again on-prem, or vice versa.`n"

    $offPrem | ForEach-Object {
      $_.To
    }
  }

}
