$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "CommonFunctions.Get-FilePath execution" {

		
	Context "When Get-FilePath module is invoked with NO path parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = Join-Path "$here" "\.." -Resolve
		$result = ""
		try {
			$result = Get-FilePath -fileName "nuget.exe"
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

	Context "When Get-FilePath module is invoked with an empty path parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = Join-Path "$here" "\.." -Resolve
		$result = ""
		try {
			$result = Get-FilePath -path "" -fileName "nuget.exe"
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

	Context "When Get-FilePath module is invoked with a null path parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = Join-Path "$here" "\.." -Resolve
		$result = ""
		try {
			$result = Get-FilePath -path $null -fileName "nuget.exe"
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

	Context "When Get-FilePath module is invoked with a path (-path parameter) that does NOT exist" {

		Import-Module "$baseModulePath\$sut"	
		$testBasePath = "$TestDrive\NonExistentPath\"
		
		$error.Clear()		
		$result = ""
		try {
			Get-FilePath -path $testBasePath -fileName "nuget.exe"
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}

		It "Exits the module with a terminating error" {
			$result | Should Be "CommonFunctions:Get-FilePath: Supplied path: '$($testBasePath)' does not exist" 
        }		
	}	

}

Describe "CommonFunctions.Get-FilePath" {
	
	Context "When there is more than one version of NuGet.Commandline installed" {

		Import-Module "$baseModulePath\$sut"
		New-Item -Name "packages" -Path $TestDrive -ItemType Directory
		New-Item -Name "NuGet.CommandLine.2.7.2" -Path "$TestDrive\packages" -ItemType Directory
		New-Item -Name "tools" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.2" -ItemType Directory		
		New-Item -Name "nuget.exe" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.2\tools" -ItemType File	
		New-Item -Name "NuGet.CommandLine.2.7.3" -Path "$TestDrive\packages" -ItemType Directory		
		New-Item -Name "tools" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.3" -ItemType Directory		
		New-Item -Name "nuget.exe" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.3\tools" -ItemType File			
		$correctPath = "$($TestDrive)\packages\NuGet.CommandLine.2.7.3\tools\nuget.exe"
		$testBasePath = "$($TestDrive)"

		$result = ""
		try {
			$result = Get-FilePath -path "$testBasePath\packages" -fileName "nuget.exe"
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should return the full path to to the highest version of NuGet.Commandline found in the solution packages folder" {
            $result | Should Be $correctPath
        }			
	}	
}


Describe "CommonFunctions.Get-FilePath" {
	
	Context "When pathContains parameter is used" {

		Import-Module "$baseModulePath\$sut"
		New-Item -Name "packages" -Path $TestDrive -ItemType Directory
		New-Item -Name "NuGet.CommandLine.2.7.2" -Path "$TestDrive\packages" -ItemType Directory
		New-Item -Name "tools" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.2" -ItemType Directory		
		New-Item -Name "nuget.exe" -Path "$TestDrive\packages\NuGet.CommandLine.2.7.2\tools" -ItemType File	
		New-Item -Name "AnotherPath.2.7.3" -Path "$TestDrive\packages" -ItemType Directory		
		New-Item -Name "tools" -Path "$TestDrive\packages\AnotherPath.2.7.3" -ItemType Directory		
		New-Item -Name "nuget.exe" -Path "$TestDrive\packages\AnotherPath.2.7.3\tools" -ItemType File			
		$correctPath = "$($TestDrive)\packages\AnotherPath.2.7.3\tools\nuget.exe"
		$testBasePath = "$($TestDrive)"

		$result = ""
		try {
			$result = Get-FilePath -path "$testBasePath\packages" -fileName "nuget.exe" -pathContains "AnotherPath" -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should return the full path containing the value provided for the pathContains parameter" {
            $result | Should Be $correctPath
        }			
	}	
}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


