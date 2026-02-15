param (
    [string]$ApiKey
)

if ([string]::IsNullOrEmpty($ApiKey)) {
    Write-Host "Usage: .\tools\check_gemini.ps1 <API_KEY>" -ForegroundColor Red
    exit 1
}

# Sanitize
# Allow only alphanumeric, underscore, and dash. Remove everything else.
# This avoids encoding issues with smart quotes.
$ApiKey = $ApiKey -replace "[^a-zA-Z0-9_\-]", ""
Write-Host "API Key Length (Sanitized): $($ApiKey.Length)"

$baseUrl = "https://generativelanguage.googleapis.com/v1beta/models"
$outputFile = "api_check_result.txt"
"Checking API Key: $($ApiKey.Substring(0, [math]::Min(5, $ApiKey.Length)))..." | Out-File -FilePath $outputFile -Encoding utf8

# Debug: Check for invisible characters
$debugChars = [char[]]$ApiKey
$debugOutput = ""
foreach ($c in $debugChars) {
    $debugOutput += "['$c':$([int]$c)] "
}
# "Key Chars: $debugOutput" | Out-File -FilePath $outputFile -Append # Uncomment if needed for deep debug

# Check for curl.exe
$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
if (-not $curl) {
    Write-Host "curl.exe not found. Falling back to Invoke-RestMethod." -ForegroundColor Yellow
}
else {
    Write-Host "Using curl.exe found at $($curl.Source)" -ForegroundColor Green
}

# 1. List Models
Write-Host "Fetching available models..."
$listUrl = "$baseUrl?key=$ApiKey"

# Debug URL
"DEBUG: Requesting URL: $($baseUrl)?key=***" | Out-File -FilePath $outputFile -Append

$availableModels = @()

# Try List Models
try {
    $rawResponse = ""
    if ($curl) {
        $rawResponse = & curl.exe -s $listUrl
        # Log plain response (first 500 chars)
        "DEBUG: Raw List Response: $(($rawResponse -join ' ').Substring(0, [math]::Min(500, ($rawResponse -join ' ').Length)))" | Out-File -FilePath $outputFile -Append
        
        try {
            $listResponse = $rawResponse | ConvertFrom-Json
        }
        catch {
            "DEBUG: JSON Conversion Failed." | Out-File -FilePath $outputFile -Append
        }
    }
    else {
        $listResponse = Invoke-RestMethod -Uri $listUrl -Method Get -ErrorAction Stop
    }

    if ($listResponse -and $listResponse.models) {
        "----------------------------------------" | Out-File -FilePath $outputFile -Append
        "Available Models:" | Out-File -FilePath $outputFile -Append
        foreach ($m in $listResponse.models) {
            if ($m.supportedGenerationMethods -contains "generateContent") {
                $modelName = $m.name -replace "models/", ""
                " - $modelName (Supports generateContent)" | Out-File -FilePath $outputFile -Append
                $availableModels += $modelName
            }
        }
    }
    else {
        "No models field in response or response was empty." | Out-File -FilePath $outputFile -Append
        if ($listResponse) {
            $listResponse | Out-File -FilePath $outputFile -Append
        }
    }
}
catch {
    "WARN: ListModels failed or parsed no models." | Out-File -FilePath $outputFile -Append
    "Error: $_" | Out-File -FilePath $outputFile -Append
}

# 2. Test specific models (Force test if empty)
if ($availableModels.Count -eq 0) {
    "No models found via ListModels. Attempting default models blindly..." | Out-File -FilePath $outputFile -Append
    $modelsToTest = @("gemini-1.5-flash", "gemini-pro")
}
else {
    $modelsToTest = $availableModels | Select-Object -First 3
}

$tempBody = "temp_body.json"
$body = '{ "contents": [{ "parts": [{ "text": "Hello" }] }] }'
$body | Out-File $tempBody -Encoding ascii

foreach ($model in $modelsToTest) {
    $url = "$baseUrl/${model}:generateContent?key=$ApiKey"
    
    Write-Host "`nTesting model: $model"
    "----------------------------------------" | Out-File -FilePath $outputFile -Append
    "Testing model: $model" | Out-File -FilePath $outputFile -Append

    try {
        if ($curl) {
            $rawResponse = & curl.exe -s -H "Content-Type: application/json" -X POST -d ("@" + $tempBody) $url
            "DEBUG: Raw Generate Response: $(($rawResponse -join ' ').Substring(0, [math]::Min(500, ($rawResponse -join ' ').Length)))" | Out-File -FilePath $outputFile -Append
            
            try {
                $response = $rawResponse | ConvertFrom-Json
            }
            catch {
                "DEBUG: JSON Conversion Failed." | Out-File -FilePath $outputFile -Append
                continue
            }
            
            if ($response.error) {
                if ($response.error.code -ne 200) { throw $response.error.message }
            }
        }
        else {
            $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        }
        
        Write-Host "SUCCESS" -ForegroundColor Green
        "SUCCESS: Model $model is working." | Out-File -FilePath $outputFile -Append
        if ($response.candidates.content.parts.text) {
            "Response: $($response.candidates.content.parts.text)" | Out-File -FilePath $outputFile -Append
        }
    }
    catch {
        Write-Host "FAILED: $_" -ForegroundColor Red
        "FAILED: Model $model." | Out-File -FilePath $outputFile -Append
        "Error: $_" | Out-File -FilePath $outputFile -Append
    }
    continue
}
Remove-Item $tempBody -ErrorAction SilentlyContinue

Write-Host "`nCheck complete. Results written to $(Convert-Path $outputFile)" -ForegroundColor Cyan
