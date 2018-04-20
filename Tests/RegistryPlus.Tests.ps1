[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $thisModuleName = 'RegistryPlus'
    ,
    [Parameter()]
    [string]
    $Examples       = $(if ($env:PesterExamples) { $env:PesterExamples } else { '*' })
    ,
    [Parameter()]
    [string]
    $DSCModulePath  = "${SystemRoot}\System32\WindowsPowerShell\v1.0\Modules"
    ,
    [Parameter()]
    [bool]
    $CleanUp        = $(if ($env:CI -eq 'true') { $false } else { $true })
)

$ParentModulePath = "${env:ProgramFiles}\WindowsPowerShell\Modules\${thisModuleName}"
$ResourceModulePath = "${ParentModulePath}\DSCResources\${thisModuleName}"
$PSScriptRootParent = $(Split-Path $PSScriptRoot -Parent)
$ManifestJsonFile  = "${PSScriptRootParent}\${thisModuleName}\Manifest.json"


# Pre POSH 6.0: ConvertFrom-Json -AsHashtable
$Manifest = @{}
$Manifest_obj = Get-Content $ManifestJsonFile | ConvertFrom-Json
$Manifest_obj | Get-Member -MemberType Properties | ForEach-Object { $Manifest.Add($_.Name,$Manifest_obj.($_.Name)) }

$Manifest.Copyright = $Manifest.Copyright -f [DateTime]::Now.Year

# Create Temp Dir; if needed.
$New_Item = @{
    ItemType = 'Directory'
    Path     = "${PSScriptRootParent}\.temp"
    Force    = $true
}
Write-Verbose "New-Item: $($New_Item | ConvertTo-Json -Compress)"
New-Item @New_Item

# Remove-Module; if exists ...
# Prevents issues in dev ...
Remove-Module $thisModuleName -ErrorAction 'SilentlyContinue'

function Invoke-PesterTestCleaup
{
    Invoke-DscCleanup

    Remove-Item -LiteralPath "${DSCModulePath}\${thisModuleName}" -Force -ErrorAction 'SilentlyContinue'
    $env:PSModulePath = $script:PSModulePathORIG
}

function Invoke-DscCleanup
{
    #Remove all mof files (pending,current,backup,MetaConfig.mof,caches,etc)
    Remove-Item 'C:\windows\system32\Configuration\*.mof*' -Force -ErrorAction 'Ignore'
    #Kill the LCM/DSC processes
    Get-Process 'wmi*' | Where-Object { $_.modules.ModuleName -like "*DSC*" } | Stop-Process -Force
}

Describe $thisModuleName {
    AfterEach {
        # Slow things down a little to help prevent build failures that work after a retry.
        if ($env:CI)
        {
            Start-Sleep -Seconds 5
        }
        else
        {
            Start-Sleep -Seconds 1
        }
    }



    Context 'Script Analyzer' {
        if (-not (Get-Command 'Invoke-ScriptAnalyzer' -ErrorAction 'SilentlyContinue'))
        {
            Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.11.0 -Force
        }

        $ScriptAnalyzerRules = Get-ScriptAnalyzerRule | Where-Object {$_.SourceName -eq 'PSDSC'}

        foreach ($Rule in $ScriptAnalyzerRules)
        {
            It "Should not return any violation for the rule : $($Rule.RuleName)" {
                Invoke-ScriptAnalyzer -Path "${PSScriptRootParent}\${thisModuleName}\${thisModuleName}.schema.psm1" -IncludeRule $Rule.RuleName | Should BeNullOrEmpty
            }
        }
    }



    Context 'Class Available' {
        It 'Module Available' {
            Get-Module -Name $Manifest.ModuleName -Refresh -ListAvailable -ErrorAction 'SilentlyContinue' | Should Not BeNullOrEmpty
        }

        It 'Module Count' {
            (Get-Module -Name $Manifest.ModuleName -Refresh -ListAvailable -ErrorAction 'SilentlyContinue').Count | Should Be 1
        }

        It 'DscResource' {
            Get-DscResource $Manifest.ResourceName -ErrorAction 'SilentlyContinue' | Should Not BeNullOrEmpty
        }

        It 'DscResource Name' {
            (Get-DscResource $Manifest.ResourceName -ErrorAction 'SilentlyContinue').Name | Should Be $Manifest.ResourceName
        }

        It 'DscResource ResourceType' {
            (Get-DscResource $Manifest.ResourceName -ErrorAction 'SilentlyContinue').ResourceType | Should Be $Manifest.ResourceName
        }

        It 'DscResource Version Major' {
            (Get-DscResource $Manifest.ResourceName -ErrorAction 'SilentlyContinue').Version.Major | Should Be $(& "${PSScriptRootParent}\.build\version.ps1").Major
        }

        It 'DscResource Version Minor' {
            (Get-DscResource $Manifest.ResourceName -ErrorAction 'SilentlyContinue').Version.Minor | Should Be $(& "${PSScriptRootParent}\.build\version.ps1").Minor
        }
    }



    foreach ($example in (Get-ChildItem "${PSScriptRootParent}\Examples\${Examples}").FullName)
    {
        Invoke-DscCleanup

        Context "Configuration: ${example}" {
            . $example

            It 'Build Configuration' {
                { Demo_Configuration } | Should Not Throw
            }

            It 'Build Configuration Type' {
                Demo_Configuration | Should BeOfType 'System.IO.FileInfo'
            }

            It 'Apply Configuration' {
                { Start-DscConfiguration "${PSScriptRootParent}\Demo_Configuration" -Wait -Force -ErrorAction 'Stop' } | Should Not Throw
            }

            $tested = Test-DscConfiguration "${PSScriptRootParent}\Demo_Configuration" -ErrorAction 'Ignore'
            It 'Test Configuration' {
                { Test-DscConfiguration "${PSScriptRootParent}\Demo_Configuration" -ErrorAction 'Stop' } | Should Not Throw
            }

            It 'Test Configuration In Desired State: True' {
                # We have applied the Configuration, so this should be true.
                $tested.InDesiredState | Should Be $TRUE
            }
        }

        Remove-DscConfigurationDocument -Stage Current
    }
}

if ($CleanUp)
{
    Invoke-PesterTestCleaup
}