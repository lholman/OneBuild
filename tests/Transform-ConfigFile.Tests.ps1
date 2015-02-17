$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "Transform-ConfigFile Single config file" {
	Context "When there is a single config file" {
		
		Import-Module "$baseModulePath\$sut"
		New-Item -Name "source.xml" -Path $TestDrive -ItemType File
		New-Item -Name "transform.xslt" -Path $TestDrive -ItemType File
		New-Item -Name "_TransformedConfigs" -Path $TestDrive -ItemType Directory	
		$testBasePath = "$TestDrive"		
		
		Mock -ModuleName $sut Invoke-ConfigTransformationTool
		#Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
        #    $Message -eq "No NuGet '.nuspec' configuration template file(s) found matching the packaging naming convention, exiting without NuGet packaging."
        #}
		
		try {
			Transform-ConfigFile -sourceFile "$testBasePath\source.xml" -transformFile "$testBasePath\transform.xslt" -verbose
		}
		catch {
			throw $_
		}
		finally {
			Remove-Module $sut
		}

		It "Should call Invoke-ConfigTransformationTool once to transform config files" {
            Assert-MockCalled Invoke-ConfigTransformationTool -ModuleName $sut -Times 1
        }
	}	
}


$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


