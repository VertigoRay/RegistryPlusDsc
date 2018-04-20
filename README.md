[![Build status](https://ci.appveyor.com/api/projects/status/armotrsuydsjhop2?svg=true)](https://ci.appveyor.com/project/VertigoRay/registryplusdsc)
[![codecov](https://codecov.io/gh/UNT-CAS/RegistryPlusDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/UNT-CAS/RegistryPlusDsc)

PowerShell DSC Composite Resource the fills the void where the [native Registry resource](https://docs.microsoft.com/en-us/powershell/dsc/registryresource) is lacking.

This Composite Resource will not attempt to replicate any functionality that's built-in to the [native Registry resource](https://docs.microsoft.com/en-us/powershell/dsc/registryresource).
We will only attempt to extend functionality when submitted feature requests are taking too long to implement or have been rejected.
Please feel free to request functionality that you would like to see streamlined.

# Detailed Usage

If you want to do something basic, like manage the data in a registry value, this composite resource won't do it. More importantly, it never will; use [Registry](https://docs.microsoft.com/en-us/powershell/dsc/registryresource):

```powershell
Registry 7Zip_FastCompression
{
    Key = 'HKLM:\Software\Microsoft\7-Zip'
    ValueName = 'FastCompression'
    ValueType = 'DWORD'
    ValueData = 1
}
```

However, if you want to do something more advanced that [Registry](https://docs.microsoft.com/en-us/powershell/dsc/registryresource) can't currently handle; use **RegistryPlus**. [See the wiki for more details ...](https://github.com/UNT-CAS/RegistryDsc/wiki)

# Installation

This is a Composite Resource; which means you do not need to install this on every node that you manage.
This Composite Resource only needs to be installed on your development and build machines.

```powershell
Install-Module -Name 'RegistryPlusDsc'
```

# Quick Example

Remove a Registry Key:

```powershell
RegistryPlus Remove_Key
{
    Ensure = 'Absent'
    Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Test'
}
```

This is doable, with [Registry](https://docs.microsoft.com/en-us/powershell/dsc/registryresource). However, I believe it feels a bit clunky and [have asked for the rogue `ValueName` to be removed](https://github.com/PowerShell/PSDscResources/issues/101). Here's how you would do it with [Registry](https://docs.microsoft.com/en-us/powershell/dsc/registryresource):

```powershell
Registry Remove_Key
{
    Ensure = 'Absent'
    Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Test'
    ValueName = ''
}
```