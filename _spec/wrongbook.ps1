param(
    [Parameter(Position=0, Mandatory=$true)][string]$Slug,
    [Parameter(Position=1, Mandatory=$true)][string]$Command,
    [Parameter(Position=2, ValueFromRemainingArguments=$true)][string[]]$Ids
)
$ErrorActionPreference = 'Stop'
$book = Join-Path "exams/$Slug/state" 'wrongbook.md'
$resolved = Join-Path "exams/$Slug/state" '_resolved.md'
$lines = @(Get-Content -LiteralPath $book -Encoding UTF8)
function Cells($row) { @($row.Split('|') | ForEach-Object { $_.Trim() }) }
function Rows($content) { @($content | Where-Object { $_ -match '^\| W-\d+ \|' }) }
function Save($path, $content) {
    [IO.File]::WriteAllLines([IO.Path]::GetFullPath($path), [string[]]$content, [Text.UTF8Encoding]::new($false))
}
function Insert($content, $newRows) {
    $position = -1
    for ($index = 0; $index -lt $content.Count; $index++) {
        if ($content[$index] -match '^\| W-') { $position = $index }
    }
    if ($position -lt 0) {
        for ($index = 0; $index -lt $content.Count; $index++) {
            if ($content[$index] -match '^\|( *\|)+ *$') {
                $content[$index] = $null
                $position = $index
                break
            }
            if ($content[$index] -match '^\|-') { $position = $index }
        }
    }
    if ($position -lt 0) { throw 'No table found' }
    for ($index = 0; $index -lt $content.Count; $index++) {
        if ($null -ne $content[$index]) { $content[$index] }
        if ($index -eq $position) { $newRows }
    }
}
$entries = @(Rows $lines)
switch ($Command) {
    'index' {
        $groups = $entries | Group-Object { (Cells $_)[2] } | Sort-Object Name
        ($groups | ForEach-Object { "$($_.Name) $($_.Count) " + (($_.Group | ForEach-Object { (Cells $_)[3] }) -join ',') }) -join '; '
        return
    }
    'rows' { if (!$Ids) { throw 'Topic IDs required' }; $entries | Where-Object { (Cells $_)[2] -in $Ids }; return }
    'id' { if (!$Ids) { throw 'W-IDs required' }; $entries | Where-Object { (Cells $_)[1] -in $Ids }; return }
    'type' { if ($Ids.Count -ne 1) { throw 'One error type required' }; $entries | Where-Object { (Cells $_)[4] -eq $Ids[0] }; return }
    'next-id' {
        $all = $entries
        if (Test-Path $resolved) { $all += @(Rows @(Get-Content $resolved -Encoding UTF8)) }
        $maximum = ($all | ForEach-Object { [int]((Cells $_)[1].Substring(2)) } | Measure-Object -Maximum).Maximum
        'W-{0:D3}' -f ([int]$maximum + 1)
        return
    }
    'keywords' {
        $value = [Console]::In.ReadLine()
        Save $book @($lines | ForEach-Object { if ($_ -match '^missed keywords: ') { "missed keywords: $value" } else { $_ } })
        return
    }
}
if ($Command -notin @('add', 'set', 'retire')) { throw "Unknown command: $Command" }
$incoming = @(Rows @([Console]::In.ReadToEnd() -split '\r?\n'))
if (!$incoming.Count) { throw 'No rows on stdin' }
$retired = if (Test-Path $resolved) { @(Get-Content $resolved -Encoding UTF8) } else { @() }
$header = if ($Command -eq 'retire') { $retired } else { $lines }
$header = @($header | Where-Object { $_ -match '^\| ID ' })
if ($header.Count -ne 1) { throw 'Expected one table header' }
$width = (Cells $header[0]).Count
$changes = @{}
$existing = @($entries | ForEach-Object { (Cells $_)[1] })
$oldIds = @(Rows $retired | ForEach-Object { (Cells $_)[1] })
foreach ($row in $incoming) {
    $cells = Cells $row
    $entryId = $cells[1]
    if ($cells.Count -ne $width -or $row -notmatch '\|\s*$') { throw "Malformed row: $entryId" }
    if ($changes.ContainsKey($entryId)) { throw "Duplicate input: $entryId" }
    if ($Command -eq 'add' -and ($entryId -in $existing -or $entryId -in $oldIds)) { throw "Already exists: $entryId" }
    if ($Command -ne 'add' -and $entryId -notin $existing) { throw "Not in book: $entryId" }
    $changes[$entryId] = $row
}
if ($Command -eq 'add') { $lines = @(Insert $lines $incoming) }
else {
    $lines = @($lines | ForEach-Object {
        $entryId = if ($_ -match '^\| W-') { (Cells $_)[1] } else { '' }
        if (!$changes.ContainsKey($entryId)) { $_ }
        elseif ($Command -eq 'set') { $changes[$entryId] }
    })
}
if ($Command -eq 'retire') {
    $retired = @(Insert $retired $incoming)
    $count = @(Rows $retired).Count
    Save $resolved @($retired | ForEach-Object { if ($_ -match '^resolved: ') { "resolved: $count" } else { $_ } })
}
$entries = @(Rows $lines)
$origins = @{}
$types = @{}
foreach ($row in $entries) {
    $cells = Cells $row
    $origins[$cells[3]]++
    $types[$cells[4]]++
}
$lines = @($lines | ForEach-Object {
    if ($_ -match '^active: ') { 'active: {0}  (miss {1} / lucky {2} / shaky {3})' -f $entries.Count, [int]$origins.miss, [int]$origins.lucky, [int]$origins.shaky }
    elseif ($_ -match '^types: ') { 'types: unknown {0} / confusion {1} / misread {2} / distractor {3} / recall {4}' -f [int]$types.unknown, [int]$types.confusion, [int]$types.misread, [int]$types.distractor, [int]$types.recall }
    else { $_ }
})
Save $book $lines
"$Command $($incoming.Count)"
