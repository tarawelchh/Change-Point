library(dplyr)
library(lubridate)
library(ggplot2)
library(tidyr)
library(tseries) # for adf
library(InspectChangepoint) # for pivot
library(reshape2) # for melt
library(glue)
library(vars)
set.seed(123)

source("src/utils/load_data.R")
source("src/utils/preprocess_data.R")
source("src/methods/wald_changepoint.R")

#### clean and format data #####
clean <- clean_data(mixed_data)
n <- nrow(clean)
wide_matrix <- create_wide_matrix(clean)
dates <- wide_matrix$Date
stocks <- wide_matrix %>% dplyr::select(-Date)

log_returns <- log(1 + stocks)
final_var_matrix <- as.matrix(log_returns)
rownames(final_var_matrix) <- as.character(dates)
####

#### VAR Setup ####
p_lag <- 1
data <- make_X_tilde(final_var_matrix, p_lag)
X_t <- data$X_t
X_tilde <- data$X_tilde

resid_full <- sapply(1:ncol(stocks), function(j) {
  resid(lm(X_t[, j] ~ X_tilde))
})
rownames(resid_full) <- as.character(dates[2:length(dates)])
colnames(resid_full) <- colnames(stocks)
abs_resid <- abs(resid_full)
inspect_matrix <- t(abs_resid)
####

#### augmented dickey fuller test for stationarity ####
adf_pvals <- apply(final_var_matrix, 2, function(x) {
  adf.test(x)$p.value
})
adf_pvals
####

#### implement inspect  ####
locate.change(inspect_matrix, lambda = 5, view.cusum = TRUE, standardize.series = TRUE) # locates single changepoint, gives projection vector and plot

# multiple change point implementation with threshold
C <- 10
threshold_optimal <- (log(ncol(stocks) * log(n)))
inspect_result <- inspect((inspect_matrix), M = 1000, threshold = 10 * threshold_optimal) # empirically tuned C to have a reasonable number of changepoints
inspect_cps <- inspect_result$changepoints[, "location"]
inspect_dates <- as.Date(sapply(inspect_cps, get_dates_myone))
inspect_df <- data.frame(Dates = inspect_dates, Scores = inspect_result$changepoints[, "max.proj.cusum"])
inspect_df |> arrange(desc(Scores))
####

#### plot located change points on residual heatmap ####
resid_melt <- melt(abs_resid)
colnames(resid_melt) <- c("date", "stock", "value")
resid_melt$date <- as.Date(resid_melt$date)

ggplot(resid_melt, aes(x = date, y = stock, fill = value)) +
  geom_tile() +
  scale_fill_gradient(
    low = "white", high = "black",
    name = "Absolute\nresidual"
  ) +
  geom_vline(
    xintercept = get_dates_myone(inspect_cps),
    colour = "red", linetype = "dashed", linewidth = 0.5
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(x = "", y = "", ) +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 9))
####

#### Calculate Wald Statistic
ntime <- nrow(X_t)
d <- ncol(X_t)
dp1 <- ncol(X_tilde)
trim <- floor(0.2 * ntime)
grid <- trim:(ntime - trim)

Sigma_hat <- crossprod(resid_full) / ntime # covariance estimator
Sigma_hat_inv <- solve(Sigma_hat)

wald_stats <- sapply(grid, function(tau) {
  pi_hat <- fit_pi(X_t, X_tilde, tau)
  XtX_break <- get_xtx_break(X_tilde, tau, ntime, dp1)
  wald_dense(pi_hat, XtX_break, Sigma_hat)
})

tau_hat <- grid[which.max(wald_stats)]
print(glue("tau_hat = {tau_hat} u = {round(tau_hat/ntime, 3)}"))
# tauhat=562
resultsdf <- data.frame(days = grid, wald = wald_stats)
resultsdf$days <- sapply(resultsdf$days, get_dates_myone)
resultsdf$days <- as.Date(resultsdf$days)

ggplot(resultsdf, aes(x = days, y = wald)) +
  geom_line(color = "black") +
  labs(y = "Joint Wald Statistic") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  geom_vline(
    xintercept = as.Date(get_dates_myone(tau_hat)),
    color = "red",
    linetype = "dashed"
  ) +
  theme_minimal() +
  theme(
    axis.title.x = element_blank(),
  )

#### diagnostics ####
VARselect(final_var_matrix, lag.max = 10, type = "const")

lb_results <- apply(resid_full, 2, function(x) {
  Box.test(x, lag = 10, type = "Ljung-Box")$p.value
})
round(lb_results, 3)
####

###### CORRELATION #######
data <- wide_matrix[, -1]
break_index <- 551
data_pre <- data[1:break_index, ]
data_post <- data[break_index:nrow(wide_matrix), ]
var_pre <- vars::VAR(data_pre, p = 1, type = "const")
var_post <- vars::VAR(data_post, p = 1, type = "const")
Sigma_pre <- crossprod(residuals(var_pre)) / nrow(data[1:break_index, ])
Sigma_post <- crossprod(residuals(var_post)) / nrow(data[(break_index + 1):nrow(data), ])
cor_pre <- cov2cor(Sigma_pre)
cor_post <- cov2cor(Sigma_post)
global_min <- min(c(as.vector(cor_pre), as.vector(cor_post)))
global_max <- 1

colnames(cor_pre) <- rownames(cor_pre) <- colnames(data)
melted_pre <- melt(cor_pre)

p1 <- ggplot(melted_pre, aes(Var2, Var1, fill = value)) +
  geom_tile(colour = "white") +
  scale_fill_gradient(
    low = "white",
    high = "black",
    limits = c(global_min, global_max),
    name = "Correlation"
  ) +
  labs() +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    legend.position = "right"
  )

colnames(cor_post) <- rownames(cor_post) <- colnames(Y)
melted_post <- melt(cor_post)

p2 <- ggplot(melted_post, aes(Var2, Var1, fill = value)) +
  geom_tile(colour = "white") +
  scale_fill_gradient(
    low = "white",
    high = "black",
    limits = c(global_min, global_max),
    name = "Correlation"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    legend.position = "none"
  )

p1 + p2 +
  plot_layout(guides = "collect") &
  theme(legend.position = "right")
############
