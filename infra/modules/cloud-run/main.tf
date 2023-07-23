resource "google_cloud_run_v2_service" "default" {
  name     = var.name
  location = var.region

  template {
    containers {
      ports {
        container_port = var.port
      }
      image = var.image
    }
    vpc_access {
      connector = var.vpc_connector
      egress    = "ALL_TRAFFIC"
    }
    scaling {
      # Limit scale up to prevent any cost blow outs!
      max_instance_count = var.max_count
    }
  }
}

data "google_iam_policy" "no_auth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "no_auth" {
  location = google_cloud_run_v2_service.default.location
  project  = google_cloud_run_v2_service.default.project
  service  = google_cloud_run_v2_service.default.name

  policy_data = data.google_iam_policy.no_auth.policy_data
}