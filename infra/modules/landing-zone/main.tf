resource "google_folder" "client" {
  display_name = var.client_display_name
  parent       = var.parent
}

resource "google_folder" "environment" {
  for_each = var.environments

  display_name = each.value
  parent       = google_folder.client.name
}

locals {
  boolean_policies = {
    "iam.disableServiceAccountKeyCreation"            = "TRUE"
    "iam.automaticIamGrantsForDefaultServiceAccounts" = "TRUE"
    "sql.restrictPublicIp"                            = "TRUE"
    "compute.requireOsLogin"                          = "TRUE"
    "compute.skipDefaultNetworkCreation"              = "TRUE"
    "storage.uniformBucketLevelAccess"                = "TRUE"
    "storage.publicAccessPrevention"                  = "TRUE"
  }
}

resource "google_org_policy_policy" "boolean" {
  for_each = local.boolean_policies

  name   = "${google_folder.client.name}/policies/${each.key}"
  parent = google_folder.client.name

  spec {
    rules {
      enforce = each.value
    }
  }
}

resource "google_org_policy_policy" "deny_vm_external_ip" {
  name   = "${google_folder.client.name}/policies/compute.vmExternalIpAccess"
  parent = google_folder.client.name

  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}
