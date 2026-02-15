# setup_alias.ps1

# Set the target path
$targetPath = "c:\src\Antigravity\BeanBase2.0"

# Check if profile exists, create if not
if (-not (Test-Path $PROFILE)) {
    New-Item -Type File -Path $PROFILE -Force
    Write-Host "Created PowerShell profile at $PROFILE"
}

# Read current profile content
$currentContent = Get-Content $PROFILE -ErrorAction SilentlyContinue

# Define the function
$functionDef = "function beanbase { Set-Location '$targetPath' }"

# Check if already exists
if ($currentContent -match "function beanbase") {
    Write-Host "Alias 'beanbase' already exists in your profile."
} else {
    Add-Content -Path $PROFILE -Value "`n$functionDef"
    Write-Host "Success: Added 'beanbase' alias to your profile."
    Write-Host "Use 'beanbase' command to jump to the project directory."
    Write-Host "PLEASE RESTART YOUR TERMINAL (or run '. `$PROFILE') TO ACTIVATE."
}
