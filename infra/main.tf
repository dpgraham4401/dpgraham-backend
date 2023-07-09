terraform {
  backend "gcs" {
    bucket = "dpgraham-terraform-state1"
    prefix = "terraform1"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  project = "dpgraham"
  region  = "us-east1"
  zone    = "us-east1-b"
}


resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_sql_database_instance" "dpgraham_postgres" {
  name             = "dpgraham-postgres"
  database_version = "POSTGRES_14"
  region           = var.region
  project          = var.project

  settings {
    tier              = "db-f1-micro"
    activation_policy = "ALWAYS"
    availability_type = "ZONAL"
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }
}

resource "google_sql_database" "dpgraham_database" {
  name     = "dpgraham"
  instance = google_sql_database_instance.dpgraham_postgres.name
}

resource "google_sql_user" "users" {
  instance = google_sql_database_instance.dpgraham_postgres.name
  type     = "BUILT_IN"
  name     = var.db_username
  password = var.db_password
}

# CDN tutorial
#resource "random_id" "rnd" {
#  byte_length = 4
#}

# Example apache server we'll use to test Cloud DNS
resource "google_compute_instance" "default" {
  name         = "dns-compute-instance"
  machine_type = "e2-micro"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  metadata_startup_script = <<-EOF
  sudo apt-get update && \
  sudo apt-get install apache2 -y && \
  echo "<!doctype html><html><body><h1>Hello World!</h1></body></html>" > /var/www/html/index.html
  EOF
}

# to allow http traffic
resource "google_compute_firewall" "default" {
  name    = "allow-http-traffic"
  network = "default"
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
  source_ranges = ["0.0.0.0/0"]
}

# to create a DNS zone
resource "google_dns_managed_zone" "dpgraham_zone" {
  name          = "dpgraham-zone"
  dns_name      = "dpgraham.com."
  description   = "DNS zone following the google create-domain-tutorial"
  force_destroy = "true"
}

# to register web-server's ip address in DNS
resource "google_dns_record_set" "tutorial_record_set" {
  name         = google_dns_managed_zone.dpgraham_zone.dns_name
  managed_zone = google_dns_managed_zone.dpgraham_zone.name
  type         = "A"
  ttl          = 300
  rrdatas = [
    google_compute_instance.default.network_interface[0].access_config[0].nat_ip
  ]
}