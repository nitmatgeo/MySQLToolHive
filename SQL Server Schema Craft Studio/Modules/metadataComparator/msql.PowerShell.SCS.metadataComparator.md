# Utility Module: `msql.PowerShell.SCS.metadataComparator`

This module provides functionality for comparing metadata in the SQL Server Schema Craft Studio project. It includes functions for loading JSON data, comparing datasets, and exporting error logs. The module is designed to work seamlessly with other utility modules like `msql.PowerShell.SCS.Utils`.

---

## Generating the Module Manifest

The module manifest (`.psd1`) is a metadata file that describes the module and its contents. It is used to define the module's name, version, author, description, and exported functions.

To generate the module manifest for this module, use the following command:

```powershell
New-ModuleManifest -Path "C:\Users\GeorgeN\OneDrive - MHRA\02 RC DB\Scripts\SQL Server Schema Craft Studio\Modules\metadataComparator\msql.PowerShell.SCS.metadataComparator.psd1" `
                   -RootModule "msql.PowerShell.SCS.metadataComparator.psm1" `
                   -Author "NitMatGeo" `
                   -Description "Functions for comparing metadata in SQL Server Schema Craft Studio" `
                   -ModuleVersion "1.0.0"
```

---

## Refreshing the Module

After making changes to the module (e.g., updating the `.psm1` file or the manifest), refresh the module in your current PowerShell session. Use the following script to remove and re-import the module:

```powershell
# Refresh the module
$moduleName = "msql.PowerShell.SCS.metadataComparator"
$modulePath = "C:\Users\GeorgeN\OneDrive - MHRA\02 RC DB\Scripts\SQL Server Schema Craft Studio\Modules\metadataComparator"

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

### 1. `Load-JsonData`
- **Description**: Loads JSON data from a specified folder, excluding a specific raw file, and processes the data into a hashtable.
- **Parameters**:
  - `folderPath`: Path to the folder containing JSON files.
  - `rawFileNameToIgnore`: Name of the raw file to exclude from processing.
  - `debugMode`: Enable or disable debugging output.
  - `logFilePath`: Path to the log file for logging messages.
- **Usage**:
  ```powershell
  $data = Load-JsonData -folderPath "C:\Path\To\Folder" -rawFileNameToIgnore "00.rawDumpOutput.json" -debugMode $true -logFilePath "C:\Path\To\LogFile.log"
  ```

---

### 2. `Compare-Data`
- **Description**: Compares two datasets (version `n` and version `n-1`) and generates a comparison result.
- **Parameters**:
  - `dataN`: Hashtable containing data for version `n`.
  - `dataNMinus1`: Hashtable containing data for version `n-1`.
  - `debugMode`: Enable or disable debugging output.
  - `logFilePath`: Path to the log file for logging messages.
- **Usage**:
  ```powershell
  $comparisonResults = Compare-Data -dataN $dataN -dataNMinus1 $dataNMinus1 -debugMode $true -logFilePath "C:\Path\To\LogFile.log"
  ```

---

### 3. `Export-ErrorLog`
- **Description**: Exports error messages to a specified log file.
- **Parameters**:
  - `errors`: Array of error messages to export.
  - `logFilePath`: Path to the log file where errors will be saved.
- **Usage**:
  ```powershell
  Export-ErrorLog -errors $global:errors -logFilePath "C:\Path\To\ErrorLog.log"
  ```

---

## Example Workflow

Here’s an example workflow that uses the `msql.PowerShell.SCS.metadataComparator` module:

```powershell
# Import the required modules
Import-Module "C:\Path\To\msql.PowerShell.SCS.Utils.psm1" -Force
Import-Module "C:\Path\To\msql.PowerShell.SCS.metadataComparator.psm1" -Force

# Enable debug mode
$debugMode = $true

# Define paths
$rootPath = "C:\Path\To\Root"
$versionN = "version (n)"
$versionNMinus1 = "version (n-1)"
$rawFileName = "00.rawDumpOutput.json"
$logFilePath = "C:\Path\To\ComparisonLog.csv"

# Initialize global errors array
$global:errors = @()

try {
    # Load JSON data for both versions
    $dataN = Load-JsonData -folderPath (Join-Path -Path $rootPath -ChildPath $versionN) -rawFileNameToIgnore $rawFileName -debugMode $debugMode -logFilePath $logFilePath
    $dataNMinus1 = Load-JsonData -folderPath (Join-Path -Path $rootPath -ChildPath $versionNMinus1) -rawFileNameToIgnore $rawFileName -debugMode $debugMode -logFilePath $logFilePath

    # Compare the data
    $comparisonResults = Compare-Data -dataN $dataN -dataNMinus1 $dataNMinus1 -debugMode $debugMode -logFilePath $logFilePath

    # Export the comparison results
    $comparisonResults | Export-Csv -Path $logFilePath -NoTypeInformation
    Write-Host "Comparison results exported successfully to $logFilePath." -ForegroundColor Green
}
catch {
    Log-Message -message "Critical error during execution: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
}

# Export errors if any
if ($global:errors.Count -gt 0) {
    $errorLogFile = Join-Path -Path (Split-Path -Path $logFilePath -Parent) -ChildPath "ErrorLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    Export-ErrorLog -errors $global:errors -logFilePath $errorLogFile
    Write-Host "Errors logged to $errorLogFile." -ForegroundColor Yellow
}
```

---

## Dependencies

This module depends on the following:
1. **`msql.PowerShell.SCS.Utils`**:
   - Provides centralized logging functionality through the `Log-Message` function.
   - Handles module checks using the `Check-Modules` function.

---

## Version History

- **1.0.0**:
  - Initial release with `Load-JsonData`, `Compare-Data`, and `Export-ErrorLog` functions.

---

## Author

- **Author**: NitMatGeo
- **Description**: Functions for comparing metadata in SQL Server Schema Craft Studio.