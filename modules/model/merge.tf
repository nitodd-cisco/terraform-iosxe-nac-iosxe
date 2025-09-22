locals {
  data_directories = flatten([
    for dir in var.yaml_directories : [
      for file in fileset(".", "${dir}/*.{yml,yaml}") : yamldecode(file(file))
    ]
  ])
  data_files = [
    for file in var.yaml_files : yamldecode(file(file))
  ]
  model         = provider::utils::merge(concat(local.data_directories, local.data_files, [var.model]))
  user_defaults = { "defaults" : try(local.model["defaults"], {}) }
  defaults      = provider::utils::merge([yamldecode(file("${path.module}/../../defaults/defaults.yaml")), local.user_defaults])["defaults"]
}

resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = length(var.yaml_directories) != 0 || length(var.yaml_files) != 0 || length(keys(var.model)) != 0
      error_message = "Either `yaml_directories`,`yaml_files` or a non-empty `model` value must be provided."
    }
  }
}

resource "local_sensitive_file" "model" {
  count    = var.write_model_file != "" ? 1 : 0
  content  = yamlencode(local.iosxe_devices)
  filename = var.write_model_file
}

resource "local_sensitive_file" "defaults" {
  count    = var.write_default_values_file != "" ? 1 : 0
  content  = yamlencode(local.defaults)
  filename = var.write_default_values_file
}
