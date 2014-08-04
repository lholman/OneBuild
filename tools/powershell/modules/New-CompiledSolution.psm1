function New-CompiledSolution{
<#
 
.SYNOPSIS
    Executes MSBuild.exe to Clean and Rebuild a Visual Studio solution file to generate compiled .NET assemblies for a target configuration (Debug|Release etc).
.DESCRIPTION
	Executes MSBuild.exe to Clean and Rebuild a Visual Studio solution file to generate compiled .NET assemblies. Solution file to build is identified by convention, also allows optional passing of a target configuration (Debug|Release etc).
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER msBuildPath
	Optional. The full path to msbuild.exe.  Defaults to 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe'.	
.PARAMETER configMode
	Optional. The build Configuration to be passed to msbuild during compilation. Examples include 'Debug' or 'Release'.  Defaults to 'Release' 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe'.	
.PARAMETER nuGetPath
	Optional. The full path to the nuget.exe console application.  Defaults to 'packages\NuGet.CommandLine.2.7.3\tools\nuget.exe', i.e. the bundled version of NuGet.	
.EXAMPLE 
	Import-Module New-CompiledSolution
	Import the module
.EXAMPLE	
	Get-Command -Module New-CompiledSolution
	List available functions
.EXAMPLE
	New-CompiledSolution 
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
				Position = 1,
				Mandatory = $False )]
				[string]$nuGetPath				
			)			
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				Try 
				{
					#Set the basePath to the calling scripts path (using Resolve-Path .)
					$basePath = Resolve-Path .
					if ($nuGetPath -eq "")
					{
						#Set our default value for nuget.exe
						$nuGetPath = "$basePath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
					}
					
					Write-Host "Using ""Configuration"" mode $configMode. Modify this by passing in a value for ""$configMode"""

					#Our convention, build the first solution file we find (ordered alphabetically) in the current folder. 
					$solutionFile = Get-ChildItem $basePath | Where-Object {$_.Extension -eq '.sln'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1
					
					Write-Host "Restoring NuGet packages for ""$solutionFile""."
					exec { & $nugetPath restore $solutionFile }
					Write-Host "Building ""$solutionFile"" in ""$configMode"" mode."
					exec { & $msbuildPath $solutionFile /t:ReBuild /t:Clean /p:Configuration=$configMode /p:PlatformTarget=AnyCPU /m }
					
				}
				catch [Exception] {
					throw "Error compiling solution file: $solutionFile. `r`n $_.Exception.ToString()"
				}
		}
}
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUypPwPepdy5G6cewfaHIgIIXN
# WPqgggI9MIICOTCCAaagAwIBAgIQBwSeB23pR7ROOOYNHq4avjAJBgUrDgMCHQUA
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
# FPAbJp77VK1FhxgybjRci1ePJCfMMA0GCSqGSIb3DQEBAQUABIGAUkwPdIBU7Yo1
# T5VLD3eCI0/r5uIh55ZVZO8TL3z3reNkBgaSPM4WUCu1dbYs1aG2rFdnAz5KC6rh
# A9TmjGccMlD3pG/feolRYKO/hgp61+FGer/0T19c8q5PmXp3V5fMfthKd2qImc3K
# +sZ36b5vpkAWs9RZrC8INZ7RmJbOKCE=
# SIG # End signature block
