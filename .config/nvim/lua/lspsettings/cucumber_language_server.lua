return {
  mason = false,
  settings = {
    cucumber = {
      features = { "features/**/*.feature" },
      glue = { "features/step_definitions/**/*.rb" },
    },
    features = { "features/**/*.feature" },
    glue = { "features/step_definitions/**/*.rb" },
    parameterTypes = {},
  }
}
