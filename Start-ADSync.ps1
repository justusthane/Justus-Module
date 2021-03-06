function Start-ADSync {
  <#
  .SYNOPSIS
  Triggers an Azure AD sync on the specified computer (must be your server running the AD Sync application).

  .EXAMPLE
  Start-ADSync -ComputerName ad-connect
  #>
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [Parameter(Mandatory)]
    # Specify computer name
    [string]$ComputerName
  )

  If ($PSCmdlet.ShouldProcess($ComputerName,'Initiating AD delta sync')) {
    Invoke-Command -ComputerName $ComputerName -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Delta }
  }
}
