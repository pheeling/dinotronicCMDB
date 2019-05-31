#TODO Abstract Class Assets, Classdiagramm update
#Singleton Pattern für userConfiguration

$Global:srcPath = split-path -path $MyInvocation.MyCommand.Definition 
$Global:mainPath = split-path -path $srcPath
$Global:resourcespath = join-path -path "$mainPath" -ChildPath "resources"
$Global:errorVariable = "Stop"

#Requirementcheck PartnerCenter Module
if (!(Get-Module -ListAvailable -Name PartnerCenter)) {
    Install-Module -Name PartnerCenter
} 

Import-Module -Force "$resourcespath\Main.psm1"
Import-Module -Force "$resourcespath\PartnerCenterAuthentication.psm1"
Import-Module -Force "$resourcespath\UserConfiguration.psm1"
Import-Module -Force "$resourcespath\ErrorHandling.psm1"
Import-Module -Force "$resourcespath\PartnerCenterCustomer.psm1"
Import-Module -Force "$resourcespath\FreshServiceManageAssets.psm1"

$main = Get-NewMain
$partnerCenterCustomer = Get-NewPartnerCustomer
$partnerCenterCustomerList = $partnerCenterCustomer.getPartnerCenterCustomer()
$partnerCenterCustomer.getPartnerCenterSubscriptions($partnerCenterCustomerList)
$freshServiceAssets = Get-NewFreshServiceManageAssets
$freshServiceAssets.getFreshServiceDepartments()
$main.stop()