<#
    .Synopsis
        Returns the supplied key in the format required by this Module.

    .Description
        This *should* handle any of PowerShell's Registry key formats, where the Hive is included in the Key, and return the desired Registry key format.

    .Parameter Key
        Indicates the path of the registry key for which you want to ensure a specific state. This path must include the hive.

    .Example
        PS > ConvertTo-RegistryPlusKey 'HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/'
        
        Registry::HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/

    .Example
        PS > ConvertTo-RegistryPlusKey 'HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/HKLM:/Foobear'
        
        Registry::HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/HKLM:/Foobear

    .Example
        PS > ConvertTo-RegistryPlusKey 'HKLM:\SOFTWARE\TestKey2\C:/Program Files (x86)/HKLM:/Foobear'
        
        Registry::HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/HKLM:/Foobear

    .Example
        PS > ConvertTo-RegistryPlusKey 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/'
        
        Registry::HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/

#>
function ConvertTo-RegistryPlusKey {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string]
        $Key
    )
    Write-Verbose "[RegistryPlusDsc ConvertTo-RegistryPlusKey] Bound Parameters: $($PSBoundParameters | ConvertTo-Json -Compress)"


    if ($Key.StartsWith('Registry::'))
    {
        # It appears you already know what you're doing ...
        return $Key
    }

    $RegistryDriveRoots = @{
        'HKCC:' = 'HKEY_CURRENT_CONFIG'
        'HKCR:' = 'HKEY_CLASSES_ROOT'
        'HKCU:' = 'HKEY_CURRENT_USER'
        'HKLM:' = 'HKEY_LOCAL_MACHINE'
        'HKUS:' = 'HKEY_USERS'
    }

    $KeyRoot = $Key.Split('\')[0]

    $firstIndexOfBackslash = $Path.IndexOf('\')

    if ($RegistryDriveRoots.Keys -contains $KeyRoot)
    {
        $Key = $Key -replace "(.*?)${KeyRoot}(.*)", "`$1$($RegistryDriveRoots.$KeyRoot)`$2"
    }

    return ('Registry::{0}' -f $Key)
}