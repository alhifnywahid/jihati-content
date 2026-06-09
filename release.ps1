<#
.SYNOPSIS
    Rilis konten Jihati sekali-jalan: regenerasi manifest, commit, push ke main,
    buat & push tag immutable, lalu purge cache manifest jsDelivr.

.DESCRIPTION
    Pola rilis OTA Jihati:
      - Aplikasi membaca manifest dari alamat TETAP: @master/manifest.json
      - File konten disajikan dari TAG immutable: @content-vN/
    Skrip ini merangkum seluruh langkah rilis menjadi satu perintah sehingga
    perubahan konten TIDAK memerlukan rilis ulang aplikasi ke Play Store.

.PARAMETER Version
    Nomor contentVersion baru (integer). Tag yang dibuat: content-v<Version>.

.PARAMETER Message
    Pesan commit (deskripsi singkat perubahan).

.PARAMETER Owner
    Pemilik repo GitHub. Default: alhifnywahid.

.PARAMETER Branch
    Branch utama. Default: main.

.EXAMPLE
    ./release.ps1 -Version 3 -Message "koreksi harakat Surat Al-Mulk"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$Version,

    [Parameter(Mandatory = $true)]
    [string]$Message,

    [string]$Owner = "alhifnywahid",

    [string]$Branch = "master"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$repo    = "jihati-content"
$tag     = "content-v$Version"
$baseUrl = "https://cdn.jsdelivr.net/gh/$Owner/$repo@$tag/"
$purgeUrl = "https://purge.jsdelivr.net/gh/$Owner/$repo@$Branch/manifest.json"

Write-Host "==> Rilis konten Jihati" -ForegroundColor Cyan
Write-Host "    contentVersion : $Version"
Write-Host "    tag            : $tag"
Write-Host "    baseUrl        : $baseUrl"
Write-Host "    branch         : $Branch"
Write-Host ""

# 1. Regenerasi manifest (hitung ulang sha256 + ukuran, set versi & baseUrl)
Write-Host "==> 1/5 Regenerasi manifest.json ..." -ForegroundColor Cyan
python generate_manifest.py --version $Version --base-url $baseUrl
if ($LASTEXITCODE -ne 0) { throw "generate_manifest.py gagal." }

# Konfirmasi sebelum operasi git yang mendorong ke remote
Write-Host ""
$confirm = Read-Host "Lanjut commit + push ke '$Branch' dan tag '$tag'? (y/N)"
if ($confirm -notin @("y", "Y")) {
    Write-Host "Dibatalkan. manifest.json sudah diperbarui secara lokal; tidak ada yang di-push." -ForegroundColor Yellow
    exit 0
}

# 2. Commit
Write-Host "==> 2/5 Commit perubahan ..." -ForegroundColor Cyan
git add .
git commit -m "content: rilis v$Version ($Message)"

# 3. Push ke branch utama (manifest yang dibaca aplikasi)
Write-Host "==> 3/5 Push ke origin/$Branch ..." -ForegroundColor Cyan
git push origin $Branch

# 4. Buat & push tag immutable (snapshot file konten)
Write-Host "==> 4/5 Membuat & push tag $tag ..." -ForegroundColor Cyan
git tag $tag
git push origin $tag

# 5. Purge cache jsDelivr untuk manifest @master agar versi baru cepat terbaca
Write-Host "==> 5/5 Purge cache manifest jsDelivr ..." -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri $purgeUrl -Method Get | Out-Null
    Write-Host "    Purge OK: $purgeUrl" -ForegroundColor Green
}
catch {
    Write-Host "    Purge gagal/diabaikan. Buka manual di browser:" -ForegroundColor Yellow
    Write-Host "    $purgeUrl"
}

Write-Host ""
Write-Host "Selesai. Aplikasi akan mendeteksi versi $Version pada pengecekan berikutnya." -ForegroundColor Green
Write-Host "Manifest (dibaca aplikasi): https://cdn.jsdelivr.net/gh/$Owner/$repo@$Branch/manifest.json"
