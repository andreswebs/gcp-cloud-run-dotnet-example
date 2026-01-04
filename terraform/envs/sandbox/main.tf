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
      name        = "example-api"
      image       = var.image_uri
      description = "An example .NET web api to test Datadog configuration"
      resources = {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
      liveness_probe = {
        http_get = {
          path = "/healthz"
        }
      }
      env = [
        {
          name  = "TEST"
          value = "ok"
        },
      ]
    },
    # {
    #   name        = "datadog-sidecar"
    #   image       = "gcr.io/datadoghq/serverless-init:latest"
    #   description = "Datadog sidecar"
    #   resources = {
    #     limits = {
    #       cpu    = "1"
    #       memory = "512Mi"
    #     }
    #   }
    #   env = [
    #     {
    #       name = "DD_API_KEY"
    #       value_source = {
    #         secret_key_ref = {
    #           secret = "DD_API_KEY"
    #         }
    #       }
    #     },
    #   ]
    #   health_port = 5555 # DD_HEALTH_PORT
    # },
  ]

  secrets_access = [
    "DD_API_KEY",
  ]

}
