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

# Verify the module is loaded
if (-not (Get-Module -Name "msql.PowerShell.SCS.Utils")) {
    Write-Host "Module not loaded. Please check the module path or manifest file." -ForegroundColor Red
    exit 1
}
Write-Host "Module successfully loaded." -ForegroundColor Green

# Initialize test results
$testResults = @()

# Test variables
$logFilePath = "$modulePath\TestLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Helper function to track test results
function Add-TestResult {
    param (
        [string]$testName,
        [bool]$passed,
        [string]$message = ""
    )
    $testResults += [pscustomobject]@{
        TestName = $testName
        Passed   = $passed
        Message  = $message
    }
}

# Test 1: Log an error
Write-Host "Test 1: Logging an error..." -ForegroundColor Cyan
try {
    Log-Message -message "This is a test error message." -level "Error" -logFilePath $logFilePath
    Add-TestResult -testName "Log Error" -passed $true
} catch {
    Add-TestResult -testName "Log Error" -passed $false -message $_.Exception.Message
}

# Test 2: Log a warning
Write-Host "Test 2: Logging a warning..." -ForegroundColor Cyan
try {
    Log-Message -message "This is a test warning message." -level "Warning" -logFilePath $logFilePath
    Add-TestResult -testName "Log Warning" -passed $true
} catch {
    Add-TestResult -testName "Log Warning" -passed $false -message $_.Exception.Message
}

# Test 3: Log information
Write-Host "Test 3: Logging information..." -ForegroundColor Cyan
try {
    Log-Message -message "This is a test informational message." -level "Information" -logFilePath $logFilePath
    Add-TestResult -testName "Log Information" -passed $true
} catch {
    Add-TestResult -testName "Log Information" -passed $false -message $_.Exception.Message
}

# Test 4: Log a debug message (debug mode disabled)
Write-Host "Test 4: Logging a debug message (debug mode disabled)..." -ForegroundColor Cyan
try {
    Log-Message -message "This is a test debug message." -level "Debug" -debugMode $false -logFilePath $logFilePath
    Add-TestResult -testName "Log Debug (Disabled)" -passed $true
} catch {
    Add-TestResult -testName "Log Debug (Disabled)" -passed $false -message $_.Exception.Message
}

# Test 5: Log a debug message (debug mode enabled)
Write-Host "Test 5: Logging a debug message (debug mode enabled)..." -ForegroundColor Cyan
try {
    Log-Message -message "This is a test debug message." -level "Debug" -debugMode $true -logFilePath $logFilePath
    Add-TestResult -testName "Log Debug (Enabled)" -passed $true
} catch {
    Add-TestResult -testName "Log Debug (Enabled)" -passed $false -message $_.Exception.Message
}

# Test 6: Log without a file path
Write-Host "Test 6: Logging without a file path..." -ForegroundColor Cyan
try {
    Log-Message -message "This is a test message without a log file." -level "Information"
    Add-TestResult -testName "Log Without File Path" -passed $true
} catch {
    Add-TestResult -testName "Log Without File Path" -passed $false -message $_.Exception.Message
}

# Test 7: Invalid log level
Write-Host "Test 7: Logging with an invalid log level (should fail)..." -ForegroundColor Cyan
try {
    Log-Message -message "This is a test message with an invalid log level." -level "Invalid"
    Add-TestResult -testName "Invalid Log Level" -passed $false -message "Expected failure, but succeeded."
} catch {
    Add-TestResult -testName "Invalid Log Level" -passed $true -message "Caught expected error: $($_.Exception.Message)"
}

# Test 8: Verify log file content
Write-Host "Test 8: Verifying log file content..." -ForegroundColor Cyan
try {
    if (Test-Path -Path $logFilePath) {
        $logContent = Get-Content -Path $logFilePath
        if ($logContent -match "This is a test error message") {
            Add-TestResult -testName "Verify Log File Content" -passed $true
        } else {
            Add-TestResult -testName "Verify Log File Content" -passed $false -message "Log file content does not match expected output."
        }
    } else {
        Add-TestResult -testName "Verify Log File Content" -passed $false -message "Log file not found."
    }
} catch {
    Add-TestResult -testName "Verify Log File Content" -passed $false -message $_.Exception.Message
}

# Display test results
Write-Host "`nTest Results:" -ForegroundColor Cyan
$testResults | Format-Table -AutoSize

# Exit with appropriate status
if ($testResults.Passed -contains $false) {
    Write-Host "`nSome tests failed. Please review the results above." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll tests passed successfully!" -ForegroundColor Green
    exit 0
}

# Remove the module if it is already loaded
if (Get-Module -Name $moduleName) {
    Remove-Module -Name $moduleName -Force
}