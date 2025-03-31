# Utility Module: `msql.PowerShell.SCS.comparatorSummary`

This module provides functionality for generating summaries from comparison logs in the SQL Server Schema Craft Studio project. It includes functions for creating high-level summaries and detailed summaries of comparison results. The module is designed to work seamlessly with other utility modules like `msql.PowerShell.SCS.Utils` and `msql.PowerShell.SCS.metadataComparator`.

---

## Generating the Module Manifest

The module manifest (`.psd1`) is a metadata file that describes the module and its contents. It is used to define the module's name, version, author, description, and exported functions.

To generate the module manifest for this module, use the following command:

```powershell
New-ModuleManifest -Path "C:\Users\GeorgeN\OneDrive - MHRA\02 RC DB\Scripts\SQL Server Schema Craft Studio\Modules\comparatorSummary\msql.PowerShell.SCS.comparatorSummary.psd1" `
                   -RootModule "msql.PowerShell.SCS.comparatorSummary.psm1" `
                   -Author "NitMatGeo" `
                   -Description "Functions for generating summaries from comparison logs in SQL Server Schema Craft Studio" `
                   -ModuleVersion "1.0.0"
```

---

## Refreshing the Module

After making changes to the module (e.g., updating the `.psm1` file or the manifest), refresh the module in your current PowerShell session. Use the following script to remove and re-import the module:

```powershell
# Refresh the module
$moduleName = "msql.PowerShell.SCS.comparatorSummary"
$modulePath = "C:\Users\GeorgeN\OneDrive - MHRA\02 RC DB\Scripts\SQL Server Schema Craft Studio\Modules\comparatorSummary"

# Remove the module if it is already loaded
if (Get-Module -Name $moduleName) {
    Remove-Module -Name $moduleName -Force
}

# Re-import the module
Import-Module -Name "$modulePath\$moduleName.psm1" -Force

# Verify the module is loaded
Get-Module -Name $moduleName
```

---

## Functions in the Module

### 1. `Generate-Summary`
- **Description**: Generates a high-level summary of the comparison results, including counts of added, deleted, changed, and unchanged items.
- **Parameters**:
  - `comparisonLogFilePath`: Path to the comparison log file.
  - `summaryOutputPath`: Path to save the summary file.
  - `debugMode`: Enable or disable debugging output.
  - `logFilePath`: Path to the log file for logging messages.
- **Usage**:
  ```powershell
  Generate-Summary -comparisonLogFilePath "C:\Path\To\ComparisonLog.csv" -summaryOutputPath "C:\Path\To\Summaries" -debugMode $true -logFilePath "C:\Path\To\LogFile.log"
  ```

---

### 2. `Generate-DetailedSummary`
- **Description**: Generates a detailed summary of the comparison results, including additional remarks and hash values for each item.
- **Parameters**:
  - `comparisonLogFilePath`: Path to the comparison log file.
  - `detailedOutputPath`: Path to save the detailed summary file.
  - `debugMode`: Enable or disable debugging output.
  - `logFilePath`: Path to the log file for logging messages.
- **Usage**:
  ```powershell
  Generate-DetailedSummary -comparisonLogFilePath "C:\Path\To\ComparisonLog.csv" -detailedOutputPath "C:\Path\To\DetailedSummaries" -debugMode $true -logFilePath "C:\Path\To\LogFile.log"
  ```

---

## Example Workflow

Here’s an example workflow that uses the `msql.PowerShell.SCS.comparatorSummary` module:

```powershell
# Import the required modules
Import-Module "C:\Path\To\msql.PowerShell.SCS.Utils.psm1" -Force
Import-Module "C:\Path\To\msql.PowerShell.SCS.metadataComparator.psm1" -Force
Import-Module "C:\Path\To\msql.PowerShell.SCS.comparatorSummary.psm1" -Force

# Enable debug mode
$debugMode = $true

# Define paths
$comparisonLogFilePath = "C:\Path\To\ComparisonLog.csv"
$summaryOutputPath = "C:\Path\To\Summaries"
$detailedOutputPath = "C:\Path\To\DetailedSummaries"
$logFilePath = "C:\Path\To\LogFile.log"

try {
    # Generate a high-level summary
    Generate-Summary -comparisonLogFilePath $comparisonLogFilePath -summaryOutputPath $summaryOutputPath -debugMode $debugMode -logFilePath $logFilePath

    # Generate a detailed summary
    Generate-DetailedSummary -comparisonLogFilePath $comparisonLogFilePath -detailedOutputPath $detailedOutputPath -debugMode $debugMode -logFilePath $logFilePath
}
catch {
    Write-Host "Error during summary generation: $($_.Exception.Message)" -ForegroundColor Red
}
```

---

## Dependencies

This module depends on the following:
1. **`msql.PowerShell.SCS.Utils`**:
   - Provides centralized logging functionality through the `Log-Message` function.
   - Handles module checks using the `Check-Modules` function.
2. **`msql.PowerShell.SCS.metadataComparator`**:
   - Provides functionality for generating comparison logs, which are used as input for this module.

---

## Version History

- **1.0.0**:
  - Initial release with `Generate-Summary` and `Generate-DetailedSummary` functions.

---

## Author

- **Author**: NitMatGeo
- **Description**: Functions for generating summaries from comparison logs in SQL Server Schema Craft Studio.