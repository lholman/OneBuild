$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "Compress-FilesFromPath input validation" {		
		Context "When module is invoked with an empty path parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$result = ""
		try {
			Compress-FilesFromPath -path ""
		}
		catch {
			$result = "$_.Exception.Message"
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a terminating error" {
			$result | Should Match "Cannot validate argument on parameter 'path'"
		}		
	}
	
	Context "When module is invoked with an empty archiveName parameter" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = $TestDrive

		$result = ""
		try {
			Compress-FilesFromPath -basePath $testBasePath -archiveName ""
		}
		catch {
			$result = "$_.Exception.Message"
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a terminating error" {
			$result | Should Match "Cannot validate argument on parameter 'archiveName'"
		}		
	}	

	Context "When archiveName parameter seems to contain a file extension" {
		
		Import-Module "$baseModulePath\$sut"

		$testBasePath = $TestDrive

		$result = ""
		try {
			Compress-FilesFromPath -basePath $testBasePath -archiveName "myarchive.zip"
		}
		catch {
			$result = "$_.Exception.Message"
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a terminating error" {
			$result | Should Match "Cannot validate argument on parameter 'archiveName'"
		}		
	}		

	Context "When path parameter contains NO file(s) to compress" {
		
		Import-Module "$baseModulePath\$sut"
		$testBasePath = $TestDrive
		
		Mock -ModuleName $sut Compress-Files {} 
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -eq "Searching for files to compress within path: $testBasePath"
        }							

		$result = ""
		try {
			Compress-FilesFromPath -path $testBasePath -archiveName "myarchive"
		}
		catch {
			$result = "$_"
		}
		finally {
			Remove-Module $sut
		}

		It "Should not call Compress-Files as there are no files" {
            Assert-MockCalled Compress-Files -ModuleName $sut -Times 0
        }		
		
		It "Should write a descriptive message and error" {
			Assert-VerifiableMocks
		}

        It "Exits the module with an error" {
			$result | Should Be "No files found within the path: $testBasePath, exiting without generating archive file."			
        }	
	}
}

Describe "Compress-FilesFromPath" {	

	Context "When path parameter contains one file to compress" {
		
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "testfile.txt" -Path $TestDrive -ItemType File
		$testBasePath = $TestDrive

		Mock -ModuleName $sut Compress-Files {return 0} -Verifiable			
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -eq "Searching for files to compress within path: $testBasePath"
        }
		
		$error.Clear() #We clear the PowerShell $error variable here so we can asserts its value later
		$result = $null
		try {
			Compress-FilesFromPath -path $testBasePath -archiveName "myarchive"
		}
		catch {
			$result = "$_.Exception"
		}
		finally {
			Remove-Module $sut
		}

		It "Should write a descriptive message" {
			Assert-VerifiableMocks
		}		
		
		It "Should call Compress-Files once to compress files" {
            Assert-MockCalled Compress-Files -ModuleName $sut -Times 1
        }		
        It "Exits the module with no terminating or non-terminating errors" {
            $error.Count | Should Be 0  #Non-terminating errors from Write-Error
			$result | Should Be $null	#Terminating errors using throw
        }		
	}
}

Describe "Compress-FilesFromPath" {	

	Context "When file(s) are compressed successfully" {
		
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "testfile.txt" -Path $TestDrive -ItemType File
		$testBasePath = $TestDrive

		Mock -ModuleName $sut Confirm-FilesInPath {return $True} -Verifiable			
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -eq "Compressing all folder(s)/file(s) recursively from path: $testBasePath in to archive: myarchive.zip"
        }
		Mock -ModuleName $sut Write-Host {} -Verifiable -ParameterFilter {
            $Object -like "*Everything is Ok"
        }		
		
		$error.Clear() #We clear the PowerShell $error variable here so we can asserts its value later
		$result = $null
		try {
			Compress-FilesFromPath -path $testBasePath -archiveName "myarchive"
		}
		catch {
			$result = "$_"
		}
		finally {
			Remove-Module $sut
		}

		It "Should write descriptive messages" {
			Assert-VerifiableMocks
		}		
		It "Should call Confirm-FilesInPath once, finding file(s) to compress within the path" {
            Assert-MockCalled Confirm-FilesInPath -ModuleName $sut -Times 1
        }	
		It "Should create an archive file in the script root" {
			Test-Path ("$here\..\myarchive.zip")
		}
        It "Exits the module with no terminating or non-terminating errors" {
            $error.Count | Should Be 0  #Non-terminating errors from Write-Error
			$result | Should Be $null	#Terminating errors using throw
        }		
	}
}

Describe "Compress-FilesFromPath non-terminating error" {	

	Context "When 7Zip throws a non-terminating error whilst compressing file(s)" {
		
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "testfile.txt" -Path $TestDrive -ItemType File
		$testBasePath = $TestDrive

		Mock -ModuleName $sut Confirm-FilesInPath {return $True} -Verifiable			
		Mock -ModuleName $sut Compress-Files {return 1} -Verifiable			

		$error.Clear()
		$result = ""
		try {
			Compress-FilesFromPath -path $testBasePath -archiveName "myarchive"
		}
		catch {
			$result = "$_"
		}
		finally {
			Remove-Module $sut
		}

		It "Should write descriptive messages" {
			Assert-VerifiableMocks
		}		
		It "Should call Confirm-FilesInPath once, finding file(s) to compress within the path" {
            Assert-MockCalled Confirm-FilesInPath -ModuleName $sut -Times 1
        }	
        It "Exits the module with a non-terminating error" {
			$error[0].Exception | Should Be "Microsoft.PowerShell.Commands.WriteErrorException: Whilst generating 7Zip archive on path $testBasePath, 7za.exe exited with a non-terminating exit code: 1. Meaning from 7-Zip: Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed"
			$error.Count | Should Be 1
			#So as not to show the Write-Error in the test execution we could mock Test-Error and make an assumption $error is populated correctly, seeing as it's not really what we're attempting to test. The above is more implementation that should be used within the main .build.ps1 Invoke-Build script.
        }		
	}	
}

Describe "Compress-FilesFromPath terminating error" {	

	Context "When 7Zip throws a terminating error whilst compressing file(s)" {
		
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "testfile.txt" -Path $TestDrive -ItemType File
		$testBasePath = $TestDrive

		Mock -ModuleName $sut Confirm-FilesInPath {return $True} -Verifiable			
		Mock -ModuleName $sut Compress-Files {return 2} -Verifiable			

		$error.Clear()
		$result = ""
		try {
			Compress-FilesFromPath -path $testBasePath -archiveName "myarchive"
		}
		catch {
			$result = "$_"
		}
		finally {
			Remove-Module $sut
		}

		It "Should write descriptive messages" {
			Assert-VerifiableMocks
		}		
		It "Should call Confirm-FilesInPath once, finding file(s) to compress within the path" {
            Assert-MockCalled Confirm-FilesInPath -ModuleName $sut -Times 1
		}
        It "Exits the module with a terminating error" {
			$result | Should Be "Whilst generating 7Zip archive on path $testBasePath, 7za.exe exited with a terminating exit code: 2. Meaning from 7-Zip: Fatal error" 
        }		
	}	
}


$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


