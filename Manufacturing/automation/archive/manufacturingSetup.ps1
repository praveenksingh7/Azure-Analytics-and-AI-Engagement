param (
	[Parameter(Mandatory = $false)][string]$azure_login_id,
    [Parameter(Mandatory = $false)][string]$azure_login_password,
    [Parameter(Mandatory = $false)][string]$iot_hub_car,
    [Parameter(Mandatory = $false)][string]$iot_hub_telemetry,
    [Parameter(Mandatory = $false)][string]$iot_hub,
    [Parameter(Mandatory = $false)][string]$iot_hub_sendtohub,
	[Parameter(Mandatory = $false)][string]$synapseWorkspaceName,
	[Parameter(Mandatory = $false)][string]$wsId,
	[Parameter(Mandatory = $false)][string]$sqlPoolName,
	[Parameter(Mandatory = $false)][string]$dataLakeAccountName,
	[Parameter(Mandatory = $false)][string]$sqlUser,
	[Parameter(Mandatory = $false)][string]$sqlPassword,
	[Parameter(Mandatory = $false)][string]$resourceGroup,
	[Parameter(Mandatory = $false)][string]$mfgasaName,
	[Parameter(Mandatory = $false)][string]$carasaName,
	[Parameter(Mandatory = $false)][string]$cosmos_account_name_mfgdemo,
	[Parameter(Mandatory = $false)][string]$cosmos_database_name_mfgdemo_manufacturing,
	[Parameter(Mandatory = $false)][string]$mfgasaCosmosDBName,
	[Parameter(Mandatory = $false)][string]$mfgASATelemetryName,
	[Parameter(Mandatory = $false)][string]$app_name_telemetry_car,
	[Parameter(Mandatory = $false)][string]$app_name_telemetry,
	[Parameter(Mandatory = $false)][string]$app_name_hub,
	[Parameter(Mandatory = $false)][string]$app_name_sendtohub,
	[Parameter(Mandatory = $false)][string]$ai_name_telemetry_car,
	[Parameter(Mandatory = $false)][string]$ai_name_telemetry,
	[Parameter(Mandatory = $false)][string]$ai_name_hub,
	[Parameter(Mandatory = $false)][string]$ai_name_sendtohub,
	[Parameter(Mandatory = $false)][string]$sparkPoolName,
	[Parameter(Mandatory = $false)][string]$manufacturing_poc_app_service_name,
	[Parameter(Mandatory = $false)][string]$wideworldimporters_app_service_name

	)

# Install Az cli
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# login using identity
az login --identity

#install iot hub extension
az extension add --name azure-cli-iot-ext

#Create iot hub devices
az iot hub device-identity create -n $iot_hub_car -d race-car
az iot hub device-identity create -n $iot_hub_telemetry -d telemetry-data
az iot hub device-identity create -n $iot_hub -d data-device
az iot hub device-identity create -n $iot_hub_sendtohub -d send-to-hub

#get connection strings

$iot_device_connection_car = az iot hub device-identity show-connection-string --hub-name $iot_hub_car --device-id race-car | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_car.connectionString

$iot_device_connection_telemetry = az iot hub device-identity show-connection-string --hub-name $iot_hub_telemetry --device-id telemetry-data | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_telemetry.connectionString

$iot_device_connection_sku2 = az iot hub device-identity show-connection-string --hub-name $iot_hub_sendtohub --device-id send-to-hub | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_sku2.connectionString

$iot_device_connection_sendtohub = az iot hub device-identity show-connection-string --hub-name $iot_hub --device-id data-device | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_sendtohub.connectionString

#get App insights instrumentation keys

$app_insights_instrumentation_key_car = az resource show -g $resourceGroup -n $ai_name_telemetry_car --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey | Out-String | ConvertFrom-Json
Write-Host $app_insights_instrumentation_key_car 

$app_insights_instrumentation_key_telemetry = az resource show -g $resourceGroup -n $ai_name_telemetry --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey | Out-String | ConvertFrom-Json
Write-Host $app_insights_instrumentation_key_telemetry

$app_insights_instrumentation_key_sku2 = az resource show -g $resourceGroup -n $ai_name_hub --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey | Out-String | ConvertFrom-Json
Write-Host $app_insights_instrumentation_key_sku2

$app_insights_instrumentation_key_sendtohub = az resource show -g $resourceGroup -n $ai_name_sendtohub --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey | Out-String | ConvertFrom-Json
Write-Host $app_insights_instrumentation_key_sendtohub

#download the binary zip folders

expand-archive -path "./artifacts/binaries/carTelemetry.zip" -destinationpath "./carTelemetry"

expand-archive -path "./artifacts/binaries/datagenTelemetry.zip" -destinationpath "./datagenTelemetry"

expand-archive -path "./artifacts/binaries/sku2.zip" -destinationpath "./sku2"

expand-archive -path "./artifacts/binaries/sendtohub.zip" -destinationpath "./sendtohub"

expand-archive -path "./artifacts/binaries/mfg-webapp.zip" -destinationpath "./mfg-webapp"

expand-archive -path "./artifacts/binaries/wideworldimporters.zip" -destinationpath "./wideworldimporters"

#Replace connection string in config

(Get-Content -path carTelemetry/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_car.connectionString`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_car`				
        } | Set-Content -Path carTelemetry/appsettings.json
		
(Get-Content -path datagenTelemetry/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_telemetry.connectionString`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_telemetry`				
        } | Set-Content -Path datagenTelemetry/appsettings.json
		
(Get-Content -path sku2/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_sku2.connectionString`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_sku2`				
        } | Set-Content -Path sku2/appsettings.json
		
(Get-Content -path sendtohub/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_sendtohub.connectionString`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_sendtohub`				
        } | Set-Content -Path sendtohub/appsettings.json

	
#make zip for app service deployment

Compress-Archive -Path "./carTelemetry/*" -DestinationPath "./carTelemetry.zip"
Compress-Archive -Path "./sendtohub/*" -DestinationPath "./sendtohub.zip"
Compress-Archive -Path "./sku2/*" -DestinationPath "./sku2.zip"
Compress-Archive -Path "./datagenTelemetry/*" -DestinationPath "./datagenTelemetry.zip"
Compress-Archive -Path "./wideworldimporters/*" -DestinationPath "./wideworldimporters.zip"

# deploy the codes on app services

az webapp stop --name $app_name_telemetry_car --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $app_name_telemetry_car --src "./carTelemetry.zip"
az webapp start --name $app_name_telemetry_car --resource-group $resourceGroup

az webapp stop --name $app_name_telemetry --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $app_name_telemetry --src "./datagenTelemetry.zip"
az webapp start --name $app_name_telemetry --resource-group $resourceGroup

az webapp stop --name $app_name_hub --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $app_name_hub --src "./sku2.zip"
az webapp start --name $app_name_hub --resource-group $resourceGroup

az webapp stop --name $app_name_sendtohub --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $app_name_sendtohub --src "./sendtohub.zip"
az webapp start --name $app_name_sendtohub --resource-group $resourceGroup

az webapp stop --name $wideworldimporters_app_service_name --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $wideworldimporters_app_service_name --src "./wideworldimporters.zip"
az webapp start --name $wideworldimporters_app_service_name --resource-group $resourceGroup

#uploading Cosmos data
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
Connect-AzAccount -identity

$cosmosDbAccountName = $cosmos_account_name_mfgdemo
$databaseName = $cosmos_database_name_mfgdemo_manufacturing
$cosmos=Get-ChildItem "./artifacts/cosmos" | Select BaseName 
foreach($name in $cosmos)
	{
$collection = $name.BaseName
$cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $resourceGroup    
#New-CosmosDbCollection -Context $cosmosDbContext -Id $collection -OfferThroughput 400 -PartitionKey 'PartitionKey' -DefaultTimeToLive 604800
$path="./artifacts/cosmos/"+$name.BaseName+".json"
$document=Get-Content -Raw -Path $path
$document=ConvertFrom-Json $document
foreach($json in $document)
{
 $key=$json.SyntheticPartitionKey
 $id = New-Guid
 $json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id
 $body=ConvertTo-Json $json
 New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
 }
 } 

az login -u $azure_login_id -p $azure_login_password
$subscriptionId=az account show|ConvertFrom-Json
$tenantId=$subscriptionId.tenantId
$subscriptionId=$subscriptionId.Id

$tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue;

