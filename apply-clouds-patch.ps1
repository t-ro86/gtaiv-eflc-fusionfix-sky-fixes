param(
    [string]$InstallPath = "$PWD"
)

Write-Output "Applying Clouds.fx sampler_state patch under: $InstallPath"

$target = Join-Path $InstallPath "source\resources\Clouds.fx"
if (-not (Test-Path $target)) {
    Write-Error "Could not find Clouds.fx at $target. Ensure the upstream repo was cloned into this folder."
    exit 1
}

$backup = $target + ".bak"
if (-not (Test-Path $backup)) {
    Copy-Item $target $backup -Force
    Write-Output "Backup created: $backup"
} else {
    Write-Output "Backup already exists: $backup"
}

$content = Get-Content $target -Raw -ErrorAction Stop

$pattern = '(?s)sampler2D\s+DepthTex.*?sampler2D\s+SkyViewTex.*?;'
if ($content -notmatch $pattern) {
    Write-Error "Could not find expected sampler block in Clouds.fx. The file may already be patched or has a different structure. Exiting."
    exit 1
}

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

$regex = New-Object System.Text.RegularExpressions.Regex($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$newContent = $regex.Replace($content, $newBlock, 1)
Set-Content -Path $target -Value $newContent -Encoding UTF8

Write-Output "Patched Clouds.fx successfully. Backup at: $backup"
