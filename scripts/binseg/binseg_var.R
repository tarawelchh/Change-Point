library(glue)

LR_bs_var <- function(x, minseg) {
  n <- length(x)
  if (n < 2 * minseg) {
    return(c(tau = 0, max_LR = 0))
  }
  xsq <- x^2
  C <- cumsum(xsq)
  C_total <- C[n]
  k <- minseg:(n - minseg)
  var_left <- C[k] / k
  var_right <- (C_total - C[k]) / (n - k)
  var_total <- C_total / n

  LR <- n * log(var_total) - (k * log(var_left) + (n - k) * log(var_right))
  LR[is.na(LR) | is.infinite(LR)] <- 0
  relative_tau <- which.max(LR)
  adjusted_tau <- k[relative_tau]

  return(c(tau = adjusted_tau, max_LR = max(LR)))
}

binseg_variance <- function(x, start, end, threshold, minseg) {
  segment_data <- x[start:end]
  print(glue("searching interval {start} to {end}"))
  result <- LR_bs_var(segment_data, minseg)
  print(result["max_LR"])
  relative_tau <- result["tau"]
  max_LR <- result["max_LR"]
  print(glue("Max LR = {max_LR}"))

  if (max_LR <= threshold || relative_tau == 0) {
    return(NULL)
  }
  global_tau <- start + relative_tau - 1
  print(glue("Change point at {global_tau}"))
  left_points <- binseg_variance(x, start, global_tau, threshold, minseg)
  right_points <- binseg_variance(x, global_tau + 1, end, threshold, minseg)

  return(c(global_tau, left_points, right_points))
}

binseg_wrapper <- function(x, threshold, minseg) {
  n <- length(x)
  print(glue("threshold is {threshold}"))
  print(glue("min segment length is {minseg}"))
  changepoints <- binseg_variance(x, start = 1, end = n, threshold = threshold, minseg)

  if (is.null(changepoints)) {
    return("No changepoints found.")
  } else {
    return(list(
      cps = sort(unname(changepoints))
    ))
  }
}
