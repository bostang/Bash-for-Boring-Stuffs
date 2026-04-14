# Gemini Fast (gf)
  # Program CLI sederhana untuk berinteraksi dengan API Gemini
  # notes : pastikan terdapat .env yang sejajar dengan file gf.ps1 yang berisi API key.
  # contoh isi file .env : 'Ax7....'
  
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
function Start-GeminiChat {
    # --- 1. KONFIGURASI API & MODEL ---
    $envPath = Join-Path $PSScriptRoot ".env"

    if (Test-Path $envPath) {
        # -Raw membaca seluruh file sebagai satu string
        # .Trim() membuang spasi atau enter yang tidak sengaja terketik
        $apiKey = (Get-Content $envPath -Raw).Trim()
    }

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Host "[!] ERROR: API Key kosong atau file .env tidak ditemukan!" -ForegroundColor Red
        return
    }
    
    $modelName = "gemini-2.5-flash-lite" 
    $url = "https://generativelanguage.googleapis.com/v1beta/models/$($modelName):generateContent?key=$apiKey"
    
    # Fix Error 417
    [System.Net.ServicePointManager]::Expect100Continue = $false
    
    # --- 2. KONFIGURASI LOGGING ---
    $logFolder = "C:\Users\70556\Scripts\gf\gemini-cli-chat-history"
    if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder }
    $logFile = "$logFolder\ChatHistory_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    
    # --- 3. STATE AWAL ---
    $script:chatHistory = @()
    $isBrief = $false
    $lastResponse = ""

    # --- 4. HELPER: FORMATTER WARNA MARKDOWN ---
    function Write-Markdown {
        param([string]$entireText)
        
        $lines = $entireText -split "`n"
        $inCodeBlock = $false

        foreach ($line in $lines) {
            # 1. Tampilan Code Block (Batas ```)
            if ($line -match '```') {
                $inCodeBlock = -not $inCodeBlock
                # Gunakan Green agar terlihat seperti terminal hacker
                Write-Host $line -ForegroundColor Green 
                continue
            }

            # 2. Isi di dalam Code Block
            if ($inCodeBlock) {
                # Gunakan Gray (bukan DarkGray) agar lebih terang
                Write-Host $line -ForegroundColor Gray 
                continue
            }

            # 3. Deteksi Header ( # Judul )
            if ($line -match '^#+\s+(.*)') {
                Write-Host $line -ForegroundColor Cyan -Bold # Header jadi Biru Muda Terang
                continue
            }

            # 4. Deteksi Bullet Point
            $currentLine = $line
            if ($line -match '^\s*\*\s+(.*)') {
                # Menggunakan tanda '>' yang lebih aman untuk semua jenis terminal
                Write-Host " > " -ForegroundColor Yellow -NoNewline
                $currentLine = $Matches[1]
            }

            # 5. Regex: Bold (**), Italic (*), Inline Code (`)
            $pattern = '(\*\*.*?\*\*|\*.*?\*|`.*?`)'
            $parts = [regex]::Split($currentLine, $pattern)
            
            foreach ($part in $parts) {
                if ($part -match '^\*\*(.*?)\*\*$') {
                    # BOLD -> Kuning Terang
                    Write-Host $Matches[1] -ForegroundColor Yellow -NoNewline
                } elseif ($part -match '^\*(.*?)\*$') {
                    # ITALIC -> Hijau Terang (Ganti dari Ungu)
                    Write-Host $part.Replace("*","") -ForegroundColor Green -NoNewline
                } elseif ($part -match '^`(.*?)`$') {
                    # INLINE CODE -> Putih dengan Background Biru (sangat kontras)
                    Write-Host " $($Matches[1]) " -ForegroundColor White -BackgroundColor Blue -NoNewline
                } else {
                    # TEKS NORMAL -> Putih Terang
                    Write-Host $part -ForegroundColor White -NoNewline
                }
            }
            Write-Host "" 
        }
    }

    # --- 5. HELPER: TAMPILAN HEADER ---
    function Show-Header {
        Clear-Host
        $statusBrief = if ($isBrief) { "AKTIF (1 Paragraf)" } else { "NON-AKTIF" }
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "          _____                    _____          " -ForegroundColor Green
        Write-Host "         /\    \                  /\    \         " -ForegroundColor Green
        Write-Host "        /::\    \                /::\    \        " -ForegroundColor Green
        Write-Host "       /::::\    \              /::::\    \       " -ForegroundColor Green
        Write-Host "      /::::::\    \            /::::::\    \      " -ForegroundColor Green
        Write-Host "     /:::/\:::\    \          /:::/\:::\    \     " -ForegroundColor Green
        Write-Host "    /:::/  \:::\    \        /:::/__\:::\    \    " -ForegroundColor Green
        Write-Host "   /:::/    \:::\    \      /::::\   \:::\    \   " -ForegroundColor Green
        Write-Host "  /:::/    / \:::\    \    /::::::\   \:::\    \  " -ForegroundColor Green
        Write-Host " /:::/    /   \:::\ ___\  /:::/\:::\   \:::\    \ " -ForegroundColor Green
        Write-Host "/:::/____/  ___\:::|    |/:::/  \:::\   \:::\____\" -ForegroundColor Green
        Write-Host "\:::\    \ /\  /:::|____|\::/    \:::\   \::/    /" -ForegroundColor Green
        Write-Host " \:::\    /::\ \::/    /  \/____/ \:::\   \/____/ " -ForegroundColor Green
        Write-Host "  \:::\   \:::\ \/____/            \:::\    \     " -ForegroundColor Green
        Write-Host "   \:::\   \:::\____\               \:::\____\    " -ForegroundColor Green
        Write-Host "    \:::\  /:::/    /                \::/    /    " -ForegroundColor Green
        Write-Host "     \:::\/:::/    /                  \/____/     " -ForegroundColor Green
        Write-Host "      \::::::/    /                               " -ForegroundColor Green
        Write-Host "       \::::/    /                                " -ForegroundColor Green
        Write-Host "        \::/____/                                 " -ForegroundColor Green
        Write-Host "                                                  " -ForegroundColor Green
        Write-Host "                                                  " -ForegroundColor Green
        Write-Host "GEMINI AI INTERACTIVE CLI - v4.8 FAST" -ForegroundColor White -BackgroundColor Blue
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host " [BRIEF MODE: $statusBrief]" -ForegroundColor Yellow
        Write-Host "basic commands: help, exit" -ForegroundColor DarkGray
        Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    }

    Show-Header
    if (-not (Test-Path $logFile)) { 
        $header = "# Sesi Chat Gemini - $(Get-Date -Format 'dd MMMM yyyy HH:mm')`r`n`r`n"
        [System.IO.File]::WriteAllText($logFile, $header, [System.Text.Encoding]::UTF8)
    }

    # --- 6. MAIN INTERACTIVE LOOP ---
    while ($true) {
        # $promptLabel = if ($isBrief) { "Anda (Brief)" } else { "Anda" }
        # $promptLabel = "> "
        Write-Host "`n[$(Get-Date -Format 'HH:mm')] " -NoNewline -ForegroundColor DarkGray
        # $userInput = Read-Host $promptLabel
        Write-Host "> " -NoNewline -ForegroundColor Cyan
        $userInput = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($userInput)) { continue }
        
        # --- LOGIC OPEN EXPLORER ---
        if ($userInput -eq "explorer") {
            Start-Process explorer.exe $logFolder
            Write-Host "Membuka folder history di File Explorer..." -ForegroundColor Green
            continue
        }

        # --- LOGIC COPY ---
        if ($userInput -eq "copy") {
            if ($lastResponse) {
                $lastResponse | Set-Clipboard
                Write-Host "Respons terakhir telah disalin ke clipboard!" -ForegroundColor Green
            } else {
                Write-Host "Belum ada respons untuk disalin." -ForegroundColor Yellow
            }
            continue
        }

        # --- LOGIC OPEN IN VS CODE (code [idx]) ---
        if ($userInput -match "^code(\s+(\d+))?$") {
            $targetIndex = $Matches[2]
            $files = Get-ChildItem $logFolder -Filter *.md | Sort-Object LastWriteTime -Descending
            
            if ($null -eq $targetIndex) {
                # Jika cuma ketik 'code', buka file yang sedang aktif saat ini
                & code $logFile
                Write-Host "Membuka log sesi aktif di VS Code..." -ForegroundColor Green
            } elseif ($targetIndex -lt $files.Count) {
                # Jika pakai index (misal: code 1), buka file dari history
                $targetFile = $files[[int]$targetIndex].FullName
                & code $targetFile
                Write-Host "Membuka $($files[[int]$targetIndex].Name) di VS Code..." -ForegroundColor Green
            } else {
                Write-Host "Index tidak ditemukan." -ForegroundColor Red
            }
            continue
        }

        # --- LOGIC PERINTAH KHUSUS ---
        if ($userInput -eq "exit") { break }
        if ($userInput -eq "help") {
            Write-Host "`n[ DAFTAR PERINTAH ]" -ForegroundColor Cyan
            Write-Host " explorer    : Buka folder history di File Explorer" -ForegroundColor Gray
            Write-Host " logs [idx] : Lihat daftar/preview history" -ForegroundColor Gray
            Write-Host " del [idx]  : Hapus file history" -ForegroundColor Gray
            Write-Host " ren [idx]  : Rename file history" -ForegroundColor Gray
            Write-Host " brief      : Toggle mode jawaban singkat" -ForegroundColor Gray
            Write-Host " clear      : Reset chat & layar" -ForegroundColor Gray
            Write-Host " copy      : Menyalin respons terakhir ke clipboard" -ForegroundColor Gray
            Write-Host " code      : Membuka file log (chat koversation) di VSCode" -ForegroundColor Gray
            continue
        }

        if ($userInput -eq "clear") { $script:chatHistory = @(); Show-Header; continue }
        if ($userInput -eq "brief") { $isBrief = -not $isBrief; Show-Header; continue }

        # --- LOGIC LOGS / DELETE / RENAME ---
        if ($userInput -match "^(logs|del|ren)(\s+(\d+))?$") {
            $cmd = $Matches[1]
            $targetIndex = $Matches[3]
            $files = Get-ChildItem $logFolder -Filter *.md | Sort-Object LastWriteTime -Descending
            
            if ($null -eq $targetIndex) {
                Write-Host "`n--- Daftar History ($($files.Count) file) ---" -ForegroundColor Cyan
                for ($i=0; $i -lt $files.Count; $i++) { Write-Host "[$i] $($files[$i].Name)" -ForegroundColor Yellow }
                $targetIndex = Read-Host "`nPilih nomor"
            }

            if ($targetIndex -ne "" -and $targetIndex -lt $files.Count) {
                $targetFile = $files[[int]$targetIndex]
                if ($cmd -eq "logs") {
                    Write-Host "`nPREVIEW: $($targetFile.Name)" -BackgroundColor DarkGray
                    Get-Content $targetFile.FullName | ForEach-Object { Write-Markdown -entireText $_ }
                } elseif ($cmd -eq "del") {
                    Remove-Item $targetFile.FullName; Write-Host "Dihapus!" -ForegroundColor Red
                } elseif ($cmd -eq "ren") {
                    $newName = Read-Host "Nama baru (tanpa .md)"
                    Rename-Item $targetFile.FullName -NewName "$newName.md"; Write-Host "Sukses!" -ForegroundColor Green
                }
            }
            continue
        }

        # --- 7. REQUEST KE API ---
        $maxTokens = if ($isBrief) { 200 } else { 2048 }
        $modifiedInput = if ($isBrief) { "Answer briefly in 1 paragraph, plain text: $userInput" } else { $userInput }
        
        $script:chatHistory += @{ role = "user"; parts = @(@{ text = $modifiedInput }) }
        $bodyObj = @{ contents = $script:chatHistory; generationConfig = @{ maxOutputTokens = $maxTokens; temperature = 0.7 } }
        $jsonBody = $bodyObj | ConvertTo-Json -Depth 10

        Write-Host "Gemini sedang berpikir..." -ForegroundColor DarkGray

        try {
            $startTime = Get-Date
            $response = Invoke-RestMethod -Uri $url -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($jsonBody)) -ContentType "application/json" -UseBasicParsing
            $duration = "{0:N2}" -f ((Get-Date) - $startTime).TotalSeconds

            if ($response.candidates) {
                $aiResponse = $response.candidates[0].content.parts[0].text
                $lastResponse = $aiResponse
                Write-Host "`n--- Gemini ($duration s) ---" -ForegroundColor Green
                Write-Markdown -entireText $aiResponse
                $script:chatHistory += @{ role = "model"; parts = @(@{ text = $aiResponse }) }

                # Menggunakan format teks bersih tanpa emoji
                $logEntry = "## [TIME] $(Get-Date -Format 'HH:mm:ss')`n- **Anda:** $userInput`n- **Gemini:**`n$aiResponse`n---`n"

                # Tulis ke file menggunakan UTF8 standar
                [System.IO.File]::AppendAllText($logFile, $logEntry, [System.Text.Encoding]::UTF8)
            }
        } catch {
            Write-Host "`n[!] Error: $($_.Exception.Message)" -ForegroundColor Red
            if ($script:chatHistory.Count -gt 0) { $script:chatHistory = $script:chatHistory[0..($script:chatHistory.Count - 2)] }
        }
    }
}
Start-GeminiChat
