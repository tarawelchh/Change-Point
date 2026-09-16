set.seed(10)
library(glue)
source("~/Desktop/CPA/Final Code/plotchanges.R")
source("~/Desktop/CPA/Final Code/cusumex.R")

cusum_wrapper <- function(z, start, c, n, join = FALSE) {
  m <- length(z)
  if (m < 2) {
    return(c(tau = 0, LRtau = 0))
  }
  cusum <- cusum_vec(z)

  global_cusum <- rep(NA, n + start - 1)
  global_cusum[start:(start + m - 2)] <- cusum
  cusum_plot(z, cons_threshold, close_threshold, start, n)

  y_limits <- range(c(0, c, cusum), na.rm = TRUE)

  LRtau <- max(cusum, na.rm = TRUE)
  if (LRtau == -Inf) {
    LRtau <- 0
  }

  return(c(tau = which.max(cusum), LRtau))
}

binseg_wrapper <- function(x) {
  n <- length(x)
  c <- 2 * log((log(n)))
  changepoints <- list()
  changepoints <- binseg_mean(x, 1, n, c)
  return(changepoints)
}

binseg_mean <- function(x, start, end, c, join = FALSE) {
  print(glue("Checking interval of {start} to {end}"))
  cusum_result <- cusum_wrapper(x[start:end], start, c, length(x), join)
  relative_tau <- cusum_result[1]
  LR <- cusum_result[2]
  global_tau <- start + relative_tau - 1
  print(glue("Max tau is {global_tau}"))
  if (LR > c) {
    print(glue("Changepoint at {global_tau}, with LR statistic {LR}"))
    left_points <- binseg_mean(x, start, global_tau, c, join = TRUE)
    right_points <- binseg_mean(x, global_tau + 1, end, c, join = TRUE)
  } else {
    print("No changepoint")
    return(NULL)
  }
  return(c(global_tau, left_points, right_points))
}

mean_eg <- change_in_mean_define(c(10, 20, 30), c(100, 300, 400))
cons_threshold <- 2 * log(400)
close_threshold <- 2 * log(log(400))
binseg_wrapper(mean_eg)
