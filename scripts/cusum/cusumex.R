set.seed(15)
source("src/utils/plotchanges.R")
cusum <- function(x, t) {
  n <- length(x)
  l1 <- t
  l2 <- n - t

  mean1 <- mean(x[1:t]) # mean up to t
  print(mean1)
  mean2 <- mean(x[(t + 1):n]) # mean after t
  print(mean2)
  d <- sqrt(l1 * l2 / n) * (abs(mean1 - mean2))
  return(d)
}

pre_sum <- function(x) {
  n <- length(x)
  s <- numeric(n)
  s[1] <- x[1]
  for (i in 2:n) {
    s[i] <- s[i - 1] + x[i]
  }
}
cusum_vec <- function(x) {
  n <- length(x)
  t <- 1:(n - 1)
  s <- pre_sum(x)
  S <- s[n]
  m1 <- s[t] / t
  m2 <- (S - s[t]) / (n - t)
  sqrt(t * (n - t) / n) * abs(m1 - m2)
}

cusum_plot <- function(x, threshold1 = NULL, threshold2 = NULL,
                       start = 1, n = length(x)) {
  cusum <- cusum_vec(x)
  tau_hat <- which.max(cusum)

  if (!is.null(start)) {
    df <- data.frame(t = start:(start + length(cusum) - 1), d = cusum)
  } else {
    df <- data.frame(t = seq_along(cusum), d = cusum)
  }

  p <- ggplot(df, aes(t, cusum)) +
    geom_line(size = 0.3) +
    coord_cartesian(xlim = c(1, n)) +
    geom_vline(
      xintercept = tau_hat + start - 1,
      linetype = "dashed", colour = "red"
    ) +
    labs(x = "", y = "CUSUM Statistic") +
    theme_minimal()

  if (!is.null(threshold1)) {
    p <- p + geom_hline(
      yintercept = threshold1, colour = "darkgreen",
      linetype = "solid", size = 0.3
    )
  }
  if (!is.null(threshold2)) {
    p <- p + geom_hline(
      yintercept = threshold2, colour = "purple",
      linetype = "solid", size = 0.3
    )
  }

  print(p)
}

# fig 2.1
data1 <- change_in_mean_define(c(10, 20), c(100, 200))
cusum_plot(data1)

# fig2.3a
data2 <- change_in_mean_define(c(10, 11), c(100, 200))
cons_threshold <- 2 * log(300)
close_threshold <- 2 * log(log(300))

# fig2.3b
cusum_plot(data2, threshold1 = cons_threshold, threshold2 = close_threshold)

# fig2.3c
data3 <- change_in_mean_define(c(10, 12), c(100, 200))
cusum_plot(data3, threshold1 = cons_threshold, threshold2 = close_threshold)
