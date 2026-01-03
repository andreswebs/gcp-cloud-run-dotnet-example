locals {
  image = "gcr.io/${var.project}/example-api:latest"
}

module "service" {
  source     = "../../modules/cloudrun-service"
  project_id = var.project
  region     = var.region
  name       = "example-api"

  service_config = {
    invoker_iam_disabled = true
  }

  containers = [
    {
      name  = "example-api"
      image = local.image
      liveness_probe = {
        http_get = {
          path = "/healthz"
        }
      }
    },
  ]

}
