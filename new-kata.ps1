[CmdletBinding()]
param(
    [string]$Name,
    [string]$Description
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail {
    param([string]$Message)

    Write-Error $Message
    exit 1
}

function Get-ValidatedName {
    param([string]$RawName)

    if ([string]::IsNullOrWhiteSpace($RawName)) {
        Fail 'Kata name is required.'
    }

    $trimmedName = $RawName.Trim()

    if ($trimmedName -notmatch '^[A-Za-z0-9 -]+$') {
        Fail 'Kata name may contain only letters, numbers, spaces, and hyphens.'
    }

    return $trimmedName
}

function Get-NameParts {
    param([string]$ValidatedName)

    $parts = $ValidatedName -split '[ -]+' | Where-Object { $_ }

    if ($parts.Count -eq 0) {
        Fail 'Kata name must contain at least one letter or number.'
    }

    return $parts
}

function Get-Slug {
    param([string[]]$Parts)

    $slug = ($Parts | ForEach-Object { $_.ToLowerInvariant() }) -join '-'

    if ([string]::IsNullOrWhiteSpace($slug)) {
        Fail 'Kata name could not be converted into a folder name.'
    }

    return $slug
}

function Get-PascalCaseName {
    param([string[]]$Parts)

    $pascalCaseName = ($Parts | ForEach-Object {
        if ($_.Length -eq 1) {
            $_.ToUpperInvariant()
        }
        else {
            $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1).ToLowerInvariant()
        }
    }) -join ''

    if ([string]::IsNullOrWhiteSpace($pascalCaseName)) {
        Fail 'Kata name could not be converted into a C# identifier.'
    }

    if ($pascalCaseName -notmatch '^[A-Za-z][A-Za-z0-9]*$') {
        Fail 'Kata name must produce a C# identifier that starts with a letter.'
    }

    return $pascalCaseName
}

function Copy-TemplateDirectory {
    param(
        [string]$Source,
        [string]$Destination
    )

    foreach ($item in Get-ChildItem -LiteralPath $Source -Force) {
        if ($item.PSIsContainer) {
            if ($item.Name -in @('bin', 'obj')) {
                continue
            }

            $targetDirectory = Join-Path $Destination $item.Name
            New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
            Copy-TemplateDirectory -Source $item.FullName -Destination $targetDirectory
            continue
        }

        Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $Destination $item.Name)
    }
}

function Replace-FileContent {
    param(
        [string]$Path,
        [scriptblock]$Transform
    )

    $content = Get-Content -LiteralPath $Path -Raw
    $updatedContent = & $Transform $content
    Set-Content -LiteralPath $Path -Value $updatedContent
}

if ([string]::IsNullOrWhiteSpace($Name)) {
    $Name = Read-Host 'Enter kata name'
}

if ($null -eq $Description) {
    $Description = Read-Host 'Enter kata description (optional)'
}

$validatedName = Get-ValidatedName -RawName $Name
$parts = Get-NameParts -ValidatedName $validatedName
$slug = Get-Slug -Parts $parts
$pascalCaseName = Get-PascalCaseName -Parts $parts

$repoRoot = $PSScriptRoot
$templateRoot = Join-Path $repoRoot 'templates/csharp-kata'
$katasRoot = Join-Path $repoRoot 'katas'
$destinationRoot = Join-Path $katasRoot $slug

if (-not (Test-Path -LiteralPath $templateRoot -PathType Container)) {
    Fail "Template folder not found: $templateRoot"
}

if (-not (Test-Path -LiteralPath $katasRoot -PathType Container)) {
    Fail "Katas folder not found: $katasRoot"
}

if (Test-Path -LiteralPath $destinationRoot) {
    Fail "Destination already exists: $destinationRoot"
}

New-Item -ItemType Directory -Path $destinationRoot | Out-Null
Copy-TemplateDirectory -Source $templateRoot -Destination $destinationRoot

$generatedSolutionPath = Join-Path $destinationRoot 'csharp-kata.slnx'
$generatedProjectDirectory = Join-Path $destinationRoot 'Kata'
$generatedTestProjectDirectory = Join-Path $destinationRoot 'Kata.Tests'

$renamedSolutionPath = Join-Path $destinationRoot "$pascalCaseName.slnx"
$renamedProjectDirectory = Join-Path $destinationRoot $pascalCaseName
$renamedTestProjectDirectory = Join-Path $destinationRoot "$pascalCaseName.Tests"

Rename-Item -LiteralPath $generatedSolutionPath -NewName "$pascalCaseName.slnx"
Rename-Item -LiteralPath $generatedProjectDirectory -NewName $pascalCaseName
Rename-Item -LiteralPath $generatedTestProjectDirectory -NewName "$pascalCaseName.Tests"

$generatedProjectFile = Join-Path $renamedProjectDirectory 'Kata.csproj'
$generatedTestProjectFile = Join-Path $renamedTestProjectDirectory 'Kata.Tests.csproj'

$renamedProjectFile = Join-Path $renamedProjectDirectory "$pascalCaseName.csproj"
$renamedTestProjectFile = Join-Path $renamedTestProjectDirectory "$pascalCaseName.Tests.csproj"

Rename-Item -LiteralPath $generatedProjectFile -NewName "$pascalCaseName.csproj"
Rename-Item -LiteralPath $generatedTestProjectFile -NewName "$pascalCaseName.Tests.csproj"

Replace-FileContent -Path $renamedSolutionPath -Transform {
    param($content)

    $content.Replace('Kata.Tests/Kata.Tests.csproj', "$pascalCaseName.Tests/$pascalCaseName.Tests.csproj").Replace('Kata/Kata.csproj', "$pascalCaseName/$pascalCaseName.csproj")
}

Replace-FileContent -Path $renamedTestProjectFile -Transform {
    param($content)

    $content.Replace('..\Kata\Kata.csproj', "..\$pascalCaseName\$pascalCaseName.csproj")
}

Replace-FileContent -Path (Join-Path $renamedProjectDirectory 'Class1.cs') -Transform {
    param($content)

    $content.Replace('namespace Kata;', "namespace $pascalCaseName;")
}

Replace-FileContent -Path (Join-Path $renamedTestProjectDirectory 'UnitTest1.cs') -Transform {
    param($content)

    $content.Replace('namespace Kata.Tests;', "namespace $pascalCaseName.Tests;")
}

if (-not [string]::IsNullOrWhiteSpace($Description)) {
    Set-Content -LiteralPath (Join-Path $destinationRoot 'README.md') -Value $Description.Trim()
}

Write-Host "Created kata at $destinationRoot"