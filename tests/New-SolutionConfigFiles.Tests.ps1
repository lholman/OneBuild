$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-SolutionConfigFiles configuration" {

	Context "When there is an existing _transformedConfig folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "_transformedConfig" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\Project1\application" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\Project1\application\Child1" -Path $TestDrive -ItemType 	Directory	
		New-Item -Name "_transformedConfig\Project1\application\Child2" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\Project1\application\Child2\app.config" -Path $TestDrive -ItemType File 			
		$testBasePath = "$TestDrive"	

		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should remove the _transformedConfig folder and contents" {
            Test-Path "$testBasePath\_transformedConfig" | Should Be $false
        }
		
	}
	
	Context "When there is an existing _transformedConfig\temp folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "_transformedConfig" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\temp\Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\temp\Project1\application" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\temp\Project1\application\Child1" -Path $TestDrive -ItemType 	Directory	
		New-Item -Name "_transformedConfig\temp\Project1\application\Child2" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\temp\Project1\application\Child2\app.config" -Path $TestDrive -ItemType File 			
		$testBasePath = "$TestDrive"	

		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should remove the _transformedConfig\temp folder and contents" {
            Test-Path "$testBasePath\_transformedConfig\temp" | Should Be $false
        }

	}	

	Context "When there is configuration to transform" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config" -Path $TestDrive -ItemType Directory	
		$testBasePath = "$TestDrive"	
		Mock -ModuleName $sut Get-ProjectConfigFolders { return "$testBasePath\Project1\_config"}
		Mock -ModuleName $sut New-TransformedConfigForProjectConfigFolder { }

		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Get-ProjectConfigFolders to identify all _config folders under path" {
            Assert-MockCalled Get-ProjectConfigFolders -ModuleName $sut -Times 1
        }
		
		It "Should call New-TransformedConfigForProjectConfigFolder once" {
            Assert-MockCalled New-TransformedConfigForProjectConfigFolder -ModuleName $sut -Times 1
        }

	}
	
	Context "When there is NO configuration to transform" {
	
		Import-Module "$baseModulePath\$sut"

		Mock -ModuleName $sut Get-ProjectConfigFolders { return $null}
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "No configuration '_config' folders found, exiting without configuration  transformation."
        }
				
		try {
			New-SolutionConfigFiles -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Write a descriptive warning" {
			Assert-VerifiableMocks
		}
	}	
}

Describe "New-SolutionConfigFiles one project _config folder" {

	Context "When there is one project _config folder under the path folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config" -Path $TestDrive -ItemType Directory	
		$testBasePath = "$TestDrive"
		Mock -ModuleName $sut New-TransformedConfigForProjectConfigFolder { }
		
		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should identify one _config folder" {
            #Assert-MockCalled Get-ProjectConfigFolders -ModuleName $sut -Times 1
        }
		
		It "Should call New-TransformedConfigForProjectConfigFolder once" {
            Assert-MockCalled New-TransformedConfigForProjectConfigFolder -ModuleName $sut -Times 1
        }
	}
}

Describe "New-SolutionConfigFiles multiple project _config folders" {

	Context "When there are multiple project _config folders under the path folder" {
	
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project2" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project2\_config" -Path $TestDrive -ItemType Directory		
		$testBasePath = "$TestDrive"	
		Mock -ModuleName $sut New-TransformedConfigForProjectConfigFolder { }

		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call New-TransformedConfigForProjectConfigFolder twice" {
            Assert-MockCalled New-TransformedConfigForProjectConfigFolder -ModuleName $sut -Times 2
        }

	}	
}

