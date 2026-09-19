locals {
  platform_admins = toset([
    # Whoever is running (pipeline?). Will flap, though.
    data.azurerm_client_config.current.object_id,
    # Your personal user ID: az ad signed-in-user show --query id -o tsv
    "1263d89e-4b6d-44cf-9149-75c19a3412e5",
  ])
}

resource "azuread_group" "platform_admins" {
  display_name     = "${local.resource_basename}-platform-admins"
  security_enabled = true
}

resource "azuread_group_member" "platform_admin_members" {
  for_each         = local.platform_admins
  group_object_id  = azuread_group.platform_admins.object_id
  member_object_id = each.key
}

