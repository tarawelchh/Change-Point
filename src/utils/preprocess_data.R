library(tidyr)
library(dplyr)
library(stringr)
library(lubridate)

clean_data <- function(df) {
    clean_df <- df %>%
        mutate(across(where(is.character), ~ na_if(str_trim(.), ""))) %>%
        drop_na() %>%
        mutate(
            Date = ymd(DlyCalDt),
            Return = as.numeric(DlyRet)
        )
    return(clean_df)
}

create_wide_matrix <- function(data) {
    wide_matrix <- data %>%
        dplyr::select(Date, Ticker, Return) %>%
        pivot_wider(names_from = Ticker, values_from = Return) %>%
        arrange(Date)
    wide_matrix <- na.omit(wide_matrix)
}

get_dates_myone <- function(op) {
    if (length(op) == 0) {
        return(NULL)
    }
    return(as.Date(clean$Date[op]))
}
