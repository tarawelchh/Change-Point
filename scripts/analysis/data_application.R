source("scripts/binseg/binseg_var.R")
source("scripts/bottomup/bottomup_var.R")
source("scripts/slidingwindow/slidingwindow_var.R")
raw_data <- read.csv("data/psgskkke2m0wz7g9.csv", stringsAsFactors = FALSE)
library(dplyr)
library(lubridate)
library(changepoint) # for pelt
library(ggplot2)
library(moments) # to check kurtosis

get_dates_myone <- function(op) {
  if (length(op) == 0) {
    return(NULL)
  }
  return(as.Date(clean$Date[op]))
}

clean <- raw_data %>%
  mutate(
    Date = ymd(DlyCalDt),
    Return = as.numeric(DlyRet)
  )
n <- nrow(clean)

kurtosis(clean$Return) # perfect normal has kurtosis of 3

clean$Return <- log(1 + clean$Return)
mean_ret <- mean(clean$Return, na.rm = TRUE)
sd_ret <- sd(clean$Return, na.rm = TRUE)

ggplot(clean, aes(x = Return)) +
  geom_density(color = "blue", size = 0.8) +
  stat_function(
    fun = dnorm,
    args = list(mean = mean_ret, sd = sd_ret),
    color = "red", size = 1.2, linetype = "dashed"
  ) +
  theme_minimal() +
  labs(
    x = "Standardized Log Returns",
    y = "Density"
  ) +
  coord_cartesian(xlim = c(-0.05, 0.05))

global_sd <- sd(clean$Return)
global_mad <- mad(clean$Return)

ggplot(clean, aes(x = Date, y = Return)) +
  geom_line(color = "black", linewidth = 0.3) +
  labs(y = "Daily Log Returns", x = "") +
  scale_x_date(
    breaks = seq(as.Date("2018-01-01"),
      as.Date("2023-01-01"),
      by = "1 year"
    ),
    date_labels = "%Y"
  ) +
  geom_hline(yintercept = 3 * global_sd, color = "red", linetype = "dashed", size = 0.5) +
  geom_hline(yintercept = -3 * global_sd, color = "red", linetype = "dashed", size = 0.5) +
  geom_hline(yintercept = 3 * global_mad, color = "blue", size = 0.5) +
  geom_hline(yintercept = -3 * global_mad, color = "blue", size = 0.5) +
  theme_minimal()


clean$StdReturn <- clean$Return / global_mad

################## TUNING K #######
cpt_count_K <- function(K) {
  threshold <- K * log(n)
  fit <- cpt.var(clean$StdReturn,
    method = "PELT",
    penalty = "Manual", pen.value = threshold
  )

  return(length(cpts(fit)))
}

K_seq <- seq(2, 35, by = 0.1)
cpt_counts <- sapply(K_seq, cpt_count_K)

threshold_df <- data.frame(
  K = K_seq,
  changepoints = cpt_counts
)

ggplot(threshold_df, aes(x = K, y = changepoints)) +
  labs(y = "Number of Change Points", x = "K") +
  geom_line(color = "black", size = 0.5) +
  theme_minimal()

dlist <- deltalist(clean$StdReturn)
dlist2 <- dlist - min(dlist) + 0.01

dlistdf <- data.frame(x = 1:length(dlist2), y = log(dlist2))

K <- 15
c_strict <- K * log(n)
c_loose <- K * log(log(n))

ggplot(dlistdf, aes(x = x, y = y)) +
  labs(x = "Iteration", y = "Log Merge Cost") +
  geom_line(size = 0.5) +
  geom_hline(yintercept = log(c_loose), color = "red", linetype = "dashed", linewidth = 0.5) +
  geom_hline(yintercept = log(c_strict), color = "blue", linewidth = 0.5) +
  theme_minimal()

# 2 changepoints since this is the plateau - robust since there are loads of them
######################