Describe "New-SolutionConfigFiles Child config structure convention not followed" {
	
	New-Item -Name "Project1" -Path $TestDrive -ItemType Directory
	New-Item -Name "Project1\_config" -Path $TestDrive -ItemType Directory	
	$testBasePath = "$TestDrive"	

	Context "When there is NO application folder" {
	
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-SolutionConfigFiles -path "$testBasePath\Project1" -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No 'application' folder found under path: $testBasePath\Project1\_config, please remove the _config folder or add a child 'application' folder." -replace "\\","\\"			
			$result | Should Match $expectedErrorMessage
		}

	}	
	
	Context "When there is NO base config file" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-SolutionConfigFiles -path "$testBasePath\Project1" -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No base config file found under path: $testBasePath\Project1\_config\application, please remove the '_config\application' folder or add a base config file." -replace "\\","\\"			
			$result | Should Match $expectedErrorMessage
		}
	}	

	Context "When there are NO child transform folders" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		$testBasePath = "$TestDrive"			
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No 'child transform' folders found under 'application' folder: $testBasePath\Project1\_config\application, please add a new 'child transform' folder and transform file." -replace "\\","\\"			
			$result | Should Match $expectedErrorMessage
		}
	}
	
	Context "When there is a child transform folder but NO child XSLT transform file" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child1" -Path $TestDrive -ItemType Directory
		$testBasePath = "$TestDrive"			
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No child transform file found under 'child transform' folder: $testBasePath\Project1\_config\application\Child1, please remove the 'child transform' folder or add a new 'child transform' file." -replace "\\","\\"			
			$result | Should Match $expectedErrorMessage
		}
	}

}

Describe "New-SolutionConfigFiles Child and grandchild config structure convention not followed" {

	Context "When there is a child XSLT transform file a 'grandchild transform' folder and no 'grandchild transform' file" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\app.xslt" -Path $TestDrive -ItemType File		
		New-Item -Name "Project1\_config\application\Child1\Grandchild1" -Path $TestDrive -ItemType Directory				
		$testBasePath = "$TestDrive"			
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "No 'grandchild transform' file found under 'grandchild transform' folder: $testBasePath\Project1\_config\application\Child1\Grandchild1. All 'grandchild transform' folders must contain a 'grandchild transform' file. Please remove all 'grandchild transform' folders or add a new 'grandchild transform' file to the 'grandchild transform' folder: $testBasePath\Project1\_config\application\Child1\Grandchild1." -replace "\\","\\"	

				
			$result | Should Match $expectedErrorMessage
		}
	}

	Context "When there are only some grandchild transform folders" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\app.xslt" -Path $TestDrive -ItemType File		
		New-Item -Name "Project1\_config\application\Child1\Grandchild1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\Grandchild1\app.xslt" -Path $TestDrive -ItemType File		
		New-Item -Name "Project1\_config\application\Child2" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child2\app.xslt" -Path $TestDrive -ItemType File	
		#New-Item -Name "Project1\_config\application\Child2\Grandchild2" -Path $TestDrive -ItemType Directory #Purposefully removed for test
		#New-Item -Name "Project1\_config\application\Child2\Grandchild2\app.xslt" -Path $TestDrive -ItemType File #Purposefully removed for test
		New-Item -Name "Project1\_config\application\Child3" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child3\app.xslt" -Path $TestDrive -ItemType File		
		New-Item -Name "Project1\_config\application\Child3\Grandchild3" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child3\Grandchild3\app.xslt" -Path $TestDrive -ItemType File		
	

		$testBasePath = "$TestDrive"			
		Import-Module "$baseModulePath\$sut"
		
		$result = $null
		try {
			$result = New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$result = $_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "The 'project config' folder: $testBasePath\Project1\_config\application contains 2 'child transform' folders with 'grandchild transform' folders and 1 without 'grandchild transform' folders. Either add or remove 'grandchild transform' folders with corresponding 'grandchild transform' files to make the 'project config' folder structure consistent." -replace "\\","\\"			
			$result | Should Match $expectedErrorMessage
		}
	}

}

Describe "New-SolutionConfigFiles single child transformation" {
	
	Context "When there is a base config file, child transform folder and child transform file" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\app.xslt" -Path $TestDrive -ItemType File		
		$testBasePath = "$TestDrive"	
		Import-Module "$baseModulePath\$sut"
		
		Mock -ModuleName $sut Invoke-ConfigTransformation { }
		
		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Invoke-ConfigTransformation once" {
            Assert-MockCalled Invoke-ConfigTransformation -ModuleName $sut -Times 1
        }
	}
}