New-Item log.txt
Add-Content log.txt "------asa powerbi connection-----"
#connecting asa and powerbi
# $principal=az resource show -g $resourceGroup -n $mfgasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs" |ConvertFrom-Json
# $principalId=$principal.identity.principalId
# $uri="https://api.powerbi.com/v1.0/myorg/groups/$wsId/users"
# $body=@"
# {
  # "identifier": "$principalId",
  # "principalType": "App",
  # "groupUserAccessRight": "Admin"
# }
# "@
# $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $powerbitoken" } -ContentType "application/json"
# Add-Content log.txt $result
# $principal=az resource show -g $resourceGroup -n $carasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs" |ConvertFrom-Json
# $principalId=$principal.identity.principalId
# $uri="https://api.powerbi.com/v1.0/myorg/groups/$wsId/users"
# $body=@"
# {
  # "identifier": "$principalId",
  # "principalType": "App",
  # "groupUserAccessRight": "Admin"
# }
# "@
# $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $powerbitoken" } -ContentType "application/json"
# Add-Content log.txt $result
#start ASA
#Install stream-analytics extension
az extension add --name stream-analytics
az stream-analytics job start --resource-group $resourceGroup --name $mfgASATelemetryName --output-start-mode JobStartTime
az stream-analytics job start --resource-group $resourceGroup --name $mfgasaName --output-start-mode JobStartTime
az stream-analytics job start --resource-group $resourceGroup --name $carasaName --output-start-mode JobStartTime
az stream-analytics job start --resource-group $resourceGroup --name $mfgasaCosmosDBName --output-start-mode JobStartTime

Add-Content log.txt "------sql schema-----"
 #creating sql schema
Install-Module -Force -Name SqlServer
Write-Information "Create tables in $($sqlPoolName)"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
 $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
 Add-Content log.txt $result
 
 #uploading Sql Scripts
 $scripts=Get-ChildItem "./artifacts/sqlscripts" | Select BaseName
 $TemplatesPath="./artifacts/templates";	
  $cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name_mfgdemo -g $resourceGroup |ConvertFrom-Json
 $cosmos_account_key=$cosmos_account_key.primarymasterkey
 foreach ($name in $scripts) {
     $item = Get-Content -Raw -Path "$($TemplatesPath)/sql_script.json"
     $item = $item.Replace("#SQL_SCRIPT_NAME#", $name.BaseName)
	 $item = $item.Replace("#SQL_POOL_NAME#", $sqlPoolName)
	  $jsonItem = ConvertFrom-Json $item
	  $ScriptFileName="./artifacts/sqlscripts/"+$name.BaseName+".sql"
	  $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
	  $query = $query.Replace("#COSMOS_ACCOUNT#", $cosmos_account_name_mfgdemo)
	  $query = $query.Replace("#COSMOS_KEY#", $cosmos_account_key)
	  if ($Parameters -ne $null) {
        foreach ($key in $Parameters.Keys) {
            $query = $query.Replace("#$($key)#", $Parameters[$key])
        }
    }
	$query = ConvertFrom-Json (ConvertTo-Json $query)
	$jsonItem.properties.content.query = $query
    $item = ConvertTo-Json $jsonItem -Depth 100
    
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/sqlscripts/$($name.BaseName)?api-version=2019-06-01-preview"

   
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	 }

 
 #Uploading to storage containers
 $tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue;
 $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
 Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
 Expand-Archive "azCopy.zip" -DestinationPath ".\azcopy" -Force
 $azCopyCommand = (Get-ChildItem -Path ".\azcopy" -Recurse azcopy.exe).Directory.FullName
 $Env:Path += ";"+ $azCopyCommand
 Install-Module -Name Az.Storage -Force
 $storage_account_key=az storage account keys list -g $resourceGroup -n $dataLakeAccountName |ConvertFrom-Json
 $storage_account_key=$storage_account_key[0].value
 $dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
 $containers=Get-ChildItem "./artifacts/storageassets" | Select BaseName
 foreach($container in $containers)
 {
 $destinationSasKey = New-AzStorageContainerSASToken -Container $container.BaseName -Context $dataLakeContext -Permission rwdl
 $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/$($container.BaseName)/$($destinationSasKey)"
 azcopy copy "./artifacts/storageassets/$($container.BaseName)/*" $destinationUri --recursive
 }
 
 #Copy external blob content
 $tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue;
  $destinationSasKey = New-AzStorageContainerSASToken -Container "mfgdemodata" -Context $dataLakeContext -Permission rwdl
  $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/mfgdemodata/$($destinationSasKey)"
  azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-csv/telemetryp.csv" $destinationUri --recursive
  $destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
  $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /$($destinationSasKey)"
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Campaign.csv"  $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /CampaignData_Bubble.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /CampaignData.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Campaignproducts.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Campaignsales.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /customer.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Date.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /historical-data-adf.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /location.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /mfg-AlertAlarm.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /mfg-MachineAlert.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /mfg-OEE-Agg.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /mfg-OEE.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Product.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /sales.csv" $destinationUri --recursive
  azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /vCampaignSales.csv" $destinationUri --recursive
 #$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
 #$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/webappassets/$($destinationSasKey)"
 #azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/Intro_product.mp4" $destinationUri --recursive
 #azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/Machine%20Maintenance%20Demo.mp4" $destinationUri --recursive
 #azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/factory_safety_video.mp4" $destinationUri --recursive
 #azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/Hololens_Stretch.mp4" $destinationUri --recursive
 #azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/RioDeJaneiro_video.mp4" $destinationUri --recursive
 
 Add-Content log.txt "------linked Services------"
 #Creating linked services
 $tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue;
 ##cosmos linked services
 $cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name_mfgdemo -g $resourceGroup |ConvertFrom-Json
 $cosmos_account_key=$cosmos_account_key.primarymasterkey
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"cosmos_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $cosmos_account_name_mfgdemo).Replace("#COSMOS_ACCOUNT#", $cosmos_account_name_mfgdemo).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key).Replace("#COSMOS_DATABASE#", $cosmos_database_name_mfgdemo_manufacturing)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($cosmos_account_name_mfgdemo)?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 ##Datalake linked services
 $storage_account_key=az storage account keys list -g $resourceGroup -n $dataLakeAccountName |ConvertFrom-Json
 $storage_account_key=$storage_account_key[0].value
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"data_lake_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($dataLakeAccountName)?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 ##blob linked services
 $storage_account_key=az storage account keys list -g $resourceGroup -n $dataLakeAccountName |ConvertFrom-Json
 $storage_account_key=$storage_account_key[0].value
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"blob_storage_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $name=$dataLakeAccountName+"blob"
 $blobLinkedService=$name
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $name).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($name)?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 ##powerbi linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"powerbi_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "ManufacturingDemo").Replace("#WORKSPACE_ID#", $wsId)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/ManufacturingDemo?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 ##sql pool linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"sql_pool_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $sqlPoolName).Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($sqlPoolName)?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
  ##sap hana linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"sap_hana_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "SapHana")
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
  ##teradata linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"teradata_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "TeraData")
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/TeraData?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
   ##oracle linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"oracle_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "oracle")
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/oracle?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 #Creating Datasets
 $tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue;
 Add-Content log.txt "------datasets------"
 Write-Information "Creating Datasets"
 $datasets = @{
        CosmosIoTToADLS = $dataLakeAccountName
		AzureSynapseAnalyticsTable1=$sqlPoolName
		MfgSAPHanaDataset=$sqlPoolName
		historical_drill=$dataLakeAccountName
		MFGAzureSynapseDrill=$sqlPoolName
		MachineInstanceSynapse=$sqlPoolName
		MFGIoTHistoricalSynapse=$sqlPoolName
		MfgIoTSynapseSink=$sqlPoolName
		MfgLocationSynapse=$sqlPoolName
		MfgOperationDataset=$sqlPoolName
		mfgcosmosdbqualityds=$cosmos_account_name_mfgdemo
		tblcosmosdbqualityds=$sqlPoolName
		SapHanaSalesData="SapHana"
		SAPSourceDataset="SapHana"
		MarketingDB_Processed=$dataLakeAccountName
		MarketingDB_Stage=$dataLakeAccountName
		MfgCampaignSynapseAnalyticsOutput=$sqlPoolName
		Teradata_MarketingDB="TeraData"
		TeradataMarketingDB="TeraData"
		MfgSalesdatasetsink=$sqlPoolName
		Oracle_SalesDB="oracle"
		OracleSalesDB="oracle"
		CosmosDbSqlApiCollection1=$cosmos_account_name_mfgdemo
		DS_AzureSynapse_Telemetry=$sqlPoolName
		IotData=$dataLakeAccountName
		ArchiveTwitterParquet=$dataLakeAccountName
		DeleteTweeterFiles=$dataLakeAccountName
		DS_MFG_AzureSynapse_TwitterAnalytics=$sqlPoolName
		TweetsParquet=$dataLakeAccountName
		MFGazuresyanapseDW=$sqlPoolName
		MFGParquettoSynapseSource=$dataLakeAccountName
		AzureSynapseAnalyticsTable6=$sqlPoolName
		AzureSynapseAnalyticsTable7=$sqlPoolName
		AzureSynapseAnalyticsTable8=$sqlPoolName
		AzureSynapseAnalyticsTable9=$sqlPoolName
		AzureSynapseAnalyticsTable10=$sqlPoolName
		Custom_CampaignData=$sqlPoolName
		Custom_CampaignData_bubble=$sqlPoolName
		Custom_Campaignproducts=$sqlPoolName
		Custom_Product=$sqlPoolName
		CustomCampaignData=$dataLakeAccountName
		CustomCampaignData_Bubble=$dataLakeAccountName
		CustomProduct=$dataLakeAccountName
		Sales=$dataLakeAccountName
		SalesData=$sqlPoolName
		}
$DatasetsPath="./artifacts/datasets";	
foreach ($dataset in $datasets.Keys) {
        Write-Information "Creating dataset $($dataset)"
		$LinkedServiceName=$datasets[$dataset]
		$itemTemplate = Get-Content -Path "$($DatasetsPath)/$($dataset).json"
		$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $LinkedServiceName)
		$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/datasets/$($dataset)?api-version=2019-06-01-preview"
		$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
		Add-Content log.txt $result
		}
 
#Creating spark notebooks
Add-Content log.txt "------Notebooks------"
Write-Information "Creating Spark notebooks..."
$notebooks=Get-ChildItem "./artifacts/notebooks" | Select BaseName 
$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $resourceGroup
        "#WORKSPACE_NAME#"  = $synapseWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
		"#SPARK_POOL_NAME#"= $sparkPoolName
		"#STORAGE_ACCOUNT_KEY#"=$storage_account_key
		"#COSMOS_LINKED_SERVICE#"=$cosmos_account_name_mfgdemo
}
foreach($name in $notebooks)
	{
		$template=Get-Content -Raw -Path "./artifacts/templates/spark_notebook.json"
		foreach ($paramName in $cellParams.Keys) {
			$template = $template.Replace($paramName, $cellParams[$paramName])
		}
		$jsonItem = ConvertFrom-Json $template
	    $path="./artifacts/notebooks/"+$name.BaseName+".ipynb"
		$notebook=Get-Content -Raw -Path $path
		$jsonNotebook = ConvertFrom-Json $notebook
		$jsonItem.properties.cells = $jsonNotebook.cells
		if ($CellParams) {
        foreach ($cellParamName in $cellParams.Keys) {
            foreach ($cell in $jsonItem.properties.cells) {
                for ($i = 0; $i -lt $cell.source.Count; $i++) {
                    $cell.source[$i] = $cell.source[$i].Replace($cellParamName, $CellParams[$cellParamName])
                }
            }
        }
    }
	     $item = ConvertTo-Json $jsonItem -Depth 100
		 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/notebooks/$($name.BaseName)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
		 #waiting for operation completion
		 Start-Sleep -Seconds 10
		 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
		 Add-Content log.txt $result
	}	


#creating Dataflows
Add-Content log.txt "------dataflows-----"
# $params = @{
        # LOAD_TO_SYNAPSE = "AzureSynapseAnalyticsTable8"
        # LOAD_TO_AZURE_SYNAPSE = "AzureSynapseAnalyticsTable9"
        # DATA_FROM_SAP_HANA = "DelimitedText1"
# }
$workloadDataflows = [ordered]@{
        MFG_Ingest_data_from_SAP_HANA_to_Azure_Synapse = "1 MFG Ingest data from SAP HANA to Azure Synapse"
		Ingest_data_from_SAP_HANA_to_Common_Data_Service="2 Ingest data from SAP HANA to Common Data Service"
		MFGDataFlowADLStoSynapse="2 MFGDataFlowADLStoSynapse"
		MFG_IoT_dataflow="7 MFG IoT_dataflow"
		MFGCosmosdbquality="MFGCosmosdbquality"
}
$DataflowPath="./artifacts/dataflows"
foreach ($dataflow in $workloadDataflows.Keys) 
{
		$Name=$workloadDataflows[$dataflow]
        Write-Information "Creating dataflow $($workloadDataflows[$dataflow])"
		 $item = Get-Content -Path "$($DataflowPath)/$($Name).json"
    
    # if ($params -ne $null) {
        # foreach ($key in $params.Keys) {
            # $item = $item.Replace("#$($key)#", $params[$key])
        # }
    # }
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/dataflows/$($Name)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
        #waiting for operation completion
		 Start-Sleep -Seconds 10
		 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
		 Add-Content log.txt $result
}

#uploading powerbi reports
$tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue;
Add-Content log.txt "------powerbi reports------"
Write-Information "Uploading power BI reports"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "./artifacts/reports" | Select BaseName 
foreach($name in $reports)
{
        $FilePath="./artifacts/reports/$($name.BaseName)"+".pbix"
        #New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
        
        #write-host "Uploading PowerBI Report $name";
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/imports?datasetDisplayName=$($name.BaseName)&nameConflict=CreateOrOverwrite";
		$fullyQualifiedPath=Resolve-Path -path $FilePath
        $fileBytes = [System.IO.File]::ReadAllBytes($fullyQualifiedPath);
        $fileEnc = [system.text.encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes);
        $boundary = [System.Guid]::NewGuid().ToString();
        $LF = "`r`n";
        $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data",
        "",
        $fileEnc,
        "--$boundary--$LF"
        ) -join $LF
        $result = Invoke-RestMethod -Uri $url -Method POST -Body $bodyLines -ContentType "multipart/form-data; boundary=`"--$boundary`"" -Headers @{ Authorization="Bearer $powerbitoken" }
		Start-Sleep -s 5 
		Add-Content log.txt $result
        #$reportId = $result.id;
        if($name.BaseName=="Campaign - Option C")
		{
			$temp = "" | select-object @{Name = "FileName"; Expression = {"$($name.BaseName)"}}, 
								@{Name = "Name"; Expression = {"$($name.BaseName)"}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}},
                                @{Name = "SourceServer"; Expression = {"manufacturingdemor16gxwbbra4mtbmu.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"ManufacturingDW"}}
		}
		else{
        $temp = "" | select-object @{Name = "FileName"; Expression = {"$($name.BaseName)"}}, 
								@{Name = "Name"; Expression = {"$($name.BaseName)"}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}},
                                @{Name = "SourceServer"; Expression = {"manufacturingdemo.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"ManufacturingDW"}}
								}
                                
        # get dataset                         
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/datasets";
        $dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
		Add-Content log.txt $dataSets
        foreach($res in $dataSets.value)
        {
        if($res.name -eq $name.BaseName)
        {
            $temp.PowerBIDataSetId= $res.id;
        }
       }
                
        $reportList.Add($temp)
        Start-Sleep -s 5    
        
}



#creating Pipelines
$tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue;
Add-Content log.txt "------pipelines------"
Write-Information "Creating pipelines"
$pipelines=Get-ChildItem "./artifacts/pipelines" | Select BaseName
$pipelineList = New-Object System.Collections.ArrayList
foreach($name in $pipelines)
{
	$FilePath="./artifacts/pipelines/"+$name.BaseName+".json"
	$temp = "" | select-object @{Name = "FileName"; Expression = {$name.BaseName}} , @{Name = "Name"; Expression = {$name.BaseName.ToUpper()}}, @{Name = "PowerBIReportName"; Expression = {""}}
	$pipelineList.Add($temp)
	 $item = Get-Content -Path $FilePath
	 $item=$item.Replace("#DATA_LAKE_STORAGE_NAME#",$dataLakeAccountName)
	 $item=$item.Replace("#BLOB_LINKED_SERVICE#",$blobLinkedService)
	 $defaultStorage=$synapseWorkspaceName + "-WorkspaceDefaultStorage"
	 $item=$item.Replace("#DEFAULT_STORAGE#",$defaultStorage)
	 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
     $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	 #waiting for operation completion
		 Start-Sleep -Seconds 10
		 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
		 Add-Content log.txt $result
	 
}



#Establish powerbi reports dataset connections
$tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue;
Add-Content log.txt "------pbi connections------"
Write-Information "Uploading power BI reports"	
$powerBIDataSetConnectionTemplate = Get-Content -Path "./artifacts/templates/powerbi_dataset_connection.json"
$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "$($synapseWorkspaceName).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String
foreach($report in $reportList)
{
   Write-Information "Setting database connection for $($report.Name)"
   $powerBIReportDataSetConnectionUpdateRequest = $powerBIDataSetConnectionUpdateRequest.Replace("#SOURCE_SERVER#", $report.SourceServer).Replace("#SOURCE_DATABASE#", $report.SourceDatabase) |Out-String
   $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/datasets/$($report.PowerBIDataSetId)/Default.UpdateDatasources";
    $result = Invoke-RestMethod -Uri $url -Method POST -Body $powerBIReportDataSetConnectionUpdateRequest -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" };
    Add-Content log.txt $result
  
}


#setting up main web app
# Convert to SecureString
 [securestring]$secStringPassword = ConvertTo-SecureString $azure_login_password -AsPlainText -Force
 [pscredential]$credential = New-Object System.Management.Automation.PSCredential ($azure_login_id, $secStringPassword)
 Install-Module -Name AzureAD -Force
 Connect-AzureAD -Credential $Credential
 $app = New-AzureADApplication -DisplayName "mfgpoc" -Homepage "https://localhost:44322" -ReplyUrls "https://localhost:44322"
 $appId=$app.AppId
 $sp = New-AzureADServicePrincipal -AppId $app.AppId
 $appSecret = New-AzureADServicePrincipalPasswordCredential -ObjectId $sp.ObjectId
(Get-Content -path mfg-webapp/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#USERNAME#', $azure_login_id`
				-replace '#PASSWORD#', $azure_login_password`	
				-replace '#APP_ID#', $appId`	
				-replace '#APP_SECRET#', $appSecret`
				-replace '#TENANT_ID#', $tenantId`				
        } | Set-Content -Path mfg-webapp/appsettings.json
