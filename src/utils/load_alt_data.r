library(quantmod)
library(PerformanceAnalytics)
library(tidyr)

yahoo_fallback_data <- function(tickers, start_date = "2018-01-01", end_date = "2022-12-31") {
    data_env <- new.env()
    getSymbols(tickers, src = "yahoo", from = start_date, to = end_date, env = data_env)
    prices_list <- eapply(data_env, function(x) Ad(x))
    price_matrix <- do.call(merge, prices_list)
    names(price_matrix) <- gsub(".Adjusted", "", names(price_matrix))
    returns_matrix <- Return.calculate(price_matrix, method = "discrete")
    returns_matrix <- na.omit(returns_matrix)
    returns_matrix <- data.frame(DlyCalDt = index(returns_matrix), returns_matrix)
    returns_df <- pivot_longer(
        data = returns_matrix,
        cols = -DlyCalDt, # This tells R to pivot everything EXCEPT the date column
        names_to = "Ticker", # The new column that will hold the ticker symbols
        values_to = "DlyRet" # The new column that will hold the returns
    )


    return(as.data.frame(returns_df))
}
