<#
    .Synopsis
        Return the Bitmask of the results of which Properties were supplied.

    .Description
        This function will return the Bitmask of the results of which Properties were supplied to RegistryPlus.
        This allows us to easily handle complex Property combinations without having to write overly complex `if` statements.

    .Parameter Properties
        This is a hashtable of all the properties that were passed to 
        Passing $PSBoundParameters won't suffice because we need to include default values; if any.

    .Example
        $Properties = @{
            Ensure              = $Ensure               # 1 = Present; 0 = Absent
            Key                 = $Key                  # 2
            AllowedValueNames   = $AllowedValueNames    # 4
            DependsOn           = $DependsOn            # 8
        }
        $ParameterBor = Get-RegistryPlusParameterBitmask -Properties $Properties
#>
function Get-RegistryPlusPropertyBitmask {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Properties
    )
    Write-Verbose "[RegistryPlusDsc Get-RegistryPlusParameterBor] Bound Parameters: $($PSBoundParameters | ConvertTo-Json -Compress)"


    $ParameterBitmask = 0
    $ParameterBitmaskValues = @{
        EnsureAbsent        = 0     # 0000
        EnsurePresent       = 1     # 0001
        Key                 = 2     # 0010
        AllowedValueNames   = 4     # 0100
        DependsOn           = 8     # 1000
    }


    foreach ($Property in $Properties.GetEnumerator())
    {
        if ($Property.Name -eq 'Ensure')
        {
            $EnsureBitValue = if ($Property.Value -eq 'Present') { $ParameterBitmaskValues.EnsurePresent } else { $ParameterBitmaskValues.EnsureAbsent }
            $ParameterBitmask = $ParameterBitmask -bor $EnsureBitValue
        }
        else
        {
            if ($Property.Value)
            {
                $ParameterBitmask = $ParameterBitmask -bor $ParameterBitmaskValues.$($Property.Name)
            }
        }
    }


    return $ParameterBitmask
}