locals {
  services = [
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "file.googleapis.com"
  ]
  artifact_registry_repo = "${google_artifact_registry_repository.default.location}-docker.pkg.dev/${google_artifact_registry_repository.default.project}/${google_artifact_registry_repository.default.name}"
  app_build_config       = templatefile("${path.module}/cloudbuild/app-build.cloudbuild.yaml.tftpl", {})

}
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "required" {
  project  = var.project_id
  for_each = toset(local.services)
  service  = each.value
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [google_project_service.required]

  create_duration = "30s"
}

resource "google_artifact_registry_repository" "default" {
  project       = var.project_id
  location      = "us-central1"
  repository_id = "run-filesystems"
  format        = "DOCKER"
}

resource "google_service_account" "cloud_build" {
  project      = var.project_id
  account_id   = "run-filesystems-builder"
  display_name = "Service Account for Cloud Build run filesystems stuff"
}

resource "google_project_iam_member" "builder_logwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}


resource "google_project_iam_member" "builder_builds_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}


resource "google_project_iam_member" "builder_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

resource "google_project_iam_member" "builder_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

resource "google_cloudbuild_trigger" "app_new_build" {
  project         = var.project_id
  name            = "run-filesystems-app-build"
  description     = "Initiates new build of run-filesystems"
  service_account = google_service_account.cloud_build.id
  included_files = [
    "src/**",
  ]
  github {
    name  = "run-filesystems"
    owner = "rogerthatdev"
    push {
      branch       = "^main$"
      invert_regex = false
    }
  }
  build {
    images = ["${local.artifact_registry_repo}/node-app:$${SHORT_SHA}"]
    substitutions = {
      _IMAGE = "${local.artifact_registry_repo}/node-app"
    }
    tags = []
    options {
      logging = "CLOUD_LOGGING_ONLY"
    }
    dynamic "step" {
      for_each = yamldecode(local.app_build_config).steps
      content {
        args       = step.value.args
        name       = step.value.name
        entrypoint = step.value.entrypoint
        id         = step.value.id
      }
    }
  }
}