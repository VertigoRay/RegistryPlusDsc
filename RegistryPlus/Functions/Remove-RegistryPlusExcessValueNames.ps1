<#
    .Synopsis
        Remove undesired registry values from a registry key.

    .Description
        This will remove all of the underied registry value names from under a registry key; non-recursively.

    .Parameter InstanceName
        The name of the RegistryPlus resource instance.

    .Parameter Ensure
        Indicates if the key and value exist. To ensure that they do, set this property to "Present". To ensure that they do not exist, set the property to "Absent". The default value is "Present".

    .Parameter Key
        Indicates the path of the registry key for which you want to ensure a specific state. This path must include the hive.

    .Example
        Remove-RegistryPlusExcessValueNames -InstanceName 'Remove_Excess_Values' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\TestKey2\C:/Program Files (x86)/' -AllowedValueNames = @('My Value', 'Other Value')

    .Link
        https://github.com/UNT-CAS/RegistryPlusDsc/wiki/Remove-Excess-ValueNames-From-Reg-Key

#>
function Remove-RegistryPlusExcessValueNames
{
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param(
        [Parameter(Mandarory = $true)]
        [string]
        $InstanceName
        ,
        [Parameter(Mandarory = $true)]
        [string]
        $Key
        ,
        [Parameter()]
        [array]
        $AllowedValueNames
        ,
        [Parameter()]
        [string[]]
        $DependsOn
    )
    Write-Verbose "[RegistryPlusDsc Get-RegistryPlusParameterBor] Bound Parameters: $($PSBoundParameters | ConvertTo-Json -Compress)"


    $Get_DscSplattedResource = @{
        ResourceName = 'Script'
        ExecutionName = $InstanceName
        Usings = @{
            RegKey              = (ConvertTo-RegistryPlusKey -Key $Key)
            AllowedValueNames   = $AllowedValueNames
        }
        Properties = @{
            GetScript = {
                $Key = Get-Item -LiteralPath $using:RegKey
                $ValueHashtable = @{}

                foreach ($Value in $Key.Property)
                {
                    $ValueHashtable.Add($Value, $Key.GetValue($Value))
                }

                return @{ Result = ($ValueHashtable | Out-String).Trim() }
            }
            SetScript = {
                $Key = Get-Item -LiteralPath $using:RegKey
                $NotAllowedValues = $Key.Property | Where-Object{ $using:AllowedValueNames -notcontains $_ }

                foreach ($Value in $NotAllowedValues)
                {
                    Remove-ItemProperty -LiteralPath $using:RegKey -Name $Value -Force
                }
            }
            TestScript = {
                $Key = Get-Item -LiteralPath $using:RegKey
                $NotAllowedValues = $Key.Property | Where-Object{ $using:AllowedValueNames -notcontains $_ }

                if ($NotAllowedValues.Count -gt 0)
                {
                    return $false
                }
                else
                {
                    return $true
                }
            }
            DependsOn = $DependsOn
        }
        NoInvoke = $true
    }
    return Get-DscSplattedResource @Get_DscSplattedResource
}