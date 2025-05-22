function Set-PFXCertOrder {
  <#
  .SYNOPSIS
  Takes a PFX file as input, displays the contained certs in order, provides the option to reoder them, and saves the reordered result to a new PFX.

  .EXAMPLE
  Set-PFXCertOrder -Path 'C:\users\jbadergr\Desktop\cc-cn-web cert.pfx' -NewPath 'C:\users\jbadergr\Desktop\cc-cn-web cert-reodered.pfx' -Passphrase 'af45jsd$6@jk'
  #>
  param (
    [Parameter(Mandatory)]
    [ValidateScript({
      If ( -Not ($_ | Test-Path ) ) {
        throw "File does not exist"
      }
      Return $True
    })]
    # Specify path to existing PFX (absolute paths only)
    [System.IO.FileInfo]$Path,
    # Path to save new PFX as (absolute paths only)
    [System.IO.FileInfo]$NewPath,
    # Passphrase for PFX
    [string]$Passphrase
  )
  $ErrorActionPreference = "Stop"
  # Convert relative path to abosolute path, because [Security.Cryptography.X509Certificates.X509Certificate2Collection] requires an absolute path.
  $Path = (Get-Item $Path).FullName

  function Out-PFX {
    param (
      $PFX
      )

      $PFX | ForEach {$i = 0} {
        $_ | Select-Object -property @{l='Index';e={$i}},Subject,Issuer,Thumbprint
        $i++
      } | Format-Table -AutoSize | out-host
  }


  $ExistingPFX = [Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
  $KeyStorageFlags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
  $ExistingPFX.Import($Path, $Passphrase, $KeyStorageFlags)
  

  #$ExistingPFX | ForEach {$i = 0} {
  #  $_ | Select-Object -property @{l='Index';e={$i}},Subject,Issuer,Thumbprint
  #  $i++
  #} | Format-Table -AutoSize | out-host

  Out-PFX -PFX $ExistingPFX

  $CorrectOrder = "n"

  While ($CorrectOrder -eq "n") {

    $CorrectOrder = $(Read-Host "Are the certificates in the correct order (0 = Root, 1 = Intermediate, 2 = Server)? [Y/N]").ToLower()

    If ($CorrectOrder -eq "n") {

      $NewPFX = [Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
      $RootIndex = Read-Host "Enter the index number of the root cert"
      $NewPFX.Add($ExistingPFX[$RootIndex]) | out-null
      $IntermediateIndex = Read-Host "Enter the index number of the intermediate cert"
      $NewPFX.Add($ExistingPFX[$IntermediateIndex]) | out-null
      $ServerIndex = Read-Host "Enter the index number of the server cert"
      $NewPFX.Add($ExistingPFX[$ServerIndex]) | out-null

      Out-PFX -PFX $NewPFX
    }
  }

  If ($NewPFX -And $CorrectOrder -eq "y") {
    "`nSaving reordered PFX to $NewPath"
    Set-Content -Path $NewPath -Value $NewPFX.Export("pfx", $Passphrase) -Encoding byte
  }

}

