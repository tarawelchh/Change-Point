source("src/utils/plotchanges.R")
source("scripts/cusum/cusumex.R")
set.seed(123)
bottom_up_mean <- function(x, threshold, snapshot_times = c(110, NA)) {
  n <- length(x)
  snapshots <- c()
  segments <- seq(1, n, by = 2) # cant have segment length 1
  if (segments[length(segments)] != n + 1) segments <- c(segments, n + 1) # adds leftover segment tht arent multiple of 5
  deltas <- numeric(length(segments) - 2)
  iter <- 1

  merged <- FALSE
  while (!merged) {
    deltamin <- Inf
    merge_index <- 0
    for (i in 1:(length(segments) - 2)) {
      start <- segments[i]
      mid <- segments[i + 1]
      end <- segments[i + 2] - 1

      test_block <- x[start:end]
      n_block <- length(test_block)
      k_split <- mid - start

      delta <- (k_split * (n_block - k_split) / n_block) *
        (mean(test_block[1:k_split]) - mean(test_block[(k_split + 1):n_block]))^2
      if (delta < deltamin) {
        deltamin <- delta
        merge_index <- i + 1
      }
    }
    deltas[iter] <- deltamin
    iter <- iter + 1
    if (iter %in% snapshot_times) {
      snapshots[["mid"]] <- list(iter = iter, segs = segments - 1)
    }

    if (deltamin < threshold && length(segments) > 2) {
      segments <- segments[-merge_index]
    } else {
      break
      merged <- TRUE
    }
  }
  snapshots[["final"]] <- list(iter = iter, segs = segments - 1)
  return(list(
    cps = segments[c(-1, -length(segments))] - 1,
    costs = deltas, snapshots = snapshots
  ))
}

plot_snapshot <- function(x, segments, taus) {
  n <- length(x)
  df <- data.frame(t = 1:n, x = x)
  segments[1] <- 1
  seg_df <- data.frame(
    x_start = segments[-length(segments)],
    x_end = segments[-1],
    mean = sapply(seq_len(length(segments) - 1), function(i) {
      mean(x[max(segments[i], 1):segments[i + 1]])
    })
  )
  ggplot(df, aes(t, x)) +
    geom_point(colour = "grey40", shape = 1) +
    geom_segment(data = seg_df, aes(x = x_start, xend = x_end, y = mean, yend = mean), col = "blue") +
    geom_vline(xintercept = taus, col = "red", linetype = "dashed") +
    labs(x = "", y = "") +
    theme_minimal()
}

deltalist <- function(x) {
  n <- length(x)
  segments <- seq(1, n, by = 5) # cant have segment length 1
  if (segments[length(segments)] != n + 1) segments <- c(segments, n + 1) # adds leftover segment tht arent multiple of 5
  deltalist <- numeric(length(segments) - 2)
  iter <- 1

  merged <- FALSE
  while (length(segments) > 2) {
    deltamin <- Inf
    merge_index <- 0
    for (i in 1:(length(segments) - 2)) {
      start <- segments[i]
      mid <- segments[i + 1]
      end <- segments[i + 2] - 1

      test_block <- x[start:end]
      n_block <- length(test_block)
      k_split <- mid - start

      delta <- (k_split * (n_block - k_split) / n_block) *
        (mean(test_block[1:k_split]) - mean(test_block[(k_split + 1):n_block]))^2

      if (delta < deltamin) {
        deltamin <- delta
        merge_index <- i + 1
      }
    }
    deltalist[iter] <- deltamin
    iter <- iter + 1

    if (length(segments) > 2) {
      segments <- segments[-merge_index]
    } else {
      break
      merged <- TRUE
    }
  }
  return(deltalist)
}
close_threshold <- 2 * (log(250))
data <- change_in_mean_define(c(17, 20, 15, 18), c(100, 150, 250, 300))
results <- bottom_up_mean(data, close_threshold)

plot_snapshot(data, results$snapshots$mid$segs, c(100, 150, 250))
plot_snapshot(data, results$snapshots$final$segs, c(100, 150, 250))
