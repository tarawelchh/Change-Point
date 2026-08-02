library(glue)
library(ggplot2)
set.seed(10)
source("src/utils/plotchanges.R")
source("scripts/cusum/cusumex.R")
source("scripts/binseg/binarysegmentation.R")

cusum_wrapper <- function(z, start, c, n, join = FALSE) {
  m <- length(z)
  if (m < 2) {
    return(list(tau = 0, LRtau = 0, cusum = numeric(0), start = start))
  }
  cusum <- cusum_vec(z)

  global_cusum <- rep(NA, n + start - 1)
  global_cusum[start:(start + m - 2)] <- cusum
  # cusum_plot(z, cons_threshold, close_threshold, start)

  # y_limits <- range(c(0, c, cusum), na.rm = TRUE)

  LRtau <- max(cusum, na.rm = TRUE)
  if (LRtau == -Inf) {
    LRtau <- 0
  }

  return(list(tau = which.max(cusum), LRtau = LRtau, cusum = cusum, start = start))
}

random_samples <- function(n, m) {
  intervals <- matrix(0,
    nrow = m,
    ncol = 2
  )
  for (i in 1:m) {
    pair <- sample(n, 2)
    intervals[i, ] <- c(min(pair), max(pair))
  }
  return(intervals)
}

wild_binseg_wrapper <- function(x) {
  n <- length(x)
  c <- 2 * log(log(n))
  endpoints <- random_samples(n, 1000)
  output <- wild_binseg_mean(x, endpoints, 1, n, c)

  for (tauhat in unique(output$curves$tau)) {
    curve_df <- subset(output$curves, tau == tauhat)
    p <- ggplot(curve_df, aes(t, cusum)) +
      geom_line() +
      geom_hline(yintercept = c, linetype = "solid", size = 0.3, colour = "purple") +
      geom_vline(xintercept = tauhat, linetype = "dashed", colour = "red") +
      coord_cartesian(xlim = c(1, n)) +
      labs(x = "", y = "CUSUM Statistic") +
      theme_minimal()
    print(p)
  }

  return(output$cps)
}

wild_binseg_mean <- function(x, endpoints, first, last, c) {
  max_endpoints <- c()
  max_LR <- 0
  max_tau <- NULL
  print(glue("Checking interval of {first} to {last}"))
  for (i in 1:(nrow(endpoints))) {
    start <- endpoints[i, 1]
    end <- endpoints[i, 2]
    if (end - start < 4 || end > last || start < first) {
      next
    }
    cusum_result <- cusum_wrapper(x[start:end], start, c, length(x))
    relative_tau <- cusum_result$tau
    LR <- cusum_result$LRtau
    global_tau <- start + relative_tau - 1
    if (LR > max_LR) {
      max_LR <- LR
      max_tau <- global_tau
      max_cusum <- cusum_result$cusum # add this
      max_start <- start # add this
      print(glue("Interval {start}-{end}, Max LR was {LR} at t={global_tau}"))
      max_endpoints <- c(start, end)
    }
  }
  if (max_LR > c) {
    curve <- data.frame(
      t = max_start:(max_start + length(max_cusum) - 1),
      cusum = max_cusum,
      tau = max_tau
    )
    print(glue("Changepoint at {max_tau}, endpoints were {max_endpoints[1]}, {max_endpoints[2]}"))
    # plot(data, ylim=c(0, 10), xlim=c(max_endpoints[1], max_endpoints[2]))
    left_points <- wild_binseg_mean(x, endpoints, first, max_tau, c)
    right_points <- wild_binseg_mean(x, endpoints, max_tau + 1, last, c)
  } else {
    return(list(cps = NULL, curves = NULL))
  }
  return(list(
    cps = c(max_tau, left_points$cps, right_points$cps),
    curves = rbind(curve, left_points$curves, right_points$curves)
  ))
}

set.seed(10)
wbs_data <- change_in_mean_define(c(20, 22, 20), c(50, 55, 150))
wild_binseg_wrapper(wbs_data)
cusum_plot(wbs_data, threshold2 = 2 * log(log(150)))
