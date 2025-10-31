variable "subscription_id"{
  type=string
}
variable "client_id"{
  type=string
}
variable "client_secret"{
  type=string
}
variable "tenant_id"{
  type=string
}
variable "testvariable"{
  type=string
  default="Hello MCIT!"
}
variable "testnumber"{
  type=number
  default=1
}
variable "testliststring"{
  type=list(string)
  default=["montreal","toronto","calgary"]
}
variable "storage_account_name"{
  type=string
  default="mcitoctostorage"
}
variable "account_tier"{
  type=string
  default="Standard"
}
variable "account_replication_type"{
  type=string
  default="GRS"
}
variable "environment"{
  type=string
  default="production"
}
variable "admin_username" {
  description = "Admin username for the Linux VM"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password for the Linux VM"
  type        = string
  sensitive   = true
}
