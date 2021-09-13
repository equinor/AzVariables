[CmdletBinding()]
param (
    [Parameter()]
    [switch] $Load,

    [Parameter()]
    [switch] $List,

    [Parameter()]
    [string] $VariableFilePath
)

$Task = ($MyInvocation.MyCommand.Name).split('.')[0]

function Import-Variables {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline = $true)]
        [string] $VariableFilePath
    )
    $Task = ($MyInvocation.MyCommand.Name).split('.')[0]
    Write-Output "$Task - $VariableFilePath - Processing"
    if (-not (Test-Path -Path $VariableFilePath)) {
        throw "$Task - $VariableFilePath - File not found"
    }

    $Variables = Get-Content -Path $VariableFilePath -Raw -Force | ConvertFrom-Json

    Write-Output "$Task - $VariableFilePath - Nested variable files - Processing"
    $NestedVariableFilePaths = ($Variables.PSObject.Properties | Where-Object Name -EQ 'VariableFilePaths').Value
    foreach ($NestedVariableFilePath in $NestedVariableFilePaths) {
        Write-Output "$Task - $VariableFilePath - Nested variable files - $NestedVariableFilePath"
        $NestedVariableFilePath | Import-Variables
    }

    Write-Output "$Task - $VariableFilePath - Loading variables"
    foreach ($Property in $Variables.PSObject.Properties) {
        if ($Property -match 'VariableFilePaths') {
            continue
        }
        Set-GitHubEnv -Name $Property.Name -Value $Property.Value -Verbose
    }
    Write-Output "$Task - $VariableFilePath - Done"
}

New-GitHubLogGroup -Title "$Task-Load Custom Variables"
Set-GitHubEnv -Name 'build' -Value (Get-Date -Format yyyyMMddhhmmss) -Verbose
Set-GitHubEnv -Name 'GITHUB_REPOSITORY_NAME' -Value ($env:GITHUB_REPOSITORY.split('/').split('\')[-1]) -Verbose

if ($Load) {
    New-GitHubLogGroup -Title "$Task-Load variables from file(s) to runner"

    Write-Output "$Task-Load variables from file(s) to runner - $VariableFilePath - Processing"
    if ($VariableFilePath | IsNullOrEmpty ) {
        throw "$Task-Load variables from file(s) to runner - $VariableFilePath - No file provided"
    }
    if (! (Test-Path -Path $VariableFilePath)) {
        Write-Warning "$Task-Load variables from file(s) to runner - $VariableFilePath - File not found. Trying workspace root."
        $VariableFilePath = "$env:GITHUB_WORKSPACE/$VariableFilePath"
    }
    if (! (Test-Path -Path $VariableFilePath)) {
        throw "$Task-Load variables from file(s) to runner - $VariableFilePath - File not found"
    }
    try {
        Import-Variables -VariableFilePath $VariableFilePath
    } catch {
        throw "$Task-Load variables from file(s) to runner - $VariableFilePath - Failed"
    }
    Write-Output '::endgroup::'
}

if ($List) {
    New-GitHubLogGroup -Title "$Task-List variables"
    Get-ChildItem -Path env:
    Write-Output '::endgroup::'
}
