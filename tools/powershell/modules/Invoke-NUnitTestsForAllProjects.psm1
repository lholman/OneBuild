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
	Invoke-NUnitTestsForProject
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(Mandatory = $False )]
				[string]
				$basePath,		
			[Parameter(Mandatory = $False )]
				[string]$nUnitPath,
			[Parameter(Mandatory = $False )]
				[string]$searchString = "test"			
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				$path = Confirm-Path -basePath $basePath
				if ($path -eq 1) { return 1}
				
				$nUnitPath = "$path\packages\NUnit.Runners.2.6.3\tools\nunit-console.exe"
				
				#Our convention: If it's within any bin folder underneath the current folder, has 'test' in the filename (and in the direcotry name) and is a '.dll' then we'll try and run it with NUnit.
				$allTestAssemblyPaths = Get-ChildItem $path -Recurse | Where-Object {$_.Extension -eq '.dll'} | Where-Object {$_.Name -like "*$searchString*"} | Where-Object {$_.Directory -like "*$searchString*"} | Where-Object {$_.FullName -notlike "*\obj\*"} | Where-Object {$_.Name -notlike "*nunit*"} | foreach {$_.FullName}
				
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
				
				if (Test-Path "$path\TestResult_$($searchString)*.xml")
				{
					Write-Warning "Removing all previous test result file(s) matching: $path\TestResult*.xml"
					Remove-Item "$path\TestResult_$($searchString)*.xml" -Force -ErrorAction SilentlyContinue
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

function Confirm-Path {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$basePath			
		)	
	Import-Module "$PSScriptRoot\Get-Path.psm1"
	$path = Get-Path -path $basePath
	Remove-Module Get-Path
	return $path
}

Export-ModuleMember -Function Invoke-NUnitTestsForAllProjects