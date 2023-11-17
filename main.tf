provider "azurerm" {
  features {}
}
resource"azurerm_resource_group""example"{
name="terraform-test-resources"
location="EastUS"
}
resource"azurerm_storage_account""example"{
    name="terraformtstsa"
    resource_group_name=azurerm_resource_group.example.name
    location=azurerm_resource_group.example.location
account_tier="Standard"
account_replication_type="LRS"
}

resource"azurerm_storage_container""example"{
name="terraform-test-container"
storage_account_name=azurerm_storage_account.example.name
depends_on=[
azurerm_storage_account.example,
]
}

resource "azurerm_service_plan" "example" {
  name                   = "terraform-test-appserviceplan"
  location=azurerm_resource_group.example.location
  resource_group_name=azurerm_resource_group.example.name
  os_type                = "Linux"
  sku_name               = "B1"
  worker_count           = 2
  zone_balancing_enabled = "false"
  depends_on = [
    azurerm_resource_group.example,
  ]
  }


resource"azurerm_user_assigned_identity""managed_identity"{
location=azurerm_resource_group.example.location
resource_group_name=azurerm_resource_group.example.name
name="terraform-test-cm-app-managedidentity"
depends_on=[
azurerm_resource_group.example,
]
}

resource "azurerm_linux_function_app" "example"{
name="terraform-tst-functionapp"
location                =   azurerm_resource_group.example.location
resource_group_name     =   azurerm_resource_group.example.name
service_plan_id     =   azurerm_service_plan.example.id
storage_account_name    =   azurerm_storage_account.example.name
storage_account_access_key= azurerm_storage_account.example.primary_access_key
    app_settings={
        "FUNCTIONS_WORKER_RUNTIME"="python",
        "SCM_DO_BUILD_DURING_DEPLOYMENT"="true"
        "ARM_SUBSCRIPTION_ID"="",
        "ARM_TENANT_ID"="",
        "MSI_ARM_CLIENT_ID"="${azurerm_user_assigned_identity.managed_identity.client_id}",
        "CONTAINER_NAME"="${azurerm_storage_container.example.name}"
        }
site_config {
ftps_state="FtpsOnly"#Todisableplainftp
always_on=true#Enablethistoavoidthecoldstarttimeofcompute
health_check_path="/"#EnableFunctionApphealthcheck
cors {
allowed_origins=["https://portal.azure.com"]
}
}
identity{
    type="UserAssigned"
    identity_ids=[
        azurerm_user_assigned_identity.managed_identity.id
    ]
}
depends_on=[
    azurerm_storage_account.example,
    azurerm_user_assigned_identity.managed_identity
    ]
}


output"function_app_name"{
value=azurerm_linux_function_app.example.name
}