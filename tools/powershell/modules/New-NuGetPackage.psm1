function New-NuGetPackage{
<#
 
.SYNOPSIS
    Given the a path to a NuGet spec file will create a new versioned NuGet package.
.DESCRIPTION
    Given the a path to a NuGet spec file will create a new versioned NuGet package, optionally allowing you to specify a version number and path to the NuGet console executable.

.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER versionNumber
	Optional. The version number to stamp the resultant NuGet package with.
.PARAMETER nuGetPath
	Optional. The full path to the nuget.exe console application.  Defaults to 'packages\NuGet.CommandLine.2.7.3\tools\nuget.exe', i.e. the bundled version of NuGet.
.PARAMETER includeSymbolPackage
	Optional. If included, instructs the NuGet executable to include the -symbols switch, generating a matching symbols package containing the 'pdb's'. Defaults to $false.
.EXAMPLE 
	Import-Module New-NuGetPackage
	Import the module
.EXAMPLE	
	Get-Command -Module New-NuGetPackage
	List available functions
.EXAMPLE
	New-NuGetPackage -specFilePath 
	Execute the module
#>
	[cmdletbinding()]
		Param(		
			[Parameter(
				Position = 0,
				Mandatory = $False )]
				[string]$versionNumber,
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[string]$nuGetPath,
			[Parameter(
				Position = 2,
				Mandatory = $False )]
				[switch]$includeSymbolPackage					
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

				#Set the basePath to the calling scripts path (using Resolve-Path .)
				$basePath = Resolve-Path .
				if ($nuGetPath -eq "")
				{
					#Set our default value for nuget.exe
					$nuGetPath = "$basePath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
				}
				
				#Our convention, select all '.nuspec' files in the current folder and create the NuGet package for each
				$specFilePaths = Get-ChildItem $basePath | Where-Object {$_.Extension -eq '.nuspec'} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object

				if ($specFilePaths -eq $null)
				{
					Write-Warning "No NuGet '.nuspec' file found matching the packaging naming convention, exiting without NuGet packaging."
					Return 0
				}
				
				if ((Test-Path -Path "$basePath\BuildOutput") -eq $True) { Remove-Item -Path "$basePath\BuildOutput" -Force	-Recurse}
				New-Item -ItemType directory -Path "$basePath\BuildOutput" -force
					
				Try 
				{
					ForEach ($specFilePath in $specFilePaths)
					{	
					
						if ($includeSymbolPackage)
						{
							& $nuGetPath pack $specFilePath -Version $versionNumber -OutputDirectory "BuildOutput" -Symbols
						}
						else
						{
							& $nuGetPath pack $specFilePath -Version $versionNumber -OutputDirectory "BuildOutput"	
						}

					}
					
				}
				catch [Exception] {
					throw "Error executing NuGet Pack for supplied spec file: $specFilePath using NuGet from: $nuGetPath `r`n $_.Exception.ToString()"
				}
		}
}
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1gh10EthccD6WJ3oZ/7ggu4f
# BTygggI9MIICOTCCAaagAwIBAgIQBwSeB23pR7ROOOYNHq4avjAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNDAzMjcxNTM4MTJaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bvd2Vy
# U2hlbGwgVXNlcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAyCSg/wCkjDGS
# Mv7A5OLubZZCxcRW2lSRerbfN8KE1EsAD3X7E/Jy6oOaH8h7+r83744v4TUmxQ23
# 9rptO5H2NPRl6+HpCapatTGHodCLYcdV+PbnfQP19g+2VgpOuzJc1ltTF+cQbzMY
# 8aLbt2njo3jPAgIT1cEx5j/+Hd96vqUCAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwXQYDVR0BBFYwVIAQvg+wxIsvFis5+YRLK6JQfqEuMCwxKjAoBgNVBAMT
# IVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQijjs33C86o9FovTA
# 2hbxiTAJBgUrDgMCHQUAA4GBAA1qfdSfmUXeXAvocTMh3arC5I4orm6mPWK2XdyU
# WdeVWKXRHg1ZTZY54OOYVc7Yl/VH90DvyxMbsJw+seyPkygAnXRg5gbgeWIT8/lT
# lgSnCbIm1g9Qx0tRKnyuKeRgB0rQ/cQehOmmPx8IH3tpIEfWctuA/V06W94T6Ot2
# 28sEMYIBYDCCAVwCAQEwQDAsMSowKAYDVQQDEyFQb3dlclNoZWxsIExvY2FsIENl
# cnRpZmljYXRlIFJvb3QCEAcEngdt6Ue0TjjmDR6uGr4wCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FOcGL5ZF6xDMPpQIze+e/ix8mDZUMA0GCSqGSIb3DQEBAQUABIGAub/VSNtig6i1
# ODpG99ekAEtM/OBn6Uls1C9eNxc54+WcvDcWipXazcH/qgHaPbO9UEZNaqxP6DyL
# solln+gt1lj8LrU6JAS+lKPhMhtRuI1IdHxPWJnoYT4xUWR5199lme64nbj2OM6x
# LuHZhoEUCprqMe8emcp8iRIiPZYYjBI=
# SIG # End signature block
