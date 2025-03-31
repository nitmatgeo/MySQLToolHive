# Utility Module: `msql.PowerShell.SCS.Utils`

This module provides utility functions for the SQL Server Schema Craft Studio project. It includes centralized logging functionality and can be extended with additional utilities as needed.

---

## Generating the Module Manifest

The module manifest (`.psd1`) is a metadata file that describes the module and its contents. It is used to define the module's name, version, author, description, and exported functions.

To generate the module manifest for this module, use the following command:

```powershell
New-ModuleManifest -Path "C:\Users\GeorgeN\OneDrive - MHRA\02 RC DB\Scripts\SQL Server Schema Craft Studio\Modules\msql.PowerShell.SCS.Utils\msql.PowerShell.SCS.Utils.psd1" `
                   -RootModule "Utils.psm1" `
                   -Author "NitMatGeo" `
                   -Description "Utility functions for SQL Server Schema Craft Studio" `
                   -ModuleVersion "1.0.0"
```

## Refreshing the Module
After making changes to the module (e.g., update the .psm1 file or the manifest), refresh the module in your current PowerShell session. Use the following script to remove and re-import the module:

```powershell
# Refresh the module
$moduleName = "msql.PowerShell.SCS.Utils"
$modulePath = "C:\Users\GeorgeN\OneDrive - MHRA\02 RC DB\Scripts\SQL Server Schema Craft Studio\Modules\Utils"

# Remove the module if it is already loaded

if (Get-Module -Name $moduleName) {
    Remove-Module -Name $moduleName -Force
}

# Re-import the module
Import-Module -Name "$modulePath\$moduleName.psm1" -Force

# Verify the module is loaded
Get-Module -Name $moduleName
```
