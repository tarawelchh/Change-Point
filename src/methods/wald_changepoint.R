make_X_tilde <- function(Y, p_lag) {
    Y_embed <- embed(Y, p_lag + 1)
    X_tilde <- cbind(1, Y_embed[, (ncol(Y) + 1):ncol(Y_embed)])
    list(
        X_t     = Y_embed[, 1:ncol(Y)],
        X_tilde = X_tilde
    )
}

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