pelt_strict <- cpt.var(clean$StdReturn,
  method = "PELT",
  penalty = "Manual", pen.value = c_strict
)
pelt_loose <- cpt.var(clean$StdReturn,
  method = "PELT",
  penalty = "Manual", pen.value = c_loose
)

get_dates <- function(cpt_model) {
  indices <- cpts(cpt_model)
  if (length(indices) == 0) {
    return("No Change Points Detected")
  }
  return(as.Date(clean$Date[indices]))
}

##### binseg bottom up pelt #########
binseg_loose_myone <- binseg_wrapper(clean$StdReturn, c_loose, minseg = 5)
binseg_strict_myone <- binseg_wrapper(clean$StdReturn, c_strict, minseg = 5)

bottomup_strict_myone <- bottom_up_variance(clean$StdReturn, c_strict)
bottomup_loose_myone <- bottom_up_variance(clean$StdReturn, c_loose)

pelt_loose_dates <- as.Date(get_dates(pelt_loose))
binseg_loose_dates <- as.Date(get_dates_myone(binseg_loose_myone$cps))
bottomup_loose_dates <- as.Date(get_dates_myone(bottomup_loose_myone$cps))

pelt_strict_dates <- get_dates(pelt_strict)
binseg_strict_dates <- get_dates_myone(binseg_strict_myone$cps)
bottomup_strict_dates <- get_dates_myone(bottomup_strict_myone$cps)

bottomup_plot_loose <- bottomup_loose_myone$costs[bottomup_loose_myone$costs != 0]
bottomup_plot_strict <- bottomup_strict_myone$costs[bottomup_strict_myone$costs != 0]


########## LOOSE SW H TUNE #########
# SLIDING WINDOW H TUNING
h_values_l <- seq(10, 120, by = 5)
eta_values_l <- seq(5, 100, by = 5)

l_results_grid <- expand.grid(h_val = h_values_l, eta_val = eta_values_l)
l_results_grid$total_breaks <- NA

for (i in 1:nrow(l_results_grid)) {
  current_h <- l_results_grid$h_val[i]
  current_eta <- l_results_grid$eta_val[i]
  l_sw <- sliding_window_vectorised(clean$StdReturn, current_eta, current_h, c_loose)
  l_results_grid[i, "total_breaks"] <- length(l_sw$cps)
}

ggplot(l_results_grid, aes(x = factor(h_val), y = factor(eta_val), fill = total_breaks)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_steps(
    low    = "white",
    high   = "black",
    name   = "Number of \nChange \nPoints",
    limits = c(0, 40),
    breaks = c(2, 4, 6, 8, 10, 20),
    guide  = guide_colorsteps(even.steps = TRUE, show.limits = TRUE)
  ) +
  # Add your thesis-ready labels
  labs(
    x = "h",
    y = "eta"
  ) +

  # Clean up the background to look professional
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(), # Removes default background lines
    plot.title = element_text(face = "bold"),
    legend.position = "right"
  )

sw_h1 <- sliding_window_vectorised(clean$StdReturn, 20, 20, c_loose)
sw_h2 <- sliding_window_vectorised(clean$StdReturn, 40, 40, c_loose)
sw_h3 <- sliding_window_vectorised(clean$StdReturn, 50, 60, c_loose)
sw_h4 <- sliding_window_vectorised(clean$StdReturn, 50, 120, c_loose)

sliding_breaks_df <- data.frame(
  BreakDate = c(get_dates_myone(sw_h1$cps), get_dates_myone(sw_h2$cps), get_dates_myone(sw_h3$cps), get_dates_myone(sw_h4$cps)),
  WindowSize = factor(c(
    rep("h = 20, eta = 20", length(sw_h1$cps)),
    rep("h = 40, eta = 40", length(sw_h2$cps)),
    rep("h = 60, eta = 50", length(sw_h3$cps)),
    rep("h = 120, eta = 50", length(sw_h4$cps))
  ), levels = c("h = 20, eta = 20", "h = 40, eta = 40", "h = 60, eta = 50", "h = 120, eta = 50")) # Levels force the order top-to-bottom
)

