function Invoke-NUnitTestsForAllProjects{
<#
 
.SYNOPSIS
    Executes all NUnit tests for compiled .NET assemblies matching a defined naming convention.
.DESCRIPTION
    Executes all NUnit tests for compiled .NET assemblies matching a defined naming convention, optionally allowing you to specify a basePath to recursively find assemblies within and the path to the NUnit console executable.
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER basePath
	Optional. The root path to search recursively for matching .NET test assemblies.  Defaults to the calling scripts path.	
.PARAMETER nUnitPath
	Optional. The full path to nunit-console.exe.  Defaults to 'packages\NUnit.Runners.2.6.3\tools\nunit-console.exe', i.e. the bundled version of NUnit.
.PARAMETER searchString
	Optional. Defines the string to match within assembly filenames, determining which assemblies are executed. Defaults to 'test'.
.EXAMPLE 
	Import-Module Invoke-NUnitTestsForProject
	Import the module
.EXAMPLE	
	Get-Command -Module Invoke-NUnitTestsForProject
	List available functions
.EXAMPLE
	Invoke-NUnitTestsForProject -basePath "\"
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(
				Position = 0,
				Mandatory = $False )]
				[string]$basePath,		
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[string]$nUnitPath,
			[Parameter(
				Position = 2,
				Mandatory = $False )]
				[string]$searchString = "test"			
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				
				#Set the basePath to the calling scripts path (using Resolve-Path .)
				$basePath = Resolve-Path .
				$nUnitPath = "$basePath\packages\NUnit.Runners.2.6.3\tools\nunit-console.exe"
				
				#Our convention: If it's within any bin folder underneath the current folder, has 'test' in the filename (and in the direcotry name) and is a '.dll' then we'll try and run it with NUnit.
				$allTestAssemblyPaths = Get-ChildItem $basePath -Recurse | Where-Object {$_.Extension -eq '.dll'} | Where-Object {$_.Name -like "*$searchString*"} | Where-Object {$_.Directory -like "*$searchString*"} | Where-Object {$_.FullName -notlike "*\obj\*"} | Where-Object {$_.Name -notlike "*nunit*"} | foreach {$_.FullName}
				
				if ($allTestAssemblyPaths -eq $null)
				{
					Write-Warning "No assemblies found matching the test naming convention ($searchString), exiting without executing tests."
					Return 0
				}
				
				$testAssemblyPaths = @()
				#NOTE: This is unfortunately a little overly complex as a number of test projects (dh.ATCApi.Specification.csproj) within some solutions (e.g. ATCApi.sln) have dependencies on common methods in other test projects (e.g. dh.ATCApi.Tests.Common.csproj and dh.ATCApi.TestBank.csproj). For that reason we have to filter out any assemblies that match our pattern that are in other test projects bin folders due to being referenced.
				ForEach($testAssemblyPath in $allTestAssemblyPaths) 
				{ 
					$fileName = Split-Path $testAssemblyPath -Leaf
					$fileName = [IO.Path]::GetFileNameWithoutExtension($fileName)
					$projectName = Split-Path $testAssemblyPath -Parent | ForEach {$splitName = $_.Split('\'); [String]::Join('\', $splitName[($splitName.Count -2)..($splitName.Count -2)])}
					
					if ($fileName -eq $projectName)
					{
						Write-Debug "Adding: $testAssemblyPath"
						$testAssemblyPaths += $testAssemblyPath
					}
				}
				
				if (Test-Path "$basePath\TestResult_$($searchString)*.xml")
				{
					Write-Warning "Removing all previous test result file(s) matching: $basePath\TestResult*.xml"
					Remove-Item "$basePath\TestResult_$($searchString)*.xml" -Force -ErrorAction SilentlyContinue
				}
				
				$i = 1	
				foreach($testAssemblyPath in $testAssemblyPaths)
				{
													
					$testResultFileName = "TestResult_$($searchString)_$i.xml"

					Try 
					{	
							Write-Host "Executing Tests for test assembly: $testAssemblyPath"
							Write-Debug "Using NUnit-Console Path: $nUnitPath and result file: $testResultFileName"
							& $nUnitPath $testAssemblyPath /result=$testResultFileName
							
					}
					catch [Exception] {
						throw "Error executing Tests for supplied assembly: $testAssemblyPath using NUnit from: $nUnitPath `r`n $_.Exception.ToString()"
					}
					finally {
						
						$i++
					}
				}
				
		}
}
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKAPsWy5uRscFZaGn9hfRldvL
# XfmgggI9MIICOTCCAaagAwIBAgIQBwSeB23pR7ROOOYNHq4avjAJBgUrDgMCHQUA
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
# FJtOKFSevoCOKs52QjI5H1fF9fnMMA0GCSqGSIb3DQEBAQUABIGAgAVKTS1vhyTx
# LNp3fXPBY5Tu7jlZcPF3c1QE/hDB9Q2z6djSfnxRI7PVDtW6qDfbadqPAxTRSeX+
# aP3m2HwDGxy6rsWkcsT4k3+m8z+Swb48ukHibYhYLBfL6aLO8STJHqI5hHgJE1iG
# RPqbnPnLdqd0+9vqAPAQGcEVzHXY1j0=
# SIG # End signature block
