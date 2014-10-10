$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "Compress-FilesFromPath" {		
		Context "When module is invoked with an empty path parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$result = ""
		try {
			$result = Compress-FilesFromPath -path ""
		}
		catch {
			$result = "$_.Exception.Message"
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should throw a terminating exception" {
			$result | Should Match "Cannot validate argument on parameter 'path'"
		}		
	}
	
	Context "When module is invoked with an empty archiveName parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = $TestDrive

		$result = ""
		try {
			$result = Compress-FilesFromPath -basePath $testBasePath -archiveName ""
		}
		catch {
			$result = "$_.Exception.Message"
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should throw a terminating exception" {
			$result | Should Match "Cannot validate argument on parameter 'archiveName'"
		}		
	}	

	Context "When archiveName parameter seems to contain a file extension" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = $TestDrive

		$result = ""
		try {
			$result = Compress-FilesFromPath -basePath $testBasePath -archiveName "myarchive.zip"
		}
		catch {
			$result = "$_.Exception.Message"
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should throw a terminating exception" {
			#Write-Host $result
			$result | Should Match "Cannot validate argument on parameter 'archiveName'"
		}		
	}		
}

Describe "Compress-FilesFromPath" {	
	Context "When path parameter contains no files to compress" {
		
		Import-Module "$baseModulePath\$sut"

		#New-Item -Name "testfile.txt" -Path $TestDrive -ItemType File
		$testBasePath = $TestDrive
		
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -eq "Searching for files to compress within path: $testBasePath"
        }							
		
		Mock -ModuleName $sut Write-Error {} -Verifiable -ParameterFilter {
            $Message -eq "No files found with the path: $testBasePath, exiting without generating archive file."
        }							
		
		$result = ""
		try {
			$result = Compress-FilesFromPath -path $testBasePath -archiveName "myarchive"
		}
		catch {
			$result = "$_.Exception.Message"
		}
		finally {
			Remove-Module $sut
		}

		It "Writes a descriptive message and error" {
			Assert-VerifiableMocks
		}

        It "Exits module with code 1" {
            $result | Should Be 1
        }	
	}
}

Describe "Compress-FilesFromPath" {		
	Context "When path parameter contains one file to compress" {
		
		Import-Module "$baseModulePath\$sut"

		New-Item -Name "testfile.txt" -Path $TestDrive -ItemType File
		$testBasePath = $TestDrive

		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -eq "Searching for files to compress within path: $testBasePath"
        }							
		
		Mock -ModuleName $sut Compress-Files { }
		
		$result = ""
		try {
			$result = Compress-FilesFromPath -path $testBasePath -archiveName "myarchive"
		}
		catch {
			$result = "$_.Exception.Message"
		}
		finally {
			Remove-Module $sut
		}

		It "Writes a descriptive message" {
			Assert-VerifiableMocks
		}

		It "Should call Compress-Files to zip the files within the supplied path" {
            Assert-MockCalled Compress-Files -ModuleName $sut -Times 1
        }
		
        It "Exits module with code 0" {
            $result | Should Be 0
        }		
	}		
}


$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