Describe "New-SolutionConfigFiles multiple child transformations" {

		Context "When there is a base config file and multiple child transform folders and files" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\app.xslt" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child2" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child2\app.xslt" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child3" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child3\app.xslt" -Path $TestDrive -ItemType File

		$testBasePath = "$TestDrive"	
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Invoke-ConfigTransformation {}
		
		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Invoke-ConfigTransformation three times" {
            Assert-MockCalled Invoke-ConfigTransformation -ModuleName $sut -Times 3
        }
	}
}

Describe "New-SolutionConfigFiles single grandchild transformation" {
	
	Context "When there is a grandchild transform file" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\app.xslt" -Path $TestDrive -ItemType File		
		New-Item -Name "Project1\_config\application\Child1\Grandchild1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\Grandchild1\app.xslt" -Path $TestDrive -ItemType File		

		$testBasePath = "$TestDrive"	
		Import-Module "$baseModulePath\$sut"
		
		Mock -ModuleName $sut Set-TransformOutputPath { return "$testBasePath\_transformedConfig\temp\Project1\application\Child1" } -Verifiable -ParameterFilter {$useTempOutputPath -eq $true}
		Mock -ModuleName $sut Invoke-ConfigTransformation { }
		
		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should set the child transform output path to a temporary path" {
			Assert-VerifiableMocks
        }
	}
	
	Context "When a base config file is transformed using a child transform file" {
		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\app.xslt" -Path $TestDrive -ItemType File		
		New-Item -Name "Project1\_config\application\Child1\Grandchild1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\Grandchild1\app.xslt" -Path $TestDrive -ItemType File		

		$testBasePath = "$TestDrive"	
		Import-Module "$baseModulePath\$sut"
		
		Set-Content "$testBasePath\Project1\_config\application\app.config" "<?xml version=""1.0""?><configuration><custom><groups><group name=""TestGroup1""><values><value key=""Test1"" value=""True"" /><value key=""Test2"" value=""600"" /></values></group><group name=""TestGroup2""><values><value key=""Test3"" value=""True"" /></values></group></groups></custom></configuration>"
		
		Set-Content "$testBasePath\Project1\_config\application\Child1\app.xslt" "<?xml version=""1.0""?><configuration xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform""><custom><groups><group name=""TestGroup1""><values><value key=""Test2"" value=""601"" xdt:Transform=""Replace"" xdt:Locator=""Match(key)"" /></values></group></groups></custom></configuration>"
		
		$expectedOutputFile = "<?xml version=""1.0""?><configuration><custom><groups><group name=""TestGroup1""><values><value key=""Test1"" value=""True"" /><value key=""Test2"" value=""601"" /></values></group><group name=""TestGroup2""><values><value key=""Test3"" value=""True"" /></values></group></groups></custom></configuration>"
		
		#Mock -ModuleName $sut Set-TransformOutputPath { return "$TestDrive\_transformedConfig\application\Child1\app.config" }
		
		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should generate a valid transformed output file in a temporary transformed output folder" {
			#Flatten the transformed XML file, removing white space and carriage returns
			$actualOutputFile = Get-Content "$testBasePath\_transformedConfig\temp\Project1\application\Child1\app.config" | Foreach {$_.Trim()} | Out-String
			$actualOutputFile = $actualOutputFile -replace "`t|`n|`r",""
			$actualOutputFile | Should BeExactly $expectedOutputFile
        }
	}	

	Context "When a temporary transformed child output file is transformed using a grandchild transform file" {
	
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\app.xslt" -Path $TestDrive -ItemType File		
		New-Item -Name "Project1\_config\application\Child1\Grandchild1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\Grandchild1\app.xslt" -Path $TestDrive -ItemType File		

		$testBasePath = "$TestDrive"	
		Import-Module "$baseModulePath\$sut"
		
		Set-Content "$testBasePath\Project1\_config\application\app.config" "<?xml version=""1.0""?><configuration><custom><groups><group name=""TestGroup1""><values><value key=""Test1"" value=""True"" /><value key=""Test2"" value=""600"" /></values></group><group name=""TestGroup2""><values><value key=""Test3"" value=""True"" /></values></group></groups></custom></configuration>"
		
		Set-Content "$testBasePath\Project1\_config\application\Child1\app.xslt" "<?xml version=""1.0""?><configuration xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform""><custom><groups><group name=""TestGroup1""><values><value key=""Test2"" value=""601"" xdt:Transform=""Replace"" xdt:Locator=""Match(key)"" /></values></group></groups></custom></configuration>"
		
		Set-Content "$testBasePath\Project1\_config\application\Child1\Grandchild1\app.xslt" "<?xml version=""1.0""?><configuration xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform""><custom><groups><group name=""TestGroup1""><values><value key=""Test2"" value=""602"" xdt:Transform=""Replace"" xdt:Locator=""Match(key)"" /></values></group></groups></custom></configuration>"
		
		$expectedOutputFile = "<?xml version=""1.0""?><configuration><custom><groups><group name=""TestGroup1""><values><value key=""Test1"" value=""True"" /><value key=""Test2"" value=""602"" /></values></group><group name=""TestGroup2""><values><value key=""Test3"" value=""True"" /></values></group></groups></custom></configuration>"
		
		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should generate a valid transformed output file in the transformed output folder" {
			#Flatten the transformed XML file, removing white space and carriage returns
			$actualOutputFile = Get-Content "$testBasePath\_transformedConfig\Project1\application\Child1\Grandchild1\app.config" | Foreach {$_.Trim()} | Out-String
			$actualOutputFile = $actualOutputFile -replace "`t|`n|`r",""
			$actualOutputFile | Should BeExactly $expectedOutputFile
		}
	}	
}

