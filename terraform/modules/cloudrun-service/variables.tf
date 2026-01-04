variable "containers" {
  description = "Containers in name => attributes format."
  type = list(object({
    name       = string
    image      = string
    depends_on = optional(list(string))
    command    = optional(list(string))
    args       = optional(list(string))
    env        = optional(map(string))
    env_from = optional(map(object({
      secret  = string
      version = string
    })))
    liveness_probe = optional(object({
      grpc = optional(object({
        port    = optional(number)
        service = optional(string)
      }))
      http_get = optional(object({
        http_headers = optional(map(string))
        path         = optional(string)
        port         = optional(number)
      }))
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    ports = optional(map(object({
      container_port = optional(number)
      name           = optional(string)
    })))
    resources = optional(object({
      limits            = optional(map(string))
      cpu_idle          = optional(bool)
      startup_cpu_boost = optional(bool)
    }))
    startup_probe = optional(object({
      grpc = optional(object({
        port    = optional(number)
        service = optional(string)
      }))
      http_get = optional(object({
        http_headers = optional(map(string))
        path         = optional(string)
        port         = optional(number)
      }))
      tcp_socket = optional(object({
        port = optional(number)
      }))
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    volume_mounts = optional(map(string))
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for c in var.containers : (
        c.resources == null ? true : 0 == length(setsubtract(
          keys(lookup(c.resources, "limits", {})),
          ["cpu", "memory", "nvidia.com/gpu"]
        ))
      )
    ])
    error_message = "Only following resource limits are available: 'cpu', 'memory' and 'nvidia.com/gpu'."
  }
}

variable "deletion_protection" {
  description = "Deletion protection setting for this Cloud Run service."
  type        = bool
  default     = false
}

variable "encryption_key" {
  description = "The full resource name of the Cloud KMS CryptoKey."
  type        = string
  default     = null
}

variable "iam_bindings" {
  description = "IAM bindings for Cloud Run service in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "is_managed_revision" {
  description = "Whether the Terraform module should control the deployment of revisions."
  type        = bool
  nullable    = false
  default     = true
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "launch_stage" {
  description = "The launch stage as defined by Google Cloud Platform Launch Stages."
  type        = string
  default     = null
  validation {
    condition = (
      var.launch_stage == null ? true : contains(
        ["UNIMPLEMENTED", "PRELAUNCH", "EARLY_ACCESS", "ALPHA", "BETA",
      "GA", "DEPRECATED"], var.launch_stage)
    )
    error_message = <<EOF
    The launch stage should be one of UNIMPLEMENTED, PRELAUNCH, EARLY_ACCESS, ALPHA,
    BETA, GA, DEPRECATED.
    EOF
  }
}

variable "name" {
  description = "Name used for Cloud Run service."
  type        = string
}

variable "project_id" {
  description = "Project id used for all resources."
  type        = string
}

variable "region" {
  description = "Region used for all resources."
  type        = string
}

variable "revision_config" {
  description = "Revision template configurations."
  type = object({
    gpu_zonal_redundancy_disabled = optional(bool)
    labels                        = optional(map(string))
    name                          = optional(string)
    node_selector = optional(object({
      accelerator = string
    }))
    vpc_access = optional(object({
      connector = optional(string)
      egress    = optional(string)
      network   = optional(string)
      subnet    = optional(string)
      tags      = optional(list(string))
    }), {})
    timeout = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition = (
      try(var.revision_config.vpc_access.egress, null) == null ? true : contains(
      ["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.revision_config.vpc_access.egress)
    )
    error_message = "Egress should be one of ALL_TRAFFIC, PRIVATE_RANGES_ONLY."
  }

  validation {
    condition = (
      var.revision_config.vpc_access.network == null || (var.revision_config.vpc_access.network != null && var.revision_config.vpc_access.subnet != null)
    )
    error_message = "When providing var.revision_config.vpc_access.network provide also var.revision_config.vpc_access.subnet."
  }
}

variable "service_account_config" {
  description = "Service account configurations."
  type = object({
    create       = optional(bool, true)
    display_name = optional(string)
    email        = optional(string)
    name         = optional(string)
    roles        = optional(list(string), [])
  })
  nullable = false
  default  = {}
}

variable "service_account_default_roles" {
  description = "Service account default roles."
  type        = list(string)
  nullable    = false
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

variable "service_config" {
  description = "Cloud Run service specific configuration options."
  type = object({
    annotations                = optional(map(string), null)
    client                     = optional(string, null)
    client_version             = optional(string, null)
    custom_audiences           = optional(list(string), null)
    default_uri_disabled       = optional(bool, false)
    description                = optional(string, null)
    gen2_execution_environment = optional(bool, false)
    ingress                    = optional(string, null)
    invoker_iam_disabled       = optional(bool, false)
    max_concurrency            = optional(number)
    scaling = optional(object({
      max_instance_count = optional(number)
      min_instance_count = optional(number)
    }))
    timeout = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition = (
      var.service_config.ingress == null ? true : contains(
        ["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.service_config.ingress)
    )
    error_message = <<EOF
    Ingress should be one of INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY,
    INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER.
    EOF
  }
}

variable "tag_bindings" {
  description = "Tag bindings for this service, in key => value format."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "volumes" {
  description = "Named volumes in containers in name => attributes format."
  type = map(object({
    secret = optional(object({
      name         = string
      default_mode = optional(string)
      path         = optional(string)
      version      = optional(string)
      mode         = optional(string)
    }))
    cloud_sql_instances = optional(list(string))
    empty_dir_size      = optional(string)
    gcs = optional(object({
      # needs revision.gen2_execution_environment
      bucket       = string
      is_read_only = optional(bool)
    }))
    nfs = optional(object({
      server       = string
      path         = optional(string)
      is_read_only = optional(bool)
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.volumes :
      sum([for kk, vv in v : vv == null ? 0 : 1]) == 1
    ])
    error_message = "Only one type of volume can be defined at a time."
  }
}
