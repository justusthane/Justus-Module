function Remove-Emails {
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
    [System.IO.FileInfo]$InputCsv,
    [switch]$WhatIf,
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
  Write-Host "Some mailboxes could not be searched" -ForegroundColor "Yellow"
  Write-Host "The following mailboxes are in the other premises, so please run this script again there to delete those messages:`n"
  Write-Host "E.g. If you're running this on Office365, please run again on-prem, or vice versa.`n"

  $offPrem | ForEach {
    $_.To
  }

}
