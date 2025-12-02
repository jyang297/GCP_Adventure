module "providers" {
  source = "../../../shared/terraform"
}

locals {
  sa_name = "terraform-runner"
}

resource "google_project_service" "apis" {
  for_each           = toset([
    "compute.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "runner" {
  account_id   = local.sa_name
  display_name = "Terraform Runner"
}

resource "google_project_iam_custom_role" "runner_role" {
  role_id     = "terraformRunnerRole"
  title       = "Terraform Runner"
  description = "Scoped permissions for Terraform labs"
  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.networks.create",
    "compute.networks.updatePolicy",
    "compute.subnetworks.create",
    "compute.subnetworks.use",
    "compute.firewalls.create",
    "compute.firewalls.update",
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.get",
    "resourcemanager.projects.get",
    "storage.buckets.create",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.get",
    "logging.logEntries.create",
  ]
}

resource "google_project_iam_member" "runner_binding" {
  project = var.project_id
  role    = google_project_iam_custom_role.runner_role.name
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_storage_bucket" "tf_state" {
  name          = "${var.project_id}-tf-state"
  location      = var.region
  force_destroy = false
  versioning { enabled = true }
}

resource "google_compute_network" "main" {
  name                    = "advnet-main"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "regional" {
  for_each = {
    primary   = { region = var.region, cidr = "10.10.0.0/20" }
    secondary = { region = var.secondary_region, cidr = "10.20.0.0/20" }
  }

  name          = "adv-${each.key}"
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.main.id
  private_ip_google_access = true
}

resource "google_compute_firewall" "ssh_restrict" {
  name    = "adv-allow-ssh"
  network = google_compute_network.main.name

  allow { protocol = "tcp" ports = ["22"] }
  source_ranges = [var.my_ip_cidr]
  direction     = "INGRESS"
}

resource "google_billing_budget" "monthly" {
  billing_account = var.billing_account
  display_name    = "Adventure Budget"

  amount { specified_amount { currency_code = "USD" units = 50 } }

  threshold_rules { threshold_percent = 0.5 }
  threshold_rules { threshold_percent = 0.8 }
  threshold_rules { threshold_percent = 1.0 }

  all_updates_rule {
    pubsub_topic        = var.budget_pubsub_topic
    schema_version      = "1.0"
    monitoring_notification_channels = []
    disable_default_iam_recipients   = false
  }
}
