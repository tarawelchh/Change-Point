set.seed(123)
library(ggplot2)

change_in_mean_define <- function(mus, taus) {
  if (length(mus) != length(taus)) stop("mismatched lengths")

  lens <- diff(c(0, taus))
  full_series <- rep(mus, lens) + rnorm(sum(lens))
  for (i in seq_along(mus)) {
    cat(sprintf(
      "Segment %d: Mean = %g, Tau = %d, Length = %d\n",
      i, mus[i], taus[i], lens[i]
    ))
  }

  df <- data.frame(t = seq_along(full_series), x = full_series)
  changepoints <- taus[-length(taus)]

  seg_df <- data.frame(
    x_start = c(0, taus[-length(taus)]),
    x_end = taus,
    y = mus
  )

  p <- ggplot(df, aes(t, x)) +
    geom_point(shape = 1) +
    geom_segment(
      data = seg_df,
      aes(x = x_start, xend = x_end, y = y, yend = y),
      colour = "blue"
    ) +
    geom_vline(xintercept = changepoints, linetype = "dashed", col = "red") +
    labs(x = NULL, y = NULL) +
    theme_minimal()
  print(p)

  # starts <- c(0, taus[-length(taus)])
  # segments(x0 = starts, x1 = taus, y0 = mus, y1 = mus, col = "blue")
  # if (length(taus) > 1) abline(v = taus[-length(taus)], lty = 2, col = "red")
  return(full_series)
}

change_in_var_define <- function(sigmas, taus, mu = 0) {
  if (length(sigmas) != length(taus)) stop("mismatched lengths")
  if (any(sigmas <= 0)) stop("sigmas must be positive")

  lens <- diff(c(0, taus))
  full_series <- mu + rnorm(sum(lens), sd = rep(sigmas, lens))

  for (i in seq_along(sigmas)) {
    cat(sprintf(
      "Segment %d: SD = %g, Tau = %d, Length = %d\n",
      i, sigmas[i], taus[i], lens[i]
    ))
  }
  df <- data.frame(t = seq_along(full_series), x = full_series)
  changepoints <- taus[-length(taus)]

  p <- ggplot(df, aes(t, x)) +
    geom_point(shape = 1) +
    geom_vline(xintercept = changepoints, linetype = "dashed", col = "red") +
    annotate("segment",
      x = 0, xend = length(full_series),
      y = mu, yend = mu, col = "blue"
    ) +
    labs(x = NULL, y = NULL) +
    theme_minimal()
  print(p)
  return(full_series)
}

change_in_both_simul_define <- function(sigmas, mus, taus) {
  if (length(sigmas) != length(taus) || length(mus) != length(taus)) {
    stop("mismatched lengths")
  }

  if (any(sigmas <= 0)) stop("sigmas must be positive")

  lens <- diff(c(0, taus))

  full_series <- rnorm(sum(lens), mean = rep(mus, lens), sd = rep(sigmas, lens))

  for (i in seq_along(sigmas)) {
    cat(sprintf(
      "Segment %d: SD = %g, Tau = %d, Length = %d, Mu=%d\n",
      i, sigmas[i], taus[i], lens[i], mus[i]
    ))
  }

  df <- data.frame(t = seq_along(full_series), x = full_series)
  changepoints <- taus[-length(taus)]

  seg_df <- data.frame(
    x_start = c(0, taus[-length(taus)]), x_end = taus, y1 = mus, y2 = sigmas
  )

  p <- ggplot(df, aes(t, x)) +
    geom_point(shape = 1) +
    geom_vline(xintercept = changepoints, linetype = "dashed", col = "red") +
    geom_segment(
      data = seg_df,
      aes(x = x_start, xend = x_end, y = y1, yend = y1),
      colour = "blue"
    ) +
    labs(x = NULL, y = NULL) +
    theme_minimal()
  print(p)
  return(full_series)
}

# figure 2.1a
change_in_mean_define(c(10, 20), c(200, 500))
# figure 2.1b
change_in_var_define(c(1, 4), c(200, 500), mu = 10)
# figure 2.1c
change_in_both_simul_define(c(1, 4), c(10, 20), c(200, 500))
