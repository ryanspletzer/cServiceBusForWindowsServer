#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

# Deviating from test template because SB.Util is not a DSC Resource under test.
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$moduleName = "ServiceBusForWindowsServerDsc"
$subModuleName = "SB.Util"

$moduleRootFilePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$moduleManifestFilePath = Join-Path -Path $moduleRootFilePath -ChildPath "$moduleName.psd1"

if (Test-Path -Path $moduleManifestFilePath)
{
    Write-Verbose -Message "Module manifest $moduleName.psd1 detected at $moduleManifestFilePath"
}
else
{
    throw "Module manifest could not be found for the module $moduleName in the root folder $moduleRootFilePath"
}

$subModuleFolderFilePath = Join-Path -Path $moduleRootFilePath -ChildPath "Modules"
$subModuleToTestFolderFilePath = Join-Path -Path $subModuleFolderFilePath -ChildPath $subModuleName

$subModuleToImportFilePath = Join-Path $subModuleToTestFolderFilePath -ChildPath "$subModuleName.psm1"

Import-Module -Name $subModuleToImportFilePath -Scope 'Global' -Force

#endregion HEADER

function Invoke-TestSetup {

}

function Invoke-TestCleanup {
    # Deviating from test template because SB.Util is not a DSC Resource under test.
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'SB.Util' {
        Describe 'SB.Util Function Tests' {
            Context "Validate Test-SBParameterState" {
                It "Returns true for two identical tables" {
                    # Arrange
                    $desired = @{
                        Example = "test"
                    }

                    # Act | Assert
                    Test-SBParameterState -CurrentValues $desired -DesiredValues $desired | Should Be $true
                }

                It "Returns false when a value is different" {
                    # Arrange
                    $current = @{
                        Example = "something"
                    }
                    $desired = @{
                        Example = "test"
                    }

                    # Act | Assert
                    Test-SBParameterState -CurrentValues $current -DesiredValues $desired | Should Be $false
                }

                It "Returns false when a value is missing" {
                    # Arrange
                    $current = @{}
                    $desired = @{
                        Example = "test"
                    }

                    # Act | Assert
                    Test-SBParameterState -CurrentValues $current -DesiredValues $desired | Should Be $false
                }

                It "Returns true when only a specified value matches, but other non-listed values do not" {
                    # Arrange
                    $current = @{
                        Example       = "test";
                        SecondExample = "true"
                    }
                    $desired = @{
                        Example       = "test";
                        SecondExample = "false"
                    }

                    # Act | Assert
                    Test-SBParameterState -CurrentValues $current -DesiredValues $desired -ValuesToCheck @( "Example" ) | Should Be $true
                }

                It "Returns false when only specified values do not match, but other non-listed values do " {
                    # Arrange
                    $current = @{
                        Example       = "test";
                        SecondExample = "true"
                    }
                    $desired = @{
                        Example       = "test";
                        SecondExample = "false"
                    }

                    # Act | Assert
                    Test-SBParameterState -CurrentValues $current -DesiredValues $desired -ValuesToCheck @( "SecondExample" ) | Should Be $false
                }

                It "Returns false when an empty array is used in the current values" {
                    # Arrange
                    $current = @{}
                    $desired = @{
                        Example       = "test";
                        SecondExample = "false"
                    }

                    # Act | Assert
                    Test-SBParameterState -CurrentValues $current -DesiredValues $desired | Should Be $false
                }
            }

            Context "Validate ConvertTo-PlainText" {
                It "Converts a securestring to plaintext" {
                    # Arrange
                    $secureString = ConvertTo-SecureString -String "test" -AsPlainText -Force

                    # Act
                    $value = ConvertTo-PlainText -SecureString $secureString

                    # Assert
                    $value | Should Be "test"
                }
            }

            Context "Validate New-SqlConnectionString" {
                It "Sets appropriate Integrated Security values" {
                    # Arrange
                    $params = @{
                        DataSource     = "TestServer"
                        InitialCatalog = "TestDB"
                    }

                    $params.IntegratedSecurity = "True"

                    # Act
                    $connectionString = New-SqlConnectionString @params

                    # Assert
                    $connectionString.Contains("Integrated Security=True") | Should Be $true

                    # Arrange
                    $params.IntegratedSecurity = "False"

                    # Act
                    $connectionString = New-SqlConnectionString @params

                    # Assert
                    $connectionString.Contains("Integrated Security=False") | Should Be $true

                    # Arrange
                    $params.IntegratedSecurity = "SSPI"

                    # Act
                    $connectionString = New-SqlConnectionString @params

                    # Assert
                    $connectionString.Contains("Integrated Security=SSPI") | Should Be $true
                }

                It "Sets credentials if given" {
                    # Arrange
                    $params = @{
                        DataSource         = "TestServer"
                        InitialCatalog     = "TestDB"
                        IntegratedSecurity = "False"
                    }

                    $secpassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                    $credential = New-Object -TypeName pscredential ("username", $secpassword)
                    $params.Credential = $credential

                    # Act
                    $connectionString = New-SqlConnectionString @params

                    # Assert
                    $connectionString.Contains("User Id=username") | Should Be $true
                    $connectionString.Contains("Password=password") | Should Be $true
                }

                It "Sets Encrypt value appropriately" {
                    # Arrange
                    $params = @{
                        DataSource         = "TestServer"
                        InitialCatalog     = "TestDB"
                        IntegratedSecurity = "True"
                    }

                    # Act
                    $connectionString = New-SqlConnectionString @params

                    # Assert
                    $connectionString.Contains("Encrypt=False") | Should Be $true

                    # Arrange
                    $params.Encrypt = $false

                    # Act
                    $connectionString = New-SqlConnectionString @params

                    # Assert
                    $connectionString.Contains("Encrypt=False") | Should Be $true

                    # Arrange
                    $params.Encrypt = $true

                    # Act
                    $connectionString = New-SqlConnectionString @params

                    # Assert
                    $connectionString.Contains("Encrypt=True") | Should Be $true
                }
            }

            Context "Validate Get-SqlConnectionStringPropertyValue" {
                It "Retrieves appropriate value" {
                    # Arrange
                    $connectionString =
@"
Data Source=TestServer;Initial Catalog=TestDB;Integrated Security=True;User Id=username;Password=password;Encrypt=True
"@
                    $params = @{
                        SqlConnectionString = $connectionString
                    }

                    $params.PropertyName = "Data Source"

                    # Act
                    $propertyValue = [string](Get-SqlConnectionStringPropertyValue @params)

                    # Assert
                    $propertyValue | Should BeExactly "TestServer"

                    # Arrange
                    $params.PropertyName = "Initial Catalog"

                    # Act
                    $propertyValue = [string](Get-SqlConnectionStringPropertyValue @params)

                    # Assert
                    $propertyValue | Should BeExactly "TestDB"

                    # Arrange
                    $params.PropertyName = "Integrated Security"

                    # Act
                    $propertyValue = [string](Get-SqlConnectionStringPropertyValue @params)

                    # Assert
                    $propertyValue | Should BeExactly "True"

                    # Arrange
                    $params.PropertyName = "User Id"

                    # Act
                    $propertyValue = [string](Get-SqlConnectionStringPropertyValue @params)

                    # Assert
                    $propertyValue | Should BeExactly "username"

                    # Arrange
                    $params.PropertyName = "Password"

                    # Act
                    $propertyValue = [string](Get-SqlConnectionStringPropertyValue @params)

                    # Assert
                    $propertyValue | Should BeExactly "password"

                    # Arrange
                    $params.PropertyName = "Encrypt"

                    # Act
                    $propertyValue = [string](Get-SqlConnectionStringPropertyValue @params)

                    # Assert
                    $propertyValue | Should BeExactly "True"
                }

                It "Returns SSPI when SSPI is in Integrated Security in connection string" {
                    # Arrange
                    $connectionString =
@"
Data Source=TestServer;Initial Catalog=TestDB;Integrated Security=SSPI;User Id=username;Password=password;Encrypt=True
"@

                    $params = @{
                        SqlConnectionString = $connectionString
                    }

                    $params.PropertyName = "Integrated Security"

                    # Act
                    $propertyValue = [string](Get-SqlConnectionStringPropertyValue @params)

                    # Assert
                    $propertyValue | Should BeExactly "SSPI"
                }
            }

            Context 'Validate Get-AccountName' {
                It "returns the account name from an account formatted like CONTOSO\AccountName" {
                    # Arrange
                    $accountName = "CONTOSO\AccountName"

                    # Act | Assert
                    Get-AccountName -FullAccountNameWithDomain $accountName | Should BeExactly 'AccountName'
                }

                It 'returns the account name from an account formatted like AccountName@contoso.com' {
                    # Arrange
                    $accountName = 'AccountName@contoso.com'

                    # Act | Assert
                    Get-AccountName -FullAccountNameWithDomain $accountName | Should BeExactly 'AccountName'
                }
            }

            Context 'Validate Get-AccountDomainName' {
                It 'returns the account domain name from an account formatted like CONTOSO\AccountName' {
                    # Arrange
                    $accountName = "CONTOSO\AccountName"

                    # Act | Assert
                    Get-AccountDomainName -FullAccountNameWithDomain $accountName | Should BeExactly 'CONTOSO'
                }

                It 'returns the account domain name from an account formatted like AccountName@contoso.com' {
                    # Arrange
                    $accountName = 'AccountName@contoso.com'

                    # Act | Assert
                    Get-AccountDomainName -FullAccountNameWithDomain $accountName | Should BeExactly 'contoso.com'
                }
            }

            Context 'Validate Get-FullyQualifiedDomainName' {
                # Arrange
                Mock -ModuleName SB.Util Get-DistinguishedNameForDomain {
                    return 'DC=contoso,DC=com'
                }

                $domainName = 'CONTOSO'

                It 'returns contoso.com via the distinguished name of the domain' {
                    # Act
                    $fullyQualifiedDomainName = Get-FullyQualifiedDomainName -DomainName $domainName

                    # Assert
                    $fullyQualifiedDomainName | Should BeExactly 'contoso.com'
                }
            }

            Context 'Validate Format-AccountName' {
                # Arrange
                Mock -ModuleName SB.Util Get-DistinguishedNameForDomain {
                    return 'DC=contoso,DC=com'
                }

                Mock -ModuleName SB.Util Get-NetBIOSDomainName {
                    return 'CONTOSO'
                }

                It 'returns a user logon name in UPN format from pre Windows 2000 format' {
                    # Arrange
                    $preWindows2000Account = 'CONTOSO\account'

                    # Act
                    $formatAccountNameParams = @{
                        FullAccountNameWithDomain = $preWindows2000Account
                        Format                    = 'UserLogonName'
                    }
                    $formattedAccountName = Format-AccountName @formatAccountNameParams

                    # Assert
                    $formattedAccountName | Should BeExactly 'account@contoso.com'
                }

                It 'returns a user logon name in pre Windows 2000 format from a UPN format' {
                    # Arrange
                    $formatAccountNameParams = @{
                        FullAccountNameWithDomain = 'account@contoso.com'
                        Format                    = 'UserLogonNamePreWindows2000'
                    }

                    # Act
                    $formattedAccountName = Format-AccountName @formatAccountNameParams

                    # Assert
                    $formattedAccountName | Should BeExactly 'CONTOSO\account'
                }
            }

            Context 'Validate Compare-AccountName' {
                # Arrange
                Mock -ModuleName SB.Util Get-DistinguishedNameForDomain {
                    return 'DC=contoso,DC=com'
                }

                Mock -ModuleName SB.Util Get-NetBIOSDomainName {
                    return 'CONTOSO'
                }

                It 'returns true for two equal pre Windows 2000 formatted accounts' {
                    # Arrange
                    $compareAccountNamesParams = @{
                        ReferenceAccountNameWithDomain = 'CONTOSO\account'
                        DifferenceAccountNameWithDomain = 'CONTOSO\account'
                    }

                    # Act | Assert
                    Compare-AccountName @compareAccountNamesParams | Should Be $true
                }

                It 'returns true for two equal UPN formatted accounts' {
                    # Arrange
                    $compareAccountNamesParams = @{
                        ReferenceAccountNameWithDomain = 'account@contoso.com'
                        DifferenceAccountNameWithDomain = 'account@contoso.com'
                    }

                    # Act | Assert
                    Compare-AccountName @compareAccountNamesParams | Should Be $true
                }

                It 'returns true for a synonymous pre Windows 2000 formatted account and UPN formatted account' {
                    # Arrange
                    $compareAccountNamesParams = @{
                        ReferenceAccountNameWithDomain = 'CONTOSO\account'
                        DifferenceAccountNameWithDomain = 'account@contoso.com'
                    }

                    # Act | Assert
                    Compare-AccountName @compareAccountNamesParams | Should Be $true
                }

                It 'returns false for two inequal pre Windows 2000 formatted accounts' {
                    # Arrange
                    $compareAccountNamesParams = @{
                        ReferenceAccountNameWithDomain = 'CONTOSO\account'
                        DifferenceAccountNameWithDomain = 'CONTOSO\account2'
                    }

                    # Act | Assert
                    Compare-AccountName @compareAccountNamesParams | Should Be $false
                }

                It 'returns false for two inequal UPN formatted accounts' {
                    # Arrange
                    $compareAccountNamesParams = @{
                        ReferenceAccountNameWithDomain = 'account@contoso.com'
                        DifferenceAccountNameWithDomain = 'account2@contoso.com'
                    }

                    # Act | Assert
                    Compare-AccountName @compareAccountNamesParams | Should Be $false
                }

                It 'returns false for two differently formatted accounts that are not synonymous' {
                    # Arrange
                    $compareAccountNamesParams = @{
                        ReferenceAccountNameWithDomain = 'CONTOSO\account'
                        DifferenceAccountNameWithDomain = 'account2@contoso.com'
                    }

                    # Act | Assert
                    Compare-AccountName @compareAccountNamesParams | Should Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
