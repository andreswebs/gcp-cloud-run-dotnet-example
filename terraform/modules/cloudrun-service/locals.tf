locals {
  connector = try(var.revision_config.vpc_access.connector, null)

  revision_name = (
    var.revision_config.name == null ? null : "${var.name}-${var.revision_config.name}"
  )

  service_account_email = (
    var.service_account_config.create
    ? google_service_account.this[0].email
    : (var.service_account_config.email == null ? null : var.service_account_config.email)
  )

  service_account_roles = distinct(compact(concat(var.service_account_default_roles, var.service_account_config.roles)))

  service = var.is_managed_revision ? try(google_cloud_run_v2_service.managed[0], null) : try(google_cloud_run_v2_service.unmanaged[0], null)
}