sliding_sensitivity <- data.frame(
  Date = rep(clean$Date, 4),
  Statistic = c(sw_h1$scores, sw_h2$scores, sw_h3$scores, sw_h4$scores),
  WindowSize = factor(rep(c("h = 20, eta = 20", "h = 40, eta = 40", "h = 60, eta = 50", "h = 120, eta = 50"), each = nrow(clean)))
)

sliding_sensitivity$WindowSize <- factor(sliding_sensitivity$WindowSize, levels = c("h = 20, eta = 20", "h = 40, eta = 40", "h = 60, eta = 50", "h = 120, eta = 50"))

ggplot(sliding_sensitivity, aes(x = Date, y = Statistic)) +
  geom_line(color = "black", linewidth = 0.4) +
  facet_grid(WindowSize ~ .) +
  geom_vline(data = sliding_breaks_df, aes(xintercept = BreakDate), color = "red", linetype = "dashed", linewidth = 0.5) +
  geom_hline(aes(yintercept = c_loose, color = "Loose"), linetype = "solid", size = 0.3) +
  # geom_hline(aes(yintercept = c_strict, color = "Strict"), linetype="dotdash", size = 0.3) +

  scale_color_manual(
    name = "Threshold Level",
    values = c("Loose" = "grey30", "Strict" = "grey30")
  ) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  theme(
    axis.title.y = element_blank(),
    axis.title.x = element_blank(),
  ) +
  labs(title = NULL, y = "GLLR Test Statistic")

######### STRICT SW H TUNE ##################
h_values_s <- seq(60, 200, by = 5)
eta_values_s <- seq(10, 200, by = 10)

s_results_grid <- expand.grid(h_val = h_values_s, eta_val = eta_values_s)
s_results_grid$total_breaks <- NA

for (i in 1:nrow(s_results_grid)) {
  current_h <- s_results_grid$h_val[i]
  current_eta <- s_results_grid$eta_val[i]
  s_sw <- sliding_window_vectorised(clean$StdReturn, current_eta, current_h, c_strict)
  s_results_grid[i, "total_breaks"] <- length(s_sw$cps)
}

ggplot(s_results_grid, aes(x = factor(h_val), y = factor(eta_val), fill = total_breaks)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_steps(
    low    = "white",
    high   = "black",
    name   = "Number of \nChange \nPoints",
    limits = c(0, max(s_results_grid$total_breaks)),
    labels = c("1", "2", "4", "8", "16", "32"),
    breaks = c(1, 2, 4, 8, 16, 32),
    guide  = guide_colorsteps(even.steps = TRUE)
  ) +
  labs(
    x = "h",
    y = "eta"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    legend.position = "right"
  )

sw_h1 <- sliding_window_vectorised(clean$StdReturn, 90, 90, c_strict)
sw_h2 <- sliding_window_vectorised(clean$StdReturn, 90, 120, c_strict)
sw_h3 <- sliding_window_vectorised(clean$StdReturn, 90, 140, c_strict)
sw_h4 <- sliding_window_vectorised(clean$StdReturn, 90, 190, c_strict)

sliding_breaks_df <- data.frame(
  BreakDate = c(get_dates_myone(sw_h1$cps), get_dates_myone(sw_h2$cps), get_dates_myone(sw_h3$cps), get_dates_myone(sw_h4$cps)),
  WindowSize = factor(c(
    rep("h = 60", length(sw_h1$cps)),
    rep("h = 80", length(sw_h2$cps)),
    rep("h = 110", length(sw_h3$cps)),
    rep("h = 160", length(sw_h4$cps))
  ), levels = c("h = 60", "h = 80", "h = 110", "h = 160"))
)

sliding_sensitivity <- data.frame(
  Date = rep(clean$Date, 4),
  Statistic = c(sw_h1$scores, sw_h2$scores, sw_h3$scores, sw_h4$scores),
  WindowSize = factor(rep(c("h = 60", "h = 80", "h = 110", "h = 160"), each = nrow(clean)))
)

sliding_sensitivity$WindowSize <- factor(sliding_sensitivity$WindowSize, levels = c("h = 60", "h = 80", "h = 110", "h = 160"))

ggplot(sliding_sensitivity, aes(x = Date, y = Statistic)) +
  geom_line(color = "black", linewidth = 0.4) +
  labs(y = "GLLR Test Statistic") +
  facet_grid(WindowSize ~ .) +
  geom_vline(data = sliding_breaks_df, aes(xintercept = BreakDate), color = "red", linetype = "dashed", linewidth = 0.5) +
  # geom_hline(aes(yintercept = c_strict, color = "Loose"), linetype="solid", size = 0.3) +
  geom_hline(aes(yintercept = c_strict), linetype = "solid", size = 0.3, color = "grey40") +
  scale_x_date(
    breaks = seq(as.Date("2018-01-01"),
      as.Date("2023-01-01"),
      by = "1 year"
    ),
    date_labels = "%Y"
  ) +
  theme_minimal() +
  theme(axis.title.x = element_blank(), ) +
  labs(title = NULL, y = "GLLR Test Statistic")

############ SW FINAL #########

slidingwindow_strict <- sliding_window_vectorised(clean$StdReturn, 90, 120, c_strict)
slidingwindow_loose <- sliding_window_vectorised(clean$StdReturn, 50, 120, c_loose)
slidingwindow_loose_dates <- as.Date(get_dates_myone(slidingwindow_loose$cps))
slidingwindow_strict_dates <- as.Date(get_dates_myone(slidingwindow_strict$cps))


######## PLOTS##########
###### loose plot #######
breaks_data_loose <- data.frame(
  BreakDate = c(pelt_loose_dates, binseg_loose_dates, bottomup_loose_dates, slidingwindow_loose_dates),
  Method = c(
    rep("PELT", length(pelt_loose_dates)),
    rep("Binary Seg", length(binseg_loose_dates)),
    rep("Bottom Up", length(bottomup_loose_dates)),
    rep("Sliding Window", length(slidingwindow_loose_dates))
  )
)
breaks_data_loose$Method <- factor(breaks_data_loose$Method, levels = c("PELT", "Binary Seg", "Bottom Up", "Sliding Window"))
ggplot(clean, aes(x = Date, y = StdReturn)) +
  geom_line(color = "black", linewidth = 0.3) +
  geom_vline(
    data = breaks_data_loose, aes(xintercept = BreakDate), color = "red",
    size = 0.5, linetype = "dashed"
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  facet_grid(Method ~ .) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    axis.title.x = element_blank(),
  )

###### strict plot ########
breaks_data_strict <- data.frame(
  BreakDate = c(pelt_strict_dates, binseg_strict_dates, bottomup_strict_dates, slidingwindow_strict_dates),
  Method = c(
    rep("PELT", length(pelt_strict_dates)),
    rep("Binary Seg", length(binseg_strict_dates)),
    rep("Bottom Up", length(bottomup_strict_dates)),
    rep("Sliding Window", length(slidingwindow_strict_dates))
  )
)
breaks_data_strict$Method <- factor(breaks_data_strict$Method, levels = c("PELT", "Binary Seg", "Bottom Up", "Sliding Window"))
ggplot(clean, aes(x = Date, y = StdReturn)) +
  geom_line(color = "black", linewidth = 0.3) +
  labs(y = "Log Returns (S&P500)") +
  geom_vline(
    data = breaks_data_strict, aes(xintercept = BreakDate), color = "red",
    size = 0.5, linetype = "dashed"
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  facet_grid(Method ~ .) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.title.x = element_blank(),
  )
