variable "mysql_engine" {
  type = string
  validation {
    condition     = var.mysql_engine == "mysql"
    error_message = "Please ensure that the database engine is set to 'mysql'"
  }
}

variable "db_instance_class" {
  type = string
  validation {
    condition     = var.db_instance_class == "db.t3.micro"
    error_message = "The instance class '${var.db_instance_class}' is not supported.\nsupported values include 'db.t3.micro'."
  }
}

variable "db_allocated_storage" {
  type = number
  validation {
    condition     = var.db_allocated_storage > 10 && var.db_allocated_storage < 40
    error_message = "The storage allocated using db_allocated_storage is outside the range.\nPlease set value between 10 and 40."
  }
}