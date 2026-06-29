$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputDir = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$zipPath = Join-Path $outputDir ('sidar-mac-source-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.zip')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $roots = @('lib', 'assets', 'ios', 'android', 'macos', 'linux', 'windows', 'web', 'test', 'scripts', 'docs', 'supabase')
    $files = @('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', '.metadata', '.gitignore', '.gitattributes', 'README.md', 'APPLE_BUILD.md')
    foreach ($folder in $roots) {
        $folderPath = Join-Path $projectRoot $folder
        if (Test-Path -LiteralPath $folderPath) {
            $files += Get-ChildItem -LiteralPath $folderPath -File -Recurse -Force |
                ForEach-Object { $_.FullName.Substring($projectRoot.Length + 1).Replace('\', '/') }
        }
    }
    foreach ($relative in ($files | Sort-Object -Unique)) {
        if ($relative -match '(^|/)(build|Pods|\.symlinks|ephemeral|\.gradle|\.dart_tool|\.swiftpm|xcuserdata|\.temp|node_modules)(/|$)') { continue }
        if ($relative -match '(^|/)(\.env.*|local.properties|key.properties|Generated.xcconfig|flutter_export_environment.sh|GeneratedPluginRegistrant\.[hm]|\.last_build_id)$') { continue }
        if ($relative -match '\.(jks|keystore|p12|mobileprovision)$') { continue }
        $sourcePath = Join-Path $projectRoot $relative
        if (Test-Path -LiteralPath $sourcePath -PathType Leaf) {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $sourcePath, "skincare/$relative", [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    }
} finally { $archive.Dispose() }
Get-Item -LiteralPath $zipPath | Select-Object FullName, Length
