# OpenCode VPN Web Search Skill - Windows Installer
# Requires: OpenCode, curl.exe (bundled with Windows 10+), a running proxy client

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " OpenCode VPN Web Search Skill - Installer " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Ask user for OpenCode path
Write-Host "OpenCode path (press Enter to skip):" -ForegroundColor Yellow
Write-Host "  Examples:" -ForegroundColor Gray
Write-Host "    C:\Users\<user>\AppData\Local\Programs\opencode\opencode.exe" -ForegroundColor Gray
Write-Host "    C:\Users\<user>\scoop\shims\opencode.exe" -ForegroundColor Gray
Write-Host "    %USERPROFILE%\.opencode\bin\opencode.exe" -ForegroundColor Gray
Write-Host ""

$opencodeInput = Read-Host "Path"
$opencodeInput = $opencodeInput.Trim()

if ([string]::IsNullOrWhiteSpace($opencodeInput)) {
    Write-Host "[i] OpenCode path not provided, skipping verification." -ForegroundColor Yellow
} else {
    $opencodeInput = [System.Environment]::ExpandEnvironmentVariables($opencodeInput)
    if (Test-Path -LiteralPath $opencodeInput) {
        Write-Host "[+] OpenCode found at: $opencodeInput" -ForegroundColor Green
    } else {
        Write-Host "[i] File not found: $opencodeInput" -ForegroundColor Yellow
        Write-Host "    Installation will continue anyway."
    }
}

# Check if curl.exe is available
$curlPath = Get-Command curl.exe -ErrorAction SilentlyContinue
if (-not $curlPath) {
    Write-Host "[!] curl.exe not found." -ForegroundColor Red
    Write-Host "    Windows 10+ includes curl.exe by default. Please check your system."
    exit 1
}
Write-Host "[+] curl.exe found at: $($curlPath.Source)" -ForegroundColor Green

# Ask for proxy port
Write-Host ""
Write-Host "Please enter your local proxy address (default: http://127.0.0.1:7890):" -ForegroundColor Yellow
$proxyInput = Read-Host "Proxy address"
if ([string]::IsNullOrWhiteSpace($proxyInput)) {
    $proxyAddress = "http://127.0.0.1:7890"
} else {
    $proxyAddress = $proxyInput
}
Write-Host "[+] Proxy address set to: $proxyAddress" -ForegroundColor Green

# Set environment variable
Write-Host ""
Write-Host "Setting OPENCODE_VPN_PROXY environment variable..." -ForegroundColor Yellow
try {
    [System.Environment]::SetEnvironmentVariable("OPENCODE_VPN_PROXY", $proxyAddress, "User")
    Write-Host "[+] Environment variable OPENCODE_VPN_PROXY set successfully." -ForegroundColor Green
} catch {
    Write-Host "[!] Failed to set environment variable: $_" -ForegroundColor Red
    Write-Host "    You can manually set it: `$env:OPENCODE_VPN_PROXY = '$proxyAddress'"
}

# Set for current session too
$env:OPENCODE_VPN_PROXY = $proxyAddress

# Determine target directory
$skillDir = "$env:USERPROFILE\.config\opencode\skills\vpn-web-search"
Write-Host ""
Write-Host "Installing Skill to: $skillDir" -ForegroundColor Yellow

# Create directory
New-Item -ItemType Directory -Path $skillDir -Force | Out-Null

# Copy SKILL.md
$sourceSkill = Join-Path $PSScriptRoot "skills\vpn-web-search\SKILL.md"
if (Test-Path $sourceSkill) {
    Copy-Item -Path $sourceSkill -Destination $skillDir -Force
    Write-Host "[+] SKILL.md copied successfully." -ForegroundColor Green
} else {
    Write-Host "[!] SKILL.md not found at: $sourceSkill" -ForegroundColor Red
    Write-Host "    Make sure you are running this script from the repository root."
    exit 1
}

# Check if we're in a project with opencode.json
$projectConfig = Join-Path (Get-Location) "opencode.json"
$action = "completed"

if (Test-Path $projectConfig) {
    Write-Host ""
    Write-Host "Found project opencode.json, merging webfetch deny permission..." -ForegroundColor Yellow
    try {
        $config = Get-Content $projectConfig -Raw | ConvertFrom-Json
        if (-not $config.permission) {
            $config | Add-Member -MemberType NoteProperty -Name "permission" -Value @{ webfetch = "deny" }
        } elseif (-not $config.permission.webfetch) {
            $config.permission | Add-Member -MemberType NoteProperty -Name "webfetch" -Value "deny"
        } else {
            $config.permission.webfetch = "deny"
        }
        $config | ConvertTo-Json -Depth 10 | Set-Content $projectConfig
        Write-Host "[+] webfetch: deny added to opencode.json" -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to update opencode.json: $_" -ForegroundColor Red
        Write-Host "    Add manually: { `"permission`": { `"webfetch`": `"deny`" } }"
    }
} else {
    Write-Host ""
    Write-Host "No project opencode.json found. You can add webfetch deny manually:" -ForegroundColor Yellow
    Write-Host '  Add to opencode.json: { "permission": { "webfetch": "deny" } }'
}

# Done
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Installation Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart OpenCode"
Write-Host "  2. Verify the skill appears: type /skills in OpenCode"
Write-Host "  3. Test: ask OpenCode to fetch a page through VPN"
Write-Host ""
Write-Host "Proxy: $proxyAddress" -ForegroundColor Gray
Write-Host ""

# Verify proxy connectivity
Write-Host "Testing proxy connectivity..." -ForegroundColor Yellow
try {
    $testResult = & curl.exe --proxy $proxyAddress -sL -o NUL -w "%{http_code}" "https://raw.githubusercontent.com" 2>$null
    if ($LASTEXITCODE -eq 0 -and $testResult -eq "200") {
        Write-Host "[+] Proxy test PASSED - raw.githubusercontent.com is reachable" -ForegroundColor Green
    } else {
        Write-Host "[!] Proxy test returned HTTP $testResult" -ForegroundColor Yellow
        Write-Host "    Check if your proxy client is running and the port is correct."
    }
} catch {
    Write-Host "[!] Proxy test failed. Make sure your proxy client is running." -ForegroundColor Red
}

Read-Host "`nPress Enter to exit"
