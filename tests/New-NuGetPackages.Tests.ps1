$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-NuGetPackages" {

	
	Context "When there are NO NuSpec file(s)" {
		
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-AllNuSpecFiles { return $null }
		Mock -ModuleName $sut Write-Warning {} -Verifiable -ParameterFilter {
            $Message -eq "No NuGet '.nuspec' file found matching the packaging naming convention, exiting without NuGet packaging."
        }
		
		$result = 0
		try {
			$result = New-NuGetPackages
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Writes a descriptive warning" {
			Assert-VerifiableMocks
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


