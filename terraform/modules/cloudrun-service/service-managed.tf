resource "google_cloud_run_v2_service" "managed" {
  count                = length(var.containers) > 0 && var.is_managed_revision ? 1 : 0
  annotations          = var.service_config.annotations
  client               = var.service_config.client
  client_version       = var.service_config.client_version
  custom_audiences     = var.service_config.custom_audiences
  description          = var.service_config.description
  deletion_protection  = var.deletion_protection
  ingress              = var.service_config.ingress
  invoker_iam_disabled = var.service_config.invoker_iam_disabled
  labels               = var.labels
  launch_stage         = var.launch_stage
  location             = var.region
  name                 = var.name
  project              = var.project_id

  template {
    execution_environment = (
      var.service_config.gen2_execution_environment
      ? "EXECUTION_ENVIRONMENT_GEN2" : "EXECUTION_ENVIRONMENT_GEN1"
    )

    labels                           = var.revision_config.labels
    encryption_key                   = var.encryption_key
    revision                         = local.revision_name
    gpu_zonal_redundancy_disabled    = var.revision_config.gpu_zonal_redundancy_disabled
    max_instance_request_concurrency = var.service_config.max_concurrency
    service_account                  = local.service_account_email
    timeout                          = var.service_config.timeout

    dynamic "node_selector" {
      for_each = var.revision_config.node_selector == null ? [] : [""]
      content {
        accelerator = var.revision_config.node_selector.accelerator
      }
    }

    dynamic "scaling" {
      for_each = var.service_config.scaling == null ? [] : [""]
      content {
        max_instance_count = var.service_config.scaling.max_instance_count
        min_instance_count = var.service_config.scaling.min_instance_count
      }
    }

    dynamic "vpc_access" {
      for_each = local.connector == null ? [] : [""]
      content {
        connector = local.connector
        egress    = try(var.revision_config.vpc_access.egress, null)
      }
    }

    dynamic "vpc_access" {
      for_each = var.revision_config.vpc_access.subnet == null && var.revision_config.vpc_access.network == null ? [] : [""]
      content {
        egress = var.revision_config.vpc_access.egress
        network_interfaces {
          subnetwork = var.revision_config.vpc_access.subnet == null ? null : lookup(
            local.ctx.subnets, var.revision_config.vpc_access.subnet,
            var.revision_config.vpc_access.subnet
          )
          network = var.revision_config.vpc_access.network == null ? null : lookup(
            local.ctx.networks, var.revision_config.vpc_access.network,
            var.revision_config.vpc_access.network
          )
          tags = var.revision_config.vpc_access.tags
        }
      }
    }

    dynamic "containers" {
      for_each = var.containers
      content {
        name       = containers.value.name
        image      = containers.value.image
        depends_on = containers.value.depends_on
        command    = containers.value.command
        args       = containers.value.args

        dynamic "env" {
          for_each = coalesce(containers.value.env, tomap({}))
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = coalesce(containers.value.env_from, tomap({}))
          content {
            name = env.key
            value_source {
              secret_key_ref {
                secret  = env.value.secret
                version = env.value.version
              }
            }
          }
        }

        dynamic "resources" {
          for_each = containers.value.resources == null ? [] : [""]
          content {
            limits            = containers.value.resources.limits
            cpu_idle          = containers.value.resources.cpu_idle
            startup_cpu_boost = containers.value.resources.startup_cpu_boost
          }
        }

        dynamic "ports" {
          for_each = coalesce(containers.value.ports, tomap({}))
          content {
            container_port = ports.value.container_port
            name           = ports.value.name
          }
        }

        dynamic "volume_mounts" {
          for_each = { for k, v in coalesce(containers.value.volume_mounts, tomap({})) : k => v if k != "cloudsql" }
          content {
            name       = volume_mounts.key
            mount_path = volume_mounts.value
          }
        }

        # CloudSQL is the last mount in the list returned by API
        dynamic "volume_mounts" {
          for_each = { for k, v in coalesce(containers.value.volume_mounts, tomap({})) : k => v if k == "cloudsql" }
          content {
            name       = volume_mounts.key
            mount_path = volume_mounts.value
          }
        }

        dynamic "liveness_probe" {
          for_each = containers.value.liveness_probe == null ? [] : [""]
          content {
            initial_delay_seconds = containers.value.liveness_probe.initial_delay_seconds
            timeout_seconds       = containers.value.liveness_probe.timeout_seconds
            period_seconds        = containers.value.liveness_probe.period_seconds
            failure_threshold     = containers.value.liveness_probe.failure_threshold
            dynamic "http_get" {
              for_each = containers.value.liveness_probe.http_get == null ? [] : [""]
              content {
                path = containers.value.liveness_probe.http_get.path
                port = containers.value.liveness_probe.http_get.port
                dynamic "http_headers" {
                  for_each = coalesce(containers.value.liveness_probe.http_get.http_headers, tomap({}))
                  content {
                    name  = http_headers.key
                    value = http_headers.value
                  }
                }
              }
            }
            dynamic "grpc" {
              for_each = containers.value.liveness_probe.grpc == null ? [] : [""]
              content {
                port    = containers.value.liveness_probe.grpc.port
                service = containers.value.liveness_probe.grpc.service
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = containers.value.startup_probe == null ? [] : [""]
          content {
            initial_delay_seconds = containers.value.startup_probe.initial_delay_seconds
            timeout_seconds       = containers.value.startup_probe.timeout_seconds
            period_seconds        = containers.value.startup_probe.period_seconds
            failure_threshold     = containers.value.startup_probe.failure_threshold
            dynamic "http_get" {
              for_each = containers.value.startup_probe.http_get == null ? [] : [""]
              content {
                path = containers.value.startup_probe.http_get.path
                port = containers.value.startup_probe.http_get.port
                dynamic "http_headers" {
                  for_each = coalesce(containers.value.startup_probe.http_get.http_headers, tomap({}))
                  content {
                    name  = http_headers.key
                    value = http_headers.value
                  }
                }
              }
            }
            dynamic "tcp_socket" {
              for_each = containers.value.startup_probe.tcp_socket == null ? [] : [""]
              content {
                port = containers.value.startup_probe.tcp_socket.port
              }
            }
            dynamic "grpc" {
              for_each = containers.value.startup_probe.grpc == null ? [] : [""]
              content {
                port    = containers.value.startup_probe.grpc.port
                service = containers.value.startup_probe.grpc.service
              }
            }
          }
        }
      }
    }

    dynamic "volumes" {
      for_each = { for k, v in var.volumes : k => v if v.cloud_sql_instances == null }
      content {
        name = volumes.key
        dynamic "secret" {
          for_each = volumes.value.secret == null ? [] : [""]
          content {
            secret       = volumes.value.secret.name
            default_mode = volumes.value.secret.default_mode
            dynamic "items" {
              for_each = volumes.value.secret.path == null ? [] : [""]
              content {
                path    = volumes.value.secret.path
                version = volumes.value.secret.version
                mode    = volumes.value.secret.mode
              }
            }
          }
        }

        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir_size == null ? [] : [""]
          content {
            medium     = "MEMORY"
            size_limit = volumes.value.empty_dir_size
          }
        }

        dynamic "gcs" {
          for_each = volumes.value.gcs == null ? [] : [""]
          content {
            bucket    = volumes.value.gcs.bucket
            read_only = volumes.value.gcs.is_read_only
          }
        }

        dynamic "nfs" {
          for_each = volumes.value.nfs == null ? [] : [""]
          content {
            server    = volumes.value.nfs.server
            path      = volumes.value.nfs.path
            read_only = volumes.value.nfs.is_read_only
          }
        }
      }
    }

    # CloudSQL is the last volume in the list returned by API
    dynamic "volumes" {
      for_each = { for k, v in var.volumes : k => v if v.cloud_sql_instances != null }
      content {
        name = volumes.key
        dynamic "cloud_sql_instance" {
          for_each = length(coalesce(volumes.value.cloud_sql_instances, [])) == 0 ? [] : [""]
          content {
            instances = volumes.value.cloud_sql_instances
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].annotations["run.googleapis.com/operation-id"],
    ]
  }
}
