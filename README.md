A collection of PowerShell cmdlets which are useful mostly to me and maybe Sam.

# Installation
## Git clone (preferred method)
1. Create an empty directory called "Justus-Module" in ~\Documents\WindowsPowerShell\modules (create the path if it doesn't exist).
2. Run the following command (requires git): `git clone https://github.com/justusthane/Justus-Module.git ~\Documents\WindowsPowerShell\modules\Justus-Module`

### Updating
If you've installed using the above method, you can update the module by running `git pull` within the Justus-Module directory.

## Manual Installation
1. Download this repo as a ZIP file, and extract the script files to ~\Documents\WindowsPowerShell\modules\Justus-Module

# Included cmdlets

**Run `get-help <cmdlet>` for more documentation about a specific cmdlet**. All cmdlets also provide examples with `get-help <cmdlet> -examples`.

### Test-Speed
Runs a series of internet speed tests with specified interval/start/stop times, using speedtest.net's command-line utility `speedtest.exe`.

### Get-IPInfo
Returns info for given IP address, including registration and ASN info.

### New-Array
A cute little helper cmdlet that takes the pain out of generating new arrays on the fly.

### Select-Unique
Given an input object, returns only unique combinations of the specified properties.

### Write-VMRDPConnection
Generates RDP connections and a spreadsheet for all Windows VMs in specific (or all) resource pools. Useful for making Windows Server updates easier.

### Remove-BarracudaEmail
Takes a CSV of delivered emails from Barracuda and removes them from Exchange mailboxes. Works both on-prem and on O365, but has to be run separately in each premise.

### Find-ADUser
A wrapper around Get-ADUser that searches multiple attributes (name, display name, email addresses, etc) all at once for the given search string.

Also displays whether a user's mailbox is on-prem or Office365.

### Find-AzureADDevice
Searches AD for a computer or computers (if passed an array of search strings), and returns the corresponding Azure AD devices.

### Get-MigrationBatchStatus
Returns the status of all mailboxes in a given migration batch, including whether there are any errors or skipped items.

### Get-SkippedItem
Returns all skipped items for all mailboxes in a given migration batch.

### Start-ADSync 
Initiates an Azure AD sync on the target server (target server must be running the AD Sync application).

```
powershell Start-ADSync -ComputerName ad-connect 
```

### Out-VisiData 
Allows cmdlet output to be piped to VisiData on Windows
(requires [VisiData](https://www.visidata.org) to be installed---see **Get-Help Out-VisiData** for more info).

### Set-PFXCertOrder
When exporting a complete certificate chain to a .pfx file (PKCS12), Windows has an annoying habit of not saving them in the correct order (Root -> Intermediate -> Server). This cmdlet makes it easy to reorder an existing .pfx.


## Coming Soon
...?
