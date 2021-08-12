function Get-MigrationBatchStatus {
  param (
    $BatchID
  )
  Check-LoadedModule "ExchangeOnlineManagement"
  get-migrationuser -BatchId $BatchID | Sort-Object DataConsistencyScore | Select-Object Identity,Status,ErrorSummary,DataConsistencyScore,HasUnapprovedSkippedItems
}

function Get-SkippedItem {
  param (
    $BatchID
  )
  Check-LoadedModule "ExchangeOnlineManagement"
  get-migrationuser -BatchId $BatchID |
  Where-Object { $_.HasUnapprovedSkippedItems -eq $True } |
  Get-MigrationUserStatistics -IncludeSkippedItems |
  Select-Object -Expand SkippedItems @{label="UserIdentity";expression={$_.Identity}} |
  Where-Object {$_.Kind -ne "CorruptFolderACL" } |
  Select-Object @{label="Identity";expression={$_.UserIdentity}},Kind,FolderName,Subject,DateReceived,@{label="MessageSizeMB";expression={$_.MessageSize/1024/1024}}
}

