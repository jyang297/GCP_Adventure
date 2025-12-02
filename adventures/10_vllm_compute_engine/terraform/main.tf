module "providers" {
  source = "../../../shared/terraform"
}

data "google_compute_network" "vpc" {
  name    = var.network_name
  project = var.project_id
}

data "google_compute_subnetwork" "subnet" {
  name    = var.subnet_name
  region  = var.region
  project = var.project_id
}

resource "google_compute_firewall" "vllm_api" {
  name    = "vllm-allow-api"
  network = data.google_compute_network.vpc.name

  allow { protocol = "tcp" ports = ["8000"] }
  source_ranges = [var.api_ingress_cidr]
  direction     = "INGRESS"
  target_service_accounts = [var.service_account_email]
}

resource "google_compute_firewall" "ssh" {
  name    = "vllm-allow-ssh"
  network = data.google_compute_network.vpc.name

  allow { protocol = "tcp" ports = ["22"] }
  source_ranges = [var.ssh_ingress_cidr]
  direction     = "INGRESS"
  target_service_accounts = [var.service_account_email]
}

resource "google_compute_instance" "vllm" {
  name         = "vllm-gpu-1"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = 100
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.id
    access_config { nat_ip = var.assign_public_ip ? google_compute_address.vllm_ip.address : null }
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = false
    preemptible         = var.preemptible
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  guest_accelerator {
    type  = var.gpu_type
    count = 1
  }

  metadata_startup_script = templatefile("${path.module}/startup.tftpl", {
    model_id          = var.model_id
    app_bucket        = var.app_bucket
    app_object        = var.app_object
    requirements_path = var.requirements_path
  })

  labels = {
    app = "vllm"
    env = "lab"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

resource "google_compute_address" "vllm_ip" {
  name    = "vllm-static-ip"
  project = var.project_id
  region  = var.region
  depends_on = [data.google_compute_network.vpc]
}
