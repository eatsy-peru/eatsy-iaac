#################################################
# RESOURCE GROUPS
#################################################
resource "azurerm_resource_group" "main_rg" {
  name     = "RSGR01${local.resNameSuffix}"
  location = var.location
}
