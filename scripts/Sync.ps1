<#
    Refreshes pluginmaster.json from each plugin's latest GitHub Release.

    For every entry in pluginmaster.json, the owning repo is taken from RepoUrl
    (https://github.com/<owner>/<repo>). That repo's latest release must carry two
    assets: "<InternalName>.zip" and "<InternalName>.json" (the DalamudPackager
    manifest). Version / API level / timestamp / download links are updated from
    those; the descriptive fields are left alone.
#>
param(
    [string] $PluginMasterPath = "pluginmaster.json"
)

$ErrorActionPreference = "Stop"
$headers = @{ "User-Agent" = "DalamudPlugins-sync" }
if ($env:GITHUB_TOKEN) { $headers["Authorization"] = "Bearer $($env:GITHUB_TOKEN)" }

$master = Get-Content $PluginMasterPath -Raw | ConvertFrom-Json
$changed = $false

foreach ($entry in $master) {
    if ($entry.RepoUrl -notmatch "github\.com/([^/]+)/([^/]+)") {
        Write-Warning "$($entry.InternalName): RepoUrl is not a GitHub repo, skipping"
        continue
    }
    $slug = "$($Matches[1])/$($Matches[2])".TrimEnd('/')
    $name = $entry.InternalName

    $release = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$slug/releases/latest"
    $manifestAsset = $release.assets | Where-Object { $_.name -eq "$name.json" } | Select-Object -First 1
    if (-not $manifestAsset) {
        Write-Warning "$name: latest release of $slug has no $name.json asset, skipping"
        continue
    }

    $manifest = (Invoke-RestMethod -Headers $headers -Uri $manifestAsset.browser_download_url)
    $version  = $manifest.AssemblyVersion
    $api      = $manifest.DalamudApiLevel
    $ts       = [int][double]::Parse((Get-Date $release.published_at -UFormat %s))
    $dl       = "https://github.com/$slug/releases/download/$($release.tag_name)/$name.zip"

    if ($entry.AssemblyVersion -eq $version -and $entry.DownloadLinkInstall -eq $dl) {
        Write-Host "$name: up to date ($version)"
        continue
    }

    $entry.AssemblyVersion        = $version
    $entry.TestingAssemblyVersion = $version
    $entry.DalamudApiLevel        = $api
    $entry.ApplicableVersion      = "any"
    $entry.LastUpdate             = $ts
    $entry.DownloadLinkInstall    = $dl
    $entry.DownloadLinkUpdate     = $dl
    $entry.DownloadLinkTesting    = $dl
    $changed = $true
    Write-Host "$name: -> $version (api $api)"
}

if ($changed) {
    $master | ConvertTo-Json -Depth 10 -AsArray | Set-Content $PluginMasterPath -Encoding UTF8
    Write-Host "pluginmaster.json updated"
} else {
    Write-Host "no changes"
}
