resource "azurerm_resource_group" "aks" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

data "azurerm_subscription" "primary" {}

module "service_principal" "aks_spn" {
    source              = "../service_principal"
    name                = "tfautomatedspn"
    expiration          = "2020-01-01T00:00:00Z"
}

resource "azurerm_role_assignment" "test" {
  scope                = "${data.azurerm_subscription.primary.id}"
  role_definition_name = "Reader"
  principal_id         = "${module.service_principal.aks_spn.id}"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.cluster_name}"
  location            = "${azurerm_resource_group.aks.location}"
  resource_group_name = "${azurerm_resource_group.aks.name}"
  dns_prefix          = "${var.dns_prefix}"

  agent_pool_profile {
    name            = "default-${count.index}"
    count           = "${var.agent_count}"
    vm_size         = "Standard_A0"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = "${module.service_principal.aks_spn.client_id}"
    client_secret = "${module.service_principal.aks_spn.client_secret}"
  }

  //tags = "${local.tags}"
} 