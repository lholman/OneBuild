$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-TransformedConfigFile Transform successfully" {
	Context "When there is a valid source and transform file"  {
		
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "source.xml" -Path $TestDrive -ItemType File
		New-Item -Name "transform.xslt" -Path $TestDrive -ItemType File
		New-Item -Name "_TransformedConfigs" -Path $TestDrive -ItemType Directory	
		$testBasePath = "$TestDrive"		
		
		Set-Content $testBasePath\source.xml "<?xml version=""1.0""?><configuration><custom><groups><group name=""TestGroup1""><values><value key=""Test1"" value=""True"" /><value key=""Test2"" value=""600"" /></values></group><group name=""TestGroup2""><values><value key=""Test3"" value=""True"" /></values></group></groups></custom></configuration>"
		
		Set-Content $testBasePath\transform.xslt "<?xml version=""1.0""?><configuration xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform""><custom><groups><group name=""TestGroup1""><values><value key=""Test2"" value=""601"" xdt:Transform=""Replace"" xdt:Locator=""Match(key)"" /></values></group></groups></custom></configuration>"
		
		$expectedOutputFile = "<?xml version=""1.0""?><configuration><custom><groups><group name=""TestGroup1""><values><value key=""Test1"" value=""True"" /><value key=""Test2"" value=""601"" /></values></group><group name=""TestGroup2""><values><value key=""Test3"" value=""True"" /></values></group></groups></custom></configuration>"
		
		try {
			New-TransformedConfigFile -sourceFile "$testBasePath\source.xml" -transformFile "$testBasePath\transform.xslt" -outputFile "$testBasePath\_TransformedConfigs\output.xml" -verbose
		}
		catch {
			throw $_
		}
		finally {
			Remove-Module $sut
		}

		It "Should generate a valid output XML file" {
			#Flatten the transformed XML file, removing white space and carriage returns
			$actualOutputFile = Get-Content "$testBasePath\_TransformedConfigs\output.xml" | Foreach {$_.Trim()} | Out-String
			$actualOutputFile = $actualOutputFile -replace "`t|`n|`r",""
			$actualOutputFile | Should BeExactly $expectedOutputFile
        }
	}
}

Describe "New-TransformedConfigFile Transform error" {
	Context "When there is an invalid source file"  {
		
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "source.xml" -Path $TestDrive -ItemType File
		New-Item -Name "transform.xslt" -Path $TestDrive -ItemType File
		$testBasePath = "$TestDrive"		
		
		$invalidXmlElement = "conuration"
		Set-Content $testBasePath\source.xml "<?xml version=""1.0""?><$invalidXmlElement><custom><groups><group name=""TestGroup1""><values><value key=""Test1"" value=""True"" /><value key=""Test2"" value=""600"" /></values></group><group name=""TestGroup2""><values><value key=""Test3"" value=""True"" /></values></group></groups></custom></configuration>"
		
		Set-Content $testBasePath\transform.xslt "<?xml version=""1.0""?><configuration xmlns:xdt=""http://schemas.microsoft.com/XML-Document-Transform""><custom><groups><group name=""TestGroup1""><values><value key=""Test2"" value=""601"" xdt:Transform=""Replace"" xdt:Locator=""Match(key)"" /></values></group></groups></custom></configuration>"
		
		try {
			$result = New-TransformedConfigFile -sourceFile "$testBasePath\source.xml" -transformFile "$testBasePath\transform.xslt" -outputFile "$testBasePath\output.xml" -verbose
		}
		catch {
			$result = "$_"
		}
		finally {
			Remove-Module $sut
		}

		It "Exits the module with a descriptive terminating error" {
			$expectedErrorMessage = "Whilst executing ctt.exe for sourceFile: $testBasePath\source.xml and transformFile: $testBasePath\transform.xslt, ctt.exe exited with error message: Exception while transforming: System.Xml.XmlException: The 'conuration' start tag on line 1 position 23 does not match the end tag of 'configuration'. Line 1, position 271" -replace "\\","\\"			
			$result | Should Match $expectedErrorMessage
		}
	}
	
}


$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


