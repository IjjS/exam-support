param([string]$Destination = 'exam-support', [string]$Ref = 'main')
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $Destination) { throw "Destination already exists: $Destination" }
$work = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
try {
    New-Item -ItemType Directory -Path $work | Out-Null
    $archive = Join-Path $work 'source.zip'
    Invoke-WebRequest -Uri "https://codeload.github.com/IjjS/exam-support/zip/$Ref" -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path $work 'source')
    $source = (Get-ChildItem (Join-Path $work 'source') -Directory | Select-Object -First 1).FullName
    $workspace = Join-Path $work 'workspace'
    New-Item -ItemType Directory -Path $workspace | Out-Null
    foreach ($item in @('.agents', '_spec', '_template', '_inbox', 'docs', 'CLAUDE.md', 'README.md', 'README_KO.md', 'LICENSE', '.gitignore')) {
        Copy-Item -LiteralPath (Join-Path $source $item) -Destination $workspace -Recurse
    }
    foreach ($name in @('AGENTS.md', 'GEMINI.md')) {
        Copy-Item (Join-Path $workspace 'CLAUDE.md') (Join-Path $workspace $name)
    }
    New-Item -ItemType Directory -Path (Join-Path $workspace '.claude') | Out-Null
    Copy-Item (Join-Path $workspace '.agents/skills') (Join-Path $workspace '.claude/skills') -Recurse
    Copy-Item (Join-Path $workspace '_template/exams') (Join-Path $workspace 'exams') -Recurse
    Move-Item -LiteralPath $workspace -Destination $Destination
    Write-Output "Installed: $Destination — open this folder in your agent and ask to register an exam."
} finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
}
