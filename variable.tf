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
