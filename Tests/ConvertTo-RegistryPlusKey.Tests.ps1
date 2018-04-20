[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $thisModuleName = 'RegistryPlus'
    ,
    [Parameter()]
    [string]
    $thisFunctionName = (Split-Path $MyInvocation.MyCommand.Path -Leaf).Replace('.Tests.ps1', '')
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
$ManifestJsonFile = "${PSScriptRootParent}\${thisModuleName}\Manifest.json"

$FunctionsFolder = "${PSScriptRootParent}\${thisModuleName}\Functions"
$thisFunctionPath = "${FunctionsFolder}\${thisFunctionName}.ps1"

. $thisFunctionPath


Describe $thisFunctionName {
    $TestCases = @(
        @{
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\TestKey2\C:/Program Files (x86)/'
            Result = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\TestKey2\C:/Program Files (x86)/'
        },
        @{
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\TestKey2\C:/Program Files (x86)/HKLM:/Foobear'
            Result = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\TestKey2\C:/Program Files (x86)/HKLM:/Foobear'
        },
        @{
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\TestKey2\C:/Program Files (x86)/HKLM:/Foobear'
            Result = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\TestKey2\C:/Program Files (x86)/HKLM:/Foobear'
        },
        @{
            Key = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\TestKey2\C:/Program Files (x86)/'
            Result = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\TestKey2\C:/Program Files (x86)/'
        }
    )
    It 'Testing Key: <Key>' -TestCases $TestCases {
        param($Key, $Result)
        ConvertTo-RegistryPlusKey -Key $Key | Should Be $Result
    }
}