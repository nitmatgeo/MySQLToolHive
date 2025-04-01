# Enable or disable debug mode
$debugMode = $true

# Define root path and raw file name
$rootPath = "C:\Users\nitin.mathew.george\Downloads\MySQLToolHive\SQL Server Schema Craft Studio"
$rawFileName = "00.rawSchemaMetadataOutput.dat"
$rawFileStartPattern = '{"schema_name":'
$rawFileEndPattern = '\}\]\}$'
$logFilePath = "$rootPath\Data\Logs\TestLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Capture the start time
$executionStartTime = Get-Date

# Import the Utils module
Import-Module "$rootPath\Modules\Utils\msql.PowerShell.SCS.Utils.psd1" -Force
Import-Module "$rootPath\Modules\processMetadata\msql.PowerShell.SCS.processMetadata.psm1" -Force
Import-Module "$rootPath\Modules\metadataComparator\msql.PowerShell.SCS.metadataComparator.psm1" -Force
Import-Module "$rootPath\Modules\comparatorSummary\msql.PowerShell.SCS.comparatorSummary.psm1" -Force

# Main Execution Block
try {
    # Log the start of script execution
    Log-Message -message "Starting script execution..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath

    # Check required modules
    Check-Modules -debugMode $debugMode
    
    # Initialize and process Schema Metadata JSON for "version (n-1)"
    Log-Message -message "Processing Schema Metadata JSON for version (n-1)..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    $resultNMinus1 = Initialize-Folder -rootPath "$rootPath\Data\Inputs" -version "version (n-1)" -rawFileName $rawFileName -debugMode $debugMode -logFilePath $logFilePath
    $validJsonContentNMinus1 = Extract-ValidJsonContent -rawFilePath $resultNMinus1.InputFile -startPattern $rawFileStartPattern -endPattern $rawFileEndPattern -debugMode $debugMode -logFilePath $logFilePath
    Process-JSON -jsonRawContent $validJsonContentNMinus1 -outputFolder $resultNMinus1.OutputFolder -debugMode $debugMode -logFilePath $logFilePath

    # Initialize and process Schema Metadata JSON for "version (n)"
    Log-Message -message "Processing Schema Metadata JSON for version (n)..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    $resultN = Initialize-Folder -rootPath "$rootPath\Data\Inputs" -version "version (n)" -rawFileName $rawFileName -debugMode $debugMode -logFilePath $logFilePath
    $validJsonContentN = Extract-ValidJsonContent -rawFilePath $resultN.InputFile -startPattern $rawFileStartPattern -endPattern $rawFileEndPattern -debugMode $debugMode -logFilePath $logFilePath
    Process-JSON -jsonRawContent $validJsonContentN -outputFolder $resultN.OutputFolder -debugMode $debugMode -logFilePath $logFilePath

    Log-Message -message "Processing Hierarchy Metadata JSON for version (n-1)..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    $hierarchyNMinus1 = Initialize-Folder -rootPath "$rootPath\Data\Inputs" -version "version (n-1)" -rawFileName "00.rawHierarchyOutput.dat" -debugMode $debugMode -logFilePath $logFilePath
    $validJsonhierarchyContentNMinus1 = Extract-ValidJsonContent -rawFilePath $hierarchyNMinus1.InputFile -startPattern '{"FullTableName":' -endPattern '}' -debugMode $debugMode -logFilePath $logFilePath
    Process-JSON -jsonRawContent $validJsonhierarchyContentNMinus1 -outputFolder $hierarchyNMinus1.OutputFolder -debugMode $debugMode -logFilePath $logFilePath

    Log-Message -message "Processing Hierarchy Metadata JSON for version (n)..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    $hierarchyN = Initialize-Folder -rootPath "$rootPath\Data\Inputs" -version "version (n)" -rawFileName "00.rawHierarchyOutput.dat" -debugMode $debugMode -logFilePath $logFilePath
    $validJsonhierarchyContentN = Extract-ValidJsonContent -rawFilePath $hierarchyN.InputFile -startPattern '{"FullTableName":' -endPattern '}' -debugMode $debugMode -logFilePath $logFilePath
    Process-JSON -jsonRawContent $validJsonhierarchyContentN -outputFolder $hierarchyN.OutputFolder -debugMode $debugMode -logFilePath $logFilePath
    
    # Initialize and merge Metadata JSONs (Schema & Hierarchy) for "version (n-1)"
    Log-Message -message "Merging Schema Metadata JSONs for version (n-1)..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    $resultMergeNMinus1 = Initialize-Folder -rootPath "$rootPath\Data\Inputs" -version "version (n-1)" -debugMode $debugMode -logFilePath $logFilePath
    Merge-JsonFiles -folderPathA $resultNMinus1.OutputFolder `
        -folderPathB $hierarchyNMinus1.OutputFolder `
        -outputFolder $resultNMinus1.RootFolder `
        -debugMode $debugMode `
        -logFilePath $logFilePath
    
    # Initialize and merge Metadata JSONs (Schema & Hierarchy) for "version (n)"
    Log-Message -message "Merging Schema Metadata JSONs for version (n)..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    $resultMergeN = Initialize-Folder -rootPath "$rootPath\Data\Inputs" -version "version (n)" -debugMode $debugMode -logFilePath $logFilePath
    Merge-JsonFiles -folderPathA $resultN.OutputFolder `
        -folderPathB $hierarchyN.OutputFolder `
        -outputFolder $resultN.RootFolder `
        -debugMode $debugMode `
        -logFilePath $logFilePath

    # Invoke the comparator
    Log-Message -message "Invoking the comparator to compare version (n) and version (n-1)..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    $comparisonLogFile = Join-Path -Path "$rootPath\Data\Outputs" -ChildPath "ComparisonLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

    # Load JSON data for both versions
    $dataN = Load-JsonData -folderPath $resultN.OutputFolder -rawFileNameToIgnore $rawFileName -debugMode $debugMode -logFilePath $logFilePath
    $dataNMinus1 = Load-JsonData -folderPath $resultNMinus1.OutputFolder -rawFileNameToIgnore $rawFileName -debugMode $debugMode -logFilePath $logFilePath
    
    # Compare the data
    $comparisonResults = Compare-Data -dataN $dataN -dataNMinus1 $dataNMinus1 -debugMode $debugMode -logFilePath $logFilePath
    
    # Ensure the directory for the comparison log file exists
    $comparisonLogDirectory = Split-Path -Path $comparisonLogFile -Parent
    if (-not (Test-Path -Path $comparisonLogDirectory)) {
        New-Item -ItemType Directory -Path $comparisonLogDirectory -Force | Out-Null
    }

    # Export the comparison results to the CSV file
    $comparisonResults | Export-Csv -Path $comparisonLogFile -NoTypeInformation
    Log-Message -message "Comparison results exported successfully to $comparisonLogFile." -level "Information" -debugMode $debugMode -logFilePath $logFilePath

    # Invoke the summary generation
    Log-Message -message "Generating summary from comparison log..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    $summaryOutputPath = Join-Path -Path "$rootPath\Data\Outputs" -ChildPath $null
    Generate-Summary -comparisonLogFilePath $comparisonLogFile -summaryOutputPath $summaryOutputPath -debugMode $debugMode -logFilePath $logFilePath

    # Invoke the detailed summary generation
    Log-Message -message "Generating detailed summary from comparison log..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    $detailedOutputPath = Join-Path -Path "$rootPath\Data\Outputs" -ChildPath $null
    Generate-DetailedSummary -comparisonLogFilePath $comparisonLogFile -detailedOutputPath $detailedOutputPath -debugMode $debugMode -logFilePath $logFilePath

    # Log the successful completion of script execution
    Log-Message -message "Script execution completed successfully." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
}
catch {
    # Log critical errors during script execution
    Log-Message -message "Critical error during script execution: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
}
finally {
    # Capture the end time
    $executionEndTime = Get-Date
    $executionDuration = $executionEndTime - $executionStartTime

    # Format the duration in HH:MM:SS
    $formattedDuration = [string]::Format("{0:hh\:mm\:ss}", $executionDuration)

    # Log the execution time details
    Log-Message -message "Execution started at: $executionStartTime" -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    Log-Message -message "Execution ended at: $executionEndTime" -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    Log-Message -message "Total execution duration: $formattedDuration" -level "Information" -debugMode $debugMode -logFilePath $logFilePath
}