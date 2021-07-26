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

**Run `get-help <cmdlet>` for more documentation about a specific cmdlet**

### Build-VMRDPConnections
Generates RDP connections and a spreadsheet for all Windows VMs in specific (or all) resource pools. Useful for making Windows Server updates easier.

### Get-IPInfo
Returns info from ipinfo.io for given IP address (or your own IP address, with no arguments)

### Remove-Emails
Takes a CSV of delivered emails from Barracuda and removes them from Exchange mailboxes. Works both on-prem and on O365, but has to be run separately in each premise.

### Find-ADUser
A wrapper around Get-ADUser that searches multiple attributes (name, display name, email addresses, etc) all at once for the given search string.

### Get-MigrationBatchStatus
Returns the status of all mailboxes in a given migration batch, including whether there are any errors or skipped items.

### Get-SkippedItems
Returns all skipped items for all mailboxes in a given migration batch.
