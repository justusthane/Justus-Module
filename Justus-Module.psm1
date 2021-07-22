function Check-LoadedModule {
  Param( [parameter(Mandatory = $true)][alias("Module")][string]$ModuleName)
    $LoadedModules = Get-Module | Select Name
    if (!$LoadedModules -like "*$ModuleName*") {Import-Module -Name $ModuleName}
}
