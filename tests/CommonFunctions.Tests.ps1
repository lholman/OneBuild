$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "CommonFunctions.Get-NuGetPath execution" {

		
	Context "When Get-NuGetPath module is invoked with NO path parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = Join-Path "$here" "\.." -Resolve
		$result = ""
		try {
			$result = Get-NuGetPath
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should return the full path to the bundled NuGet.exe command line" {
            $result | Should Match "nuget.exe"
        }		
	}

	Context "When Get-NuGetPath module is invoked with an empty path parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = Join-Path "$here" "\.." -Resolve
		$result = ""
		try {
			$result = Get-NuGetPath -path ""
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should return the full path to the bundled NuGet.exe command line" {
            $result | Should Match "nuget.exe"
        }			
	}

	Context "When Get-NuGetPath module is invoked with a null path parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = Join-Path "$here" "\.." -Resolve
		$result = ""
		try {
			$result = Get-NuGetPath -path $null
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should return the full path to the bundled NuGet.exe command line" {
            $result | Should Match "nuget.exe"
        }		
	}

	Context "When Get-NuGetPath module is invoked with a path (-path parameter) that does NOT exist" {

		Import-Module "$baseModulePath\$sut"	
		$testBasePath = "$TestDrive\NonExistentPath\"
		
		$error.Clear()		
		$result = ""
		try {
			Get-NuGetPath -path $testBasePath 
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}

		It "Exits the module with a terminating error" {
			$result | Should Be "Supplied path: $testBasePath does not exist" 
        }		
	}	

}

Describe "CommonFunctions.Get-NuGetPath" {
	
	Context "When there is more than one version of NuGet.Commandline installed" {

		Import-Module "$baseModulePath\$sut"
		New-Item -Name "packages" -Path $TestDrive -ItemType Directory
		New-Item -Name "NuGet.CommandLine.2.7.2" -Path "$TestDrive\packages" -ItemType Directory
		New-Item -Name "tools" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.2" -ItemType Directory		
		New-Item -Name "nuget.exe" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.2\tools" -ItemType File	
		New-Item -Name "NuGet.CommandLine.2.7.3" -Path "$TestDrive\packages" -ItemType Directory		
		New-Item -Name "tools" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.3" -ItemType Directory		
		New-Item -Name "nuget.exe" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.3\tools" -ItemType File			
		$correctNugetPath = "$($TestDrive)\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
		$testBasePath = "$($TestDrive)"

		$result = ""
		try {
			$result = Get-NuGetPath -path $testBasePath
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should return the full path to to the highest version of NuGet.Commandline found in the solution packages folder" {
            $result | Should Be $correctNugetPath
        }			
	}	
}

Describe "CommonFunctions.Get-NUnitPath" {
	
	Context "When there is more than one version of NUnit.Runners installed" {

		Import-Module "$baseModulePath\$sut"
		New-Item -Name "packages" -Path $TestDrive -ItemType Directory
		New-Item -Name "NUnit.Runners.2.6.2" -Path "$TestDrive\packages" -ItemType Directory
		New-Item -Name "tools" -Path "$TestDrive\packages\NUnit.Runners.2.6.2" -ItemType Directory		
		New-Item -Name "nunit-console.exe" -Path "$TestDrive\packages\NUnit.Runners.2.6.2\tools" -ItemType File	
		New-Item -Name "NUnit.Runners.2.6.3" -Path "$TestDrive\packages" -ItemType Directory		
		New-Item -Name "tools" -Path "$TestDrive\packages\NUnit.Runners.2.6.3" -ItemType Directory		
		New-Item -Name "nunit-console.exe" -Path "$TestDrive\packages\NUnit.Runners.2.6.3\tools" -ItemType File			
		$correctNUnitPath = "$($TestDrive)\packages\NUnit.Runners.2.6.3\tools\nunit-console.exe"
		$testBasePath = "$($TestDrive)"

		$result = ""
		try {
			$result = Get-NUnitPath -path $testBasePath
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should return the full path to to the highest version of NUnit.Runners found in the solution packages folder" {
            $result | Should Be $correctNUnitPath
        }			
	}	
}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


