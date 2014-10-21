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
            $result | Should Be "$testBasePath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
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
            $result | Should Be "$testBasePath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
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
            $result | Should Be "$testBasePath\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
        }		
	}
	
	Context "When Get-NuGetPath module is invoked with a path (-path parameter) that DOES exist" {
		
		Import-Module "$baseModulePath\$sut"
		#Here we get the TestDrive using pesters $TestDrive variable which holds the full file system location to the temporary PSDrive. 
		$testBasePath = "$TestDrive"

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
		
		It "Should set the path to the supplied path" {
            $result | Should Be "$testBasePath"
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


$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