Describe "New-SolutionConfigFiles child transformed output" {
	
	Context "When a base config file is transformed using a child transform file" {
	
		Import-Module "$baseModulePath\$sut"		
		New-Item -Name "Project1\_config\application" -Path $TestDrive -ItemType Directory	
		New-Item -Name "Project1\_config\application\app.config" -Path $TestDrive -ItemType File	
		New-Item -Name "Project1\_config\application\Child1" -Path $TestDrive -ItemType Directory
		New-Item -Name "Project1\_config\application\Child1\app.xslt" -Path $TestDrive -ItemType File
		
		New-Item -Name "_transformedConfig" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\Project1" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\Project1\application" -Path $TestDrive -ItemType Directory
		New-Item -Name "_transformedConfig\Project1\application\Child1" -Path $TestDrive -ItemType Directory	
		New-Item -Name "_transformedConfig\Project1\application\Child1\app.config" -Path $TestDrive -ItemType File			
		$testBasePath = "$TestDrive"
		
		Set-Content "$testBasePath\Project1\_config\application\app.config" "<?xml version=""1.0""?><configuration><custom><groups><group name=""TestGroup1""><values><value key=""Test1"" value=""True"" /><value key=""Test2"" value=""600"" /></values></group><group name=""TestGroup2""><values><value key=""Test3"" value=""True"" /></values></group></groups></custom></configuration>"
		
		Set-Content "$testBasePath\Project1\_config\application\Child1\app.xslt" "<?xml version=""1.0""?><configuration xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform""><custom><groups><group name=""TestGroup1""><values><value key=""Test2"" value=""601"" xdt:Transform=""Replace"" xdt:Locator=""Match(key)"" /></values></group></groups></custom></configuration>"
		
		$expectedOutputFile = "<?xml version=""1.0""?><configuration><custom><groups><group name=""TestGroup1""><values><value key=""Test1"" value=""True"" /><value key=""Test2"" value=""601"" /></values></group><group name=""TestGroup2""><values><value key=""Test3"" value=""True"" /></values></group></groups></custom></configuration>"
		
		#Mock -ModuleName $sut Set-TransformOutputPath { return "$TestDrive\_transformedConfig\application\Child1\app.config" }
		
		try {
			New-SolutionConfigFiles -path $testBasePath -verbose
		}
		catch {
			$_
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should generate a valid transformed output file in the correct location" {
			#Flatten the transformed XML file, removing white space and carriage returns
			$actualOutputFile = Get-Content "$testBasePath\_transformedConfig\Project1\application\Child1\app.config" | Foreach {$_.Trim()} | Out-String
			$actualOutputFile = $actualOutputFile -replace "`t|`n|`r",""
			$actualOutputFile | Should BeExactly $expectedOutputFile
        }
	}
}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


