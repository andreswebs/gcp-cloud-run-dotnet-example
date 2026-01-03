resource "google_cloud_run_v2_service_iam_binding" "this" {
  for_each = var.iam_bindings
  project  = local.service.project
  location = local.service.location
  name     = local.service.name
  role     = each.key
  members  = each.value
}

resource "google_tags_location_tag_binding" "this" {
  for_each = var.tag_bindings
  parent = (
    "//run.googleapis.com/projects/${var.project_id}/locations/${var.region}/services/${local.service.name}"
  )
  tag_value = each.value
  location  = var.region
}
