library(ggplot2)
library(reshape2)
library(patchwork)
library(dplyr)
library(tidyr)
library(lubridate)
source("src/load_data.R")
source("src/preprocess_data.R")

clean <- clean_data(mixed_data)
n <- nrow(clean)
wide_matrix <- create_wide_matrix(clean)
data <- wide_matrix[, -1]