(Get-Content -path mfg-webapp/wwwroot/config.js -Raw) | Foreach-Object { $_ `
                -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName`
				-replace '#SERVER_NAME#', $manufacturing_poc_app_service_name`
				-replace '#WWI_SITE_NAME#', $wideworldimporters_app_service_name`				
        } | Set-Content -Path mfg-webapp/wwwroot/config.js	

Compress-Archive -Path "./mfg-webapp/*" -DestinationPath "./mfg-webapp.zip"
az webapp stop --name $manufacturing_poc_app_service_name --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $manufacturing_poc_app_service_name --src "./mfg-webapp.zip"
az webapp start --name $manufacturing_poc_app_service_name --resource-group $resourceGroup

#uploading sql data
mkdir uploadscripts
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/CampaignData_Bubble.sql -outFile ./uploadscripts/CampaignData_Bubble.sql
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/CampaignData.sql        -outFile ./uploadscripts/CampaignData.sql       
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/Campaignsales.sql       -outFile ./uploadscripts/Campaignsales.sql      
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/customer.sql            -outFile ./uploadscripts/customer.sql           
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/Date.sql                -outFile ./uploadscripts/Date.sql               
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/historical-data-adf.sql -outFile ./uploadscripts/historical-data-adf.sql
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/location.sql            -outFile ./uploadscripts/location.sql           
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/mfg-AlertAlarm.sql      -outFile ./uploadscripts/mfg-AlertAlarm.sql     
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/mfg-MachineAlert.sql    -outFile ./uploadscripts/mfg-MachineAlert.sql   
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/mfg-OEE.sql             -outFile ./uploadscripts/mfg-OEE.sql            
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/Product.sql             -outFile ./uploadscripts/Product.sql            
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/sales.sql               -outFile ./uploadscripts/sales.sql              
wget https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customsql/Before/vCampaignSales.sql      -outFile ./uploadscripts/vCampaignSales.sql
 $scripts=Get-ChildItem "./uploadscripts" | Select BaseName    
 foreach ($name in $scripts) {
 $filename="./uploadscripts/$($name.BaseName)"+".sql"
 $sqlQuery = Get-Content -Raw -Path $filename
 $sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
 $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
 Add-Content log.txt $result
 }

Add-Content log.txt "Execution Complete"		


