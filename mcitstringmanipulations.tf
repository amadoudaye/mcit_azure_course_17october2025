terraform {
  required_version = ">= 0.12"
}

# -------------------
# Variables
# -------------------
variable "environments_second" {
  default = ["dev", "qa", "stage", "prod"]
}

variable "service_names_town" {
  default = ["montreal", "toronto", "calgary", "ottawa"]
}

variable "firstname" {
  default = "John"
}

variable "lastname" {
  default = "Doe"
}

variable "env_string" {
  default = "dev,qa,stage,prod"
}

# -------------------
# MCIT String Exercises
# -------------------

# MCIT Exercise 1: Concatenate first + last name
output "full_name" {
  value = "${var.firstname} ${var.lastname}"
}

# MCIT Exercise 2: Uppercase all environment names
output "uppercase_envs" {
  value = [for env in var.environments_second : upper(env)]
}

# MCIT Exercise 3: Lowercase all service names
output "lowercase_services" {
  value = [for svc in var.service_names_town : lower(svc)]
}

# MCIT Exercise 4: Length of firstname
output "firstname_length" {
  value = length(var.firstname)
}

# MCIT Exercise 5: Substring of lastname (first 3 letters)
output "lastname_substring" {
  value = substr(var.lastname, 0, 3)
}

# MCIT Exercise 6: Join service names into one string
output "services_joined" {
  value = join("-", var.service_names_town)
}

# MCIT Exercise 7: Split env_string into a list
output "split_envs" {
  value = split(",", var.env_string)
}

# MCIT Exercise 8: Replace part of a string
output "replace_city" {
  value = replace("montreal_city", "city", "town")
}

# MCIT Exercise 9: Format greeting string
output "greeting" {
  value = format("Hello %s %s, welcome to %s!", var.firstname, var.lastname, var.environments_second[0])
}

# MCIT Exercise 10: Conditional string comparison
output "is_prod" {
  value = var.environments_second[3] == "prod" ? "Production environment" : "Not production"
}
