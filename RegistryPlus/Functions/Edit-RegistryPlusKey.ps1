<#
    .Synopsis
        Adds/Removes the supplied Registry Key.

    .Description
        This will convert a simpler syntax to a slightly more clunky Registry syntax for adding/removing registry keys.

    .Parameter InstanceName
        The name of the RegistryPlus resource instance.

    .Parameter Ensure
        Indicates if the key and value exist. To ensure that they do, set this property to "Present". To ensure that they do not exist, set the property to "Absent". The default value is "Present".

    .Parameter Key
        Indicates the path of the registry key for which you want to ensure a specific state. This path must include the hive.

    .Example
        Edit-RegistryPlusKey -InstanceName 'Add_This_Key' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/'

    .Example
        Edit-RegistryPlusKey -InstanceName 'Remove_This_Key' -Ensure 'Absent' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/'

    .Link
        https://github.com/UNT-CAS/RegistryPlusDsc/wiki/Add-Reg-Key

#>
function Edit-RegistryPlusKey {
    [CmdletBinding()]
    [OutputType([[scriptblock]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $InstanceName,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [string]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [string]
        $Key
    )
    Write-Verbose "[RegistryPlusDsc Edit-RegistryPlusKey] Bound Parameters: $($PSBoundParameters | ConvertTo-Json -Compress)"


    $Get_DscSplattedResource = @{
        ResourceName = 'Registry'
        ExecutionName = $InstanceName
        Properties = @{
            Ensure      = $Ensure
            Key         = (ConvertTo-RegistryPlusKey -Key $Key)
            ValueName   = '' # Empty ValueName targets Key
        }
        NoInvoke = $true
    }
    return Get-DscSplattedResource @Get_DscSplattedResource
}