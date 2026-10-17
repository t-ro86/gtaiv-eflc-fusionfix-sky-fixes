param(
    [string]$InstallPath = "C:\Path\To\FusionFix"
)

Write-Output "Applying Clouds.fx sampler_state patch under: $InstallPath"

# Find Clouds.fx recursively under the install path
$files = Get-ChildItem -Path $InstallPath -Recurse -Filter Clouds.fx -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $files) {
    Write-Error "Could not find Clouds.fx under $InstallPath. Make sure the path is correct and that Clouds.fx exists in the release folder."
    exit 1
}

$target = $files.FullName
Write-Output "Found Clouds.fx at: $target"

$backup = $target + ".bak"
if (-not (Test-Path $backup)) {
    Copy-Item $target $backup -Force
    Write-Output "Backup created: $backup"
} else {
    Write-Output "Backup already exists: $backup"
}

# Read file
$content = Get-Content $target -Raw -ErrorAction Stop

# Regex to find the sampler block from DepthTex to SkyViewTex (inclusive). Singleline so . matches newline
$pattern = '(?s)sampler2D\s+DepthTex.*?sampler2D\s+SkyViewTex.*?;'
if ($content -notmatch $pattern) {
    Write-Error "Could not find expected sampler block in Clouds.fx. The file may already be patched or has a different structure. Exiting."
    exit 1
}

# New sampler block
$newBlock = @'
sampler2D DepthTex : register(s0) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler2D CoverageTex : register(s1) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = WRAP;
    AddressV = WRAP;
};

sampler3D DetailTex : register(s2) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;
};

sampler2D CurrentTex : register(s3) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler2D HistoryTex : register(s4) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler2D CloudTex : register(s5) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler2D SceneTex : register(s6) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler2D SkyRefTex : register(s7) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler2D MarchTex0 : register(s8) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler2D MarchTex1 : register(s9) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler2D SkyViewTex : register(s10) = sampler_state
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};
'@

# Replace using .NET Regex for singleline
$regex = New-Object System.Text.RegularExpressions.Regex($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$newContent = $regex.Replace($content, $newBlock, 1)

# Write back
Set-Content -Path $target -Value $newContent -Encoding UTF8

Write-Output "Patched Clouds.fx successfully. Backup at: $backup"
Write-Output "If you need to revert, restore the backup: Rename $backup to the original filename."