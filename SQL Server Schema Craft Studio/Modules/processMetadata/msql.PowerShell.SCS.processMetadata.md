# Utility Module: `msql.PowerShell.SCS.processMetadata`

This module provides functionality for processing metadata in the SQL Server Schema Craft Studio project. It includes functions for extracting valid JSON content, processing JSON files, and handling metadata transformations. The module is designed to work seamlessly with other utility modules like `msql.PowerShell.SCS.Utils`.

---

## Generating the Module Manifest

The module manifest (`.psd1`) is a metadata file that describes the module and its contents. It is used to define the module's name, version, author, description, and exported functions.

To generate the module manifest for this module, use the following command:

```powershell
New-ModuleManifest -Path "C:\Users\GeorgeN\OneDrive - MHRA\02 RC DB\Scripts\SQL Server Schema Craft Studio\Modules\processMetadata\msql.PowerShell.SCS.processMetadata.psd1" `
                   -RootModule "msql.PowerShell.SCS.processMetadata.psm1" `
                   -Author "NitMatGeo" `
                   -Description "Functions for processing metadata in SQL Server Schema Craft Studio" `
                   -ModuleVersion "1.0.0"
```

---

## Refreshing the Module

After making changes to the module (e.g., updating the `.psm1` file or the manifest), refresh the module in your current PowerShell session. Use the following script to remove and re-import the module:

```powershell
# Refresh the module
$moduleName = "msql.PowerShell.SCS.processMetadata"
$modulePath = "C:\Users\GeorgeN\OneDrive - MHRA\02 RC DB\Scripts\SQL Server Schema Craft Studio\Modules\processMetadata"

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

### 1. `Extract-ValidJsonContent`
- **Description**: Extracts valid JSON content from a raw file by identifying start and end patterns and fixing improperly joined JSON objects.
- **Parameters**:
  - `rawFilePath`: Path to the raw JSON file.
  - `debugMode`: Enable or disable debugging output.
- **Usage**:
  ```powershell
  $validJsonContent = Extract-ValidJsonContent -rawFilePath "C:\Path\To\RawFile.json" -debugMode $true
  ```

### 2. `Process-JSON`
- **Description**: Processes JSON content by splitting it into individual objects and saving them as separate files in the output folder.
- **Parameters**:
  - `inputFile`: Path to the input JSON file.
  - `outputFolder`: Path to the output folder where processed files will be saved.
  - `debugMode`: Enable or disable debugging output.
- **Usage**:
  ```powershell
  Process-JSON -inputFile "C:\Path\To\InputFile.json" -outputFolder "C:\Path\To\OutputFolder" -debugMode $true
  ```

---

## Dependencies

This module depends on the following:
1. **`msql.PowerShell.SCS.Utils`**:
   - Provides centralized logging functionality through the `Log-Message` function.
   - Handles module checks using the `Check-Modules` function.
2. **`Newtonsoft.Json`**:
   - Used for JSON serialization and deserialization.

Ensure these dependencies are installed and available in your environment.

---

## Example Workflow

Here’s an example workflow that uses the `msql.PowerShell.SCS.processMetadata` module:

```powershell
# Import the required modules
Import-Module "C:\Path\To\msql.PowerShell.SCS.Utils.psm1" -Force
Import-Module "C:\Path\To\msql.PowerShell.SCS.processMetadata.psm1" -Force

# Enable debug mode
$debugMode = $true

# Define paths
$rootPath = "C:\Path\To\Root"
$rawFileName = "00.rawDumpOutput.json"

# Initialize and process metadata
try {
    # Extract valid JSON content
    $rawFilePath = Join-Path -Path $rootPath -ChildPath $rawFileName
    $validJsonContent = Extract-ValidJsonContent -rawFilePath $rawFilePath -debugMode $debugMode

    # Process the JSON content
    $outputFolder = Join-Path -Path $rootPath -ChildPath "ProcessedOutput"
    Process-JSON -inputFile $rawFilePath -outputFolder $outputFolder -debugMode $debugMode

    Write-Host "Metadata processing completed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error during metadata processing: $($_.Exception.Message)" -ForegroundColor Red
}
```

---

## Testing the Module

To test the module, create a test script (e.g., `Test-ProcessMetadata.ps1`) with the following content:

```powershell
# Import the module
Import-Module "C:\Path\To\msql.PowerShell.SCS.processMetadata.psm1" -Force

# Test Extract-ValidJsonContent
try {
    $validJsonContent = Extract-ValidJsonContent -rawFilePath "C:\Path\To\RawFile.json" -debugMode $true
    Write-Host "Extract-ValidJsonContent test passed." -ForegroundColor Green
} catch {
    Write-Host "Extract-ValidJsonContent test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Process-JSON
try {
    Process-JSON -inputFile "C:\Path\To\InputFile.json" -outputFolder "C:\Path\To\OutputFolder" -debugMode $true
    Write-Host "Process-JSON test passed." -ForegroundColor Green
} catch {
    Write-Host "Process-JSON test failed: $($_.Exception.Message)" -ForegroundColor Red
}
```

---

## Version History

- **1.0.0**:
  - Initial release with `Extract-ValidJsonContent` and `Process-JSON` functions.

---

## Author

- **Author**: NitMatGeo
- **Description**: Functions for processing metadata in SQL Server Schema Craft Studio.