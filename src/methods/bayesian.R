set.seed(123)
library(ggplot2)
source("src/utils/plotchanges.R")
n <- 100
true_tau <- 50
mu1 <- 3
mu2 <- 5
sigma2 <- 1
m0 <- 0
v0 <- 10

log_posterior <- function(tau, x, m0, v0) {
  n <- length(x) # Changed to lowercase x
  if (tau < 1 || tau >= n) {
    return(-Inf)
  }

  x1 <- x[1:tau] # Changed to lowercase x
  v1 <- 1 / (1 / v0 + tau)
  m1 <- v1 * (m0 / v0 + sum(x1))

  x2 <- x[(tau + 1):n] # Changed to lowercase x
  v2 <- 1 / (1 / v0 + (n - tau))
  m2 <- v2 * (m0 / v0 + sum(x2))

  return(0.5 * log(v1 * v2) - 0.5 * (sum((x1 - m1)^2) + sum((x2 - m2)^2) + ((m1 - m0)^2 + (m2 - m0)^2) / v0))
}
data <- change_in_mean_define(c(3, 5), c(50, 100))
data2 <- change_in_mean_define(c(3, 3.5), c(50, 100))

# Renamed the first argument to 'true_tau' to make its purpose clear
plot_posterior <- function(true_tau, data) {
  x <- data
  n <- length(x) # It is safer to calculate n dynamically here
  k <- 1:(n - 1)

  # Calculate the posterior for EVERY point in the sequence 'k'
  log_post <- sapply(
    k,
    function(t) log_posterior(t, x = x, m0 = m0, v0 = v0)
  )

  log_post_centered <- log_post - max(log_post)
  posterior <- exp(log_post_centered) / sum(exp(log_post_centered))

  posterior_df <- data.frame(posterior = posterior, index = k)

  ggplot(data = posterior_df, aes(x = index, y = posterior)) +
    geom_line() +
    # Use the passed true_tau for the xintercept
    geom_vline(xintercept = true_tau, col = "red", linetype = "dashed") +
    labs(x = "Index", y = "Posterior Probability of Change Point") +
    theme_minimal()
}

plot_posterior(50, data)
plot_posterior(50, data2)
