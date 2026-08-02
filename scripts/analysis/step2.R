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

source("scripts/analysis/data_application.R")

raw_data <- read.csv("data/uh9iavowosgqqkib.csv",
  stringsAsFactors = FALSE
)

clean <- raw_data %>%
  mutate(
    Date = ymd(DlyCalDt),
    Return = as.numeric(DlyRet)
  )

n <- nrow(clean)

# one col per stock
wide_matrix <- clean %>%
  dplyr::select(Date, Ticker, Return) %>%
  pivot_wider(names_from = Ticker, values_from = Return) %>%
  arrange(Date)
wide_matrix <- na.omit(wide_matrix)
dates <- wide_matrix$Date
stocks <- wide_matrix %>% dplyr::select(-Date)

log_returns <- log(1 + stocks)
final_var_matrix <- as.matrix(log_returns)
rownames(final_var_matrix) <- as.character(dates)

make_X_tilde <- function(Y, p_lag) {
  Y_embed <- embed(Y, p_lag + 1)
  X_tilde <- cbind(1, Y_embed[, (ncol(Y) + 1):ncol(Y_embed)])
  list(
    X_t     = Y_embed[, 1:ncol(Y)],
    X_tilde = X_tilde
  )
}

Y <- final_var_matrix
p_lag <- 1
data <- make_X_tilde(Y, p_lag)

adf_pvals <- apply(Y, 2, function(x) {
  adf.test(x)$p.value
})
adf_pvals

X_t <- data$X_t
X_tilde <- data$X_tilde

ntime <- nrow(X_t)
d <- ncol(X_t)
dp1 <- ncol(X_tilde)
trim <- floor(0.2 * ntime)
grid <- trim:(ntime - trim)


resid_full <- sapply(1:13, function(j) {
  resid(lm(X_t[, j] ~ X_tilde))
})

rownames(resid_full) <- dates[2:1259]
colnames(resid_full) <- colnames(stocks)
abs_resid <- abs(resid_full)

inspect_matrix <- t(abs_resid)

threshold_optimal <- (log(13 * log(n)))
inspect2 <- inspect((inspect_matrix), M = 1000, threshold = 10 * threshold_optimal)
inspect_cps <- inspect2$changepoints[, "location"]
inspect_dates <- as.Date(sapply(inspect_cps, get_dates_myone))
inspect_df <- data.frame(Dates = inspect_dates, Scores = inspect2$changepoints[, "max.proj.cusum"])
inspect_df |> arrange(desc(Scores))

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

locate.change(inspect_matrix, lambda = 5, view.cusum = TRUE, standardize.series = TRUE)
cps <- data.frame(candidates = inspect2$changepoints[, "location"], scores = inspect2$changepoints[, "max.proj.cusum"])

Sigma_hat <- crossprod(resid_full) / ntime # covariance estimator
Sigma_hat_inv <- solve(Sigma_hat)

# dp1 = dxp+1
fit_pi <- function(X_t, X_tilde, tau) {
  d <- ncol(X_t)
  ntime <- nrow(X_t)
  indicator <- c(rep(0, tau), rep(1, ntime - tau))
  XD <- cbind(X_tilde, indicator * X_tilde)

  B_hat <- sapply(1:d, function(j) {
    coef(lm(X_t[, j] ~ XD - 1))
  })
  B_hat[(dp1 + 1):(2 * dp1), ]
}

get_xtx_break <- function(X_tilde, tau, ntime, dp1) {
  indicator <- c(rep(0, tau), rep(1, ntime - tau))
  XD <- cbind(X_tilde, indicator * X_tilde)
  XtX <- crossprod(XD)
  XtX_inv <- solve(XtX)
  XtX_inv[(dp1 + 1):(2 * dp1), (dp1 + 1):(2 * dp1)]
}

wald_dense <- function(pi_hat, XtX_break, Sigma_hat) {
  b_vec <- as.vector(pi_hat)
  XtX_break_inv <- solve(XtX_break)
  V_inv <- kronecker(Sigma_hat_inv, XtX_break_inv)
  as.numeric(t(b_vec) %*% V_inv %*% b_vec)
}

# join
wald_stats <- sapply(grid, function(tau) {
  pi_hat <- fit_pi(X_t, X_tilde, tau)
  XtX_break <- get_xtx_break(X_tilde, tau, ntime, dp1)
  W <- wald_dense(pi_hat, XtX_break, Sigma_hat)
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


VARselect(Y, lag.max = 10, type = "const")

lb_results <- apply(resid_full, 2, function(x) {
  Box.test(x, lag = 10, type = "Ljung-Box")$p.value
})
round(lb_results, 3)
