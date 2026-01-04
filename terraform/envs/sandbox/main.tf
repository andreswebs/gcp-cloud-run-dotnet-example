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
      image = var.image_uri
      liveness_probe = {
        http_get = {
          path = "/healthz"
        }
      }
      env = [
        # {
        #   name  = "TEST"
        #   value = "ok"
        # },
        {
          name = "TEST"
          value_source = {
            secret_key_ref = {
              secret = "TEST"
            }
          }
        },
      ]
    },
  ]

  secrets_access = [
    "TEST",
  ]

}
