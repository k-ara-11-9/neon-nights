# install_packages.R
# Run this once to install all R packages required by the pipeline.

required_packages <- c(
  "tidyverse",    # dplyr, ggplot2, tidyr, readr, purrr, stringr
  "lubridate",    # date/time parsing
  "scales",       # axis formatting in ggplot2
  "gridExtra",    # multi-panel plot layouts
  "randomForest", # Random Forest modelling (03_advanced_modeling.R)
  "rpart",        # Decision tree modelling
  "rpart.plot",   # Decision tree visualisation
  "broom"         # Tidy model output (lm summary to data frame)
)

to_install <- required_packages[!required_packages %in% installed.packages()[, "Package"]]

if (length(to_install) > 0) {
  message("Installing missing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install)
} else {
  message("All required packages are already installed.")
}
