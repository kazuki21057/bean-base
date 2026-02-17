param([string]$ApiKey)

if (-not $ApiKey) {
    $ApiKey = Read-Host "Input API Key"
}
$ApiKey = $ApiKey.Trim()

Write-Host "Verifying key: $ApiKey"

# 1. List Models
Write-Host "`n[1] Listing Available Models..."
try {
    $Uri = "https://generativelanguage.googleapis.com/v1beta/models?key=$ApiKey"
    $response = Invoke-RestMethod -Uri $Uri -Method Get
    Write-Host "Success!" -ForegroundColor Green
    if ($response.models) {
        $response.models | ForEach-Object { 
            $name = $_.name -replace "models/", ""
            Write-Host " - $name" 
        }
    }
    else {
        Write-Host "Warning: No models returned in list." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "List Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Payload for generation
$Body = @{
    contents = @(
        @{ parts = @( @{ text = "Hello" } ) }
    )
} | ConvertTo-Json -Depth 5

# Test Model Configuration
$ModelName = "gemini-2.5-flash"
# $ModelName = "gemini-3-pro-preview" # Uncomment to test later

Write-Host "`n[2] Testing $ModelName..."
try {
    $GenUri = "https://generativelanguage.googleapis.com/v1beta/models/${ModelName}:generateContent?key=$ApiKey"
    $Body = @{
        contents = @(
            @{ parts = @( @{ text = "Hello" } ) }
        )
    } | ConvertTo-Json -Depth 5

    $genResponse = Invoke-RestMethod -Uri $GenUri -Method Post -Body $Body -ContentType "application/json"
    Write-Host "Success!" -ForegroundColor Green
    if ($genResponse.candidates.content.parts.text) {
        Write-Host "Response: $($genResponse.candidates.content.parts.text)"
    }
}
catch {
    Write-Host "Failed ($ModelName): $($_.Exception.Message)" -ForegroundColor Red
}
