# Function: Log Messages
function Log-Message {
    param (
        [string]$message, # The message to log
        [ValidateSet("Error", "Warning", "Information", "Debug")]
        [string]$level = "Information", # The log level (default: Information)
        [string]$logFilePath = $null, # Optional: Path to a log file
        [bool]$debugMode = $false    # Whether to display debug messages
    )

    # Get the current timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Format the log message
    $logEntry = "$timestamp [$level] - $message"

    # Write to console based on log level
    switch ($level) {
        "ERROR" {
            # Use Write-Error for errors
            Write-Error -Message $logEntry
        }
        "WARNING" {
            # Use Write-Warning for warnings
            Write-Warning -Message $logEntry
        }
        "INFORMATION" {
            # Use Write-Host for informational messages
            Write-Host $logEntry -ForegroundColor Green
        }
        "DEBUG" {
            # Use Write-Host for debug messages (only if debugMode is enabled)
            if ($debugMode) {
                Write-Host $logEntry -ForegroundColor Cyan
            }
        }
    }

    # Write to log file if a path is provided
    if ($logFilePath) {
        try {
            # Log all levels except Debug when debugMode is false
            if ($debugMode -or $level -ne "Debug") {
                Add-Content -Path $logFilePath -Value $logEntry
            }
        }
        catch {
            Write-Error "EXCEPTION: Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }
}

# Export the Log-Message function
Export-ModuleMember -Function Log-Message

# Function: Initialize-Folder
function Initialize-Folder {
    param (
        [string]$rootPath, # Root path for the JSON files
        [string]$version, # Version folder (e.g., "version (n-1)")
        [string]$rawFileName = $null, # Raw partial-JSON file name (e.g., "00.rawSchemaMetadataOutput.dat")
        [string]$logFilePath = $null, # Optional: Path to a log file
        [bool]$debugMode               # Enable or disable debugging output
    )

    # Generate a 5-character hex string based on the raw file name
    if ($null -ne $rawFileName -and $rawFileName -ne "") {
        $hashTempFolder = [System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($rawFileName))).Replace("-", "").Substring(0, 5)
    }

    # Define the input JSON file and output folder based on the parameters
    $inputFile = Join-Path -Path $rootPath -ChildPath "$version\$rawFileName"
    $rootFolder = Join-Path -Path $rootPath -ChildPath "$version"
    $outputFolder = Join-Path -Path $rootPath -ChildPath "$version\$hashTempFolder"

    # Log debugging information
    Log-Message -message "Initializing script for version: $version" -level "Information" -debugMode $debugMode -logFilePath $logFilePath
    Log-Message -message "Input File: $inputFile" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
    Log-Message -message "Output Folder: $outputFolder" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath

    # Ensure the output folder exists or is cleaned up except for the input file
    try {
        if (Test-Path -Path $outputFolder) {
            Log-Message -message "Output folder exists. Cleaning up JSON files except for the input file..." -level "Information" -debugMode $debugMode -logFilePath $logFilePath

            # Get all JSON files in the output folder except the input file
            Get-ChildItem -Path $outputFolder -Filter "*.json" -File | Where-Object { $_.FullName -ne $inputFile } | ForEach-Object {
                Log-Message -message "Removing file: $($_.FullName)" -level "Debug" -debugMode $debugMode -logFilePath $logFilePath
                Remove-Item -Path $_.FullName -Force
            }
        }
        else {
            Log-Message -message "Output folder does not exist. Creating folder: $outputFolder" -level "Information" -debugMode $debugMode -logFilePath $logFilePath
            # Create the folder if it doesn't exist
            New-Item -ItemType Directory -Path $outputFolder | Out-Null
        }
    }
    catch {
        # Log the error and rethrow it to ensure it doesn't go unnoticed
        Log-Message -message "Error during initialization: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw
    }

    # Return the paths as a hashtable
    return @{
        InputFile    = $inputFile
        OutputFolder = $outputFolder
        RootFolder   = $rootFolder
    }
}

# Function: Check-Modules
function Check-Modules {
    param (
        [string]$logFilePath = $null, # Optional: Path to a log file    
        [bool]$debugMode = $false # Enable or disable debug logging
    )

    # Check if the NuGet provider is installed
    try {
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Log-Message -message "NuGet provider not found. Attempting to install..." -level "Warning" -debugMode $debugMode -logFilePath $logFilePath
            Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction Stop
            Log-Message -message "NuGet provider installed successfully." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
        }
        else {
            Log-Message -message "NuGet provider is already installed." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
        }
    }
    catch {
        Log-Message -message "Failed to install NuGet provider: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw
    }

    # Check if the Newtonsoft.Json module is installed
    try {
        if (-not (Get-Module -Name Newtonsoft.Json -ListAvailable)) {
            Log-Message -message "Newtonsoft.Json module is not installed. Please refer to the README.md for installation instructions." -level "Error" -logFilePath $logFilePath
            throw "Newtonsoft.Json module is required but not installed."
        }
        else {
            Log-Message -message "Newtonsoft.Json module is available." -level "Information" -debugMode $debugMode -logFilePath $logFilePath
        }
    }
    catch {
        Log-Message -message "Error while checking for Newtonsoft.Json module: $($_.Exception.Message)" -level "Error" -logFilePath $logFilePath
        throw
    }
}

# Export the functions
Export-ModuleMember -Function Initialize-Folder, Check-Modules