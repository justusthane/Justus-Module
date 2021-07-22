function Get-MigrationBatchStatus {
  param (
    $BatchID
  )
  Check-LoadedModule "ExchangeOnlineManagement"
  get-migrationuser -BatchId $BatchID | sort DataConsistencyScore | select Identity,Status,ErrorSummary,DataConsistencyScore,HasUnapprovedSkippedItems
}

function Get-SkippedItems {
  param (
    $BatchID
  )
  Check-LoadedModule "ExchangeOnlineManagement"
  get-migrationuser -BatchId $BatchID | 
  ?{ $_.HasUnapprovedSkippedItems -eq $True } | 
  Get-MigrationUserStatistics -IncludeSkippedItems | 
  select -Expand SkippedItems @{label="UserIdentity";expression={$_.Identity}} | 
  ? {$_.Kind -ne "CorruptFolderACL" } | 
  select @{label="Identity";expression={$_.UserIdentity}},Kind,FolderName,Subject,DateReceived,@{label="MessageSizeMB";expression={$_.MessageSize/1024/1024}}
}

