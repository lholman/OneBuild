function New-WebDeployPackages{
<#
 
.SYNOPSIS
    Executes MSBuild.exe to create WebDeploy Package(s) for Visual Studio Web Projects matching a defined naming convention.
.DESCRIPTION
	Executes MSBuild.exe to create WebDeploy Package(s) for Visual Studio Web Projects matching a defined naming convention., also allows optional passing of a target configuration (Debug|Release etc).
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER msBuildPath
	Optional. The full path to msbuild.exe.  Defaults to 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe'.	
.PARAMETER configMode
	Optional. The build Configuration to be passed to msbuild during compilation. Examples include 'Debug' or 'Release'.  Defaults to 'Release' 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe'.		
.PARAMETER versionNumber
	Optional. The version number to stamp the resultant WebDeploy package(s) with.	
.EXAMPLE 
	Import-Module New-WebDeployPackages
	Import the module
.EXAMPLE	
	Get-Command -Module New-WebDeployPackages
	List available functions
.EXAMPLE
	New-WebDeployPackages 
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(
				Position = 0,
				Mandatory = $False )]
				[string]$msBuildPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe",				
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[string]$configMode = "Release",
			[Parameter(
				Position = 2,
				Mandatory = $False )]
				[string]$versionNumber
			)			
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

				Write-Debug "Setting the basePath to the calling scripts path (using Resolve-Path .)"
				$basePath = Resolve-Path .

				
				Try 
				{
					Write-Host "Using ""Configuration"" mode $configMode. Modify this by passing in a value for ""$configMode"""

					#Our convention, get all *.csproj files containing "dh.RecommenderApi.Adapter.*Api.csproj" in their name (ordered alphabetically) in all sub folders.
					#This should identify all "Adapters" we want to create deployable WebDeploy packages for
					$projectFiles = Get-ChildItem . -Recurse | Where-Object {$_.Extension -eq '.csproj'} | Where-Object {$_.Name -like "dh.RecommenderApi.Adapter.*Api.csproj" } | Sort-Object $_.FullName
					
					ForEach($projectFile in $projectFiles) 
					{ 
						Write-Debug "WebDeploy packaging project: $($projectFile.BaseName) from location: $($projectFile.FullName) using config mode: $configMode"
						& msbuild "$($projectFile.FullName)" /t:Package /p:Configuration=$configMode /p:PlatformTarget=AnyCPU /p:PackageLocation="$basePath\BuildOutput\$($projectFile.BaseName).$($versionNumber).zip" /p:DeployOnBuild=false /p:DebugSymbols=false /p:DebugType=None /p:DeployTarget=Package /p:_PackageTempDir=c:\websites\temp /p:PipelineDependsOnBuild=False
						
					}
					
				}
				catch [Exception] {
					throw "Error packaging project in list of project files: $projectFiles. `r`n $_.Exception.ToString()"
				}
		}
}
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU99rJ6pTRMdQXW/JxFqNZ9cNY
# s/WgggI9MIICOTCCAaagAwIBAgIQBwSeB23pR7ROOOYNHq4avjAJBgUrDgMCHQUA
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
# FBp9Ndz3QJwHsivI2+vSF/X7is5SMA0GCSqGSIb3DQEBAQUABIGAlhkVgSAjSU1K
# 59m6qzNutEuvOfu48pnV+55lYjXAPUsPxMWrd61n/CGUyESWdtf64Theb8IBu5b0
# XAN8viRB6Xy3g/q/GVFbGh4o0Ffz1OGQbHVSThFlvZCORscqbRqElIpYHfmgarO1
# AgnzImVZGTL29WL3D7nf+y787uTPUcw=
# SIG # End signature block
