<#
    .Synopsis
        

    .Description
        

    .Parameter Ensure
        Indicates if the key and value exist. To ensure that they do, set this property to "Present". To ensure that they do not exist, set the property to "Absent". The default value is "Present".

    .Parameter Key
        Indicates the path of the registry key for which you want to ensure a specific state. This path must include the hive.

    .Parameter NoForce
        Will not apply `-Force` to the action. Will also not silently continue if an errors arise; instead, will stop.

    .Example
        RegistryPlus Remove_Key
        {
            Ensure = 'Absent'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Test'
        }

    .Link
        https://github.com/UNT-CAS/RegistryPlusDsc

    .Notes
        https://github.com/UNT-CAS/RegistryPlusDsc/wiki#notes
#>
Configuration RegistryPlus
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [string]
        $Ensure = 'Present',

        [Parameter()]
        [string]
        $Key,

        [Parameter()]
        [string[]]
        $AllowedValueNames,

        [Parameter()]
        [string[]]
        $DependsOn
    )
    Write-Verbose "[RegistryPlusDsc RegistryPlus] Bound Parameters: $($PSBoundParameters | ConvertTo-Json -Compress)"


    $Properties = @{
        Ensure              = $Ensure               # 1 = Present; 0 = Absent
        Key                 = $Key                  # 2
        AllowedValueNames   = $AllowedValueNames    # 4
        DependsOn           = $DependsOn            # 8
    }
    $PropertyBitmask = Get-RegistryPlusPropertyBitmask -Properties $Properties

    switch ($PropertyBitmask) {
        {0..1 -contains $_} {
            Write-Verbose "[RegistryPlusDsc RegistryPlus] Bor(${ParamameterBor}): Only Provided Ensure"
            Write-Warning "[RegistryPlusDsc RegistryPlus] Bor(${ParamameterBor}): Ensure what?"
            continue
        }

        {2..3 -contains $_} {
            Write-Verbose "[RegistryPlusDsc RegistryPlus] Bor(${ParamameterBor}): Key Absent/Present"
            $Edit_RegistryPlusKey = @{
                InstanceName = $InstanceName
                Ensure       = $Ensure
                Key          = $Key
            }
            $DscSplattedResource = Edit-RegistryPlusKey @Edit_RegistryPlusKey
            break
        }

        {4..5 -contains $_} {
            Write-Verbose "[RegistryPlusDsc RegistryPlus] Bor(${ParamameterBor}): Only AllowedValueNames and possibly Ensure Provided"
            Write-Warning "[RegistryPlusDsc RegistryPlus] Bor(${ParamameterBor}): When supplying AllowedValueNames, a Key must be provided."
            continue
        }

        6 {
            Write-Verbose "[RegistryPlusDsc RegistryPlus] Bor(${ParamameterBor}): AllowedValueNames, Key, Ensure=Absent"
            Write-Warning "[RegistryPlusDsc RegistryPlus] Bor(${ParamameterBor}): When supplying AllowedValueNames and a Key, Ensure=Absent prevents anything from happening."
            continue
        }

        {7..8 -contains $_} {
            Write-Verbose "[RegistryPlusDsc RegistryPlus] Bor(${ParamameterBor}): AllowedValueNames, Key, Ensure=Present"
            $Remove_RegistryPlusExcessValueNames = @{
                InstanceName      = $InstanceName
                Key               = $Key
                AllowedValueNames = $Key
            }
            if ($PropertyBitmask -band 8)
            {
                $Remove_RegistryPlusExcessValueNames.DependsOn = $DependsOn
            }

            $DscSplattedResource = Remove-RegistryPlusExcessValueNames @Remove_RegistryPlusExcessValueNames
            break
        }

        default {
            Throw [System.InvalidOperationException] "[RegistryPlusDsc RegistryPlus] Bor(${ParamameterBor}): Unexpected Parameter Combination: $($Parameters | ConvertTo-Json -Compress)"
        }
    }

    if ($DscSplattedResource)
    {
        $DscSplattedResource.Invoke()
    }
}