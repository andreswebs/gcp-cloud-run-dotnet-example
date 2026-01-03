resource "google_service_account" "this" {
  count      = var.service_account_config.create ? 1 : 0
  project    = var.project_id
  account_id = coalesce(var.service_account_config.name, var.name)
  display_name = coalesce(
    var.service_account_config.display_name,
    var.service_account_config.name,
    var.name
  )
}

resource "google_project_iam_member" "this" {
  for_each = (
    var.service_account_config.create
    ? toset(local.service_account_roles)
    : toset([])
  )

  project = var.project_id
  role    = each.key
  member  = google_service_account.this[0].member
}
