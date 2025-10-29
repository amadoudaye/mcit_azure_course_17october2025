resource_group_name     = "rg-webapps-foreach"
resource_group_location = "Canada Central"

webapps = {
  app1 = {
    name         = "webapp1"
    location     = "Canada Central"
    env          = "dev"
    runtime      = "PYTHON|3.11"
    app_settings = {
      FEATURE_FLAG = "on"
    }
  }
  app2 = {
    name         = "webapp2"
    location     = "Canada East"
    env          = "qa"
    runtime      = "NODE|18-lts"
    app_settings = {}
  }
}
