variable "application_name" {
  type = string
}

variable "privacy_service_enum" {
  type = string

  validation {
    condition = contains([
      "USER", "FORM", "LOYALTY", "SMARTPRIS", "TAXI", "EUROPA", "PUSH", "SUBSCRIPTION", "TICKET", "ID_TICKET",
      "RECEIPT", "SEAT", "KUNDEPULS", "CDP_API", "DATABRICKS"
    ], var.privacy_service_enum)
    error_message = "Invalid privacy service enum. Check the module variables"
  }
}

variable "task_role_name" {
  type = string
}