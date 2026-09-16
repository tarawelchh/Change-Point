library(DBI)
library(RPostgres)
library(getPass)

fetch_wrds_data <- function() {
    if (!dir.exists("data")) {
        dir.create("data")
    }

    cat("Connecting to WRDS \n")
    usr <- readline(prompt = "Enter WRDS Username: ")
    pwd <- getPass("Enter WRDS Password: ")

    con <- tryCatch(
        {
            dbConnect(
                RPostgres::Postgres(),
                host = "wrds-pgdata.wharton.upenn.edu",
                port = 9737,
                dbname = "wrds",
                sslmode = "require",
                user = usr,
                password = pwd
            )
        },
        error = function(e) {
            message("\n[Error] WRDS Authentication failed.")
            message("Please check your username and password.")
            quit(save = "no", status = 1)
        }
    )

    sql_query_mixed_stocks <- "
    SELECT
        PERMNO AS \"PERMNO\",
        HdrCUSIP AS \"HdrCUSIP\",
        Ticker AS \"Ticker\",
        PERMCO AS \"PERMCO\",
        DlyCalDt AS \"DlyCalDt\",
        DlyRet AS \"DlyRet\"
    FROM
        crsp.dsf_v2
    WHERE
        ticker IN ('AMZN', 'NFLX', 'MSFT', 'PFE', 'WMT', 'DAL', 'UAL', 'AAL', 'PG', 'XOM', 'CVX', 'JPM', 'BAC')
        AND DlyCalDt >= '2018-01-01'
        AND DlyCalDt <= '2022-12-31'
    ORDER BY
        ticker, DlyCalDt
    "

    sql_query_snp <- "
     SELECT
        PERMNO AS \"PERMNO\",
        HdrCUSIP AS \"HdrCUSIP\",
        Ticker AS \"Ticker\",
        PERMCO AS \"PERMCO\",
        DlyCalDt AS \"DlyCalDt\",
        DlyPrc AS \"DlyPrc\",
        DlyRet AS \"DlyRet\" ,
        DlyVol AS \"DlyVol\"

    FROM
        crsp.dsf_v2
    WHERE
        ticker = 'SPY'
        AND DlyCalDt >= '2018-01-01'
        AND DlyCalDt <= '2022-12-31'
    ORDER BY
        DlyCalDt
    "
    queries <- list(
        "mixed_data.csv" = sql_query_mixed_stocks,
        "snp_data.csv" = sql_query_snp
    )

    query_names <- names(queries)
    for (i in seq_along(query_names)) {
        filename <- query_names[i]
        query <- queries[[filename]]

        cat(sprintf("Executing SQL query %d of %d for %s\n", i, length(queries), filename))
        df <- dbGetQuery(con, query)
        output_path <- file.path("data", filename)
        write.csv(df, output_path, row.names = FALSE)
        cat(sprintf("Successfully saved to %s.\n\n", output_path))
    }

    dbDisconnect(con)
}

if (!file.exists("data/mixed_data.csv") || !file.exists("data/snp_data.csv")) {
    message("Data not found locally. Downloading.")
    fetch_wrds_data()
}

mixed_data <- read.csv("data/mixed_data.csv", stringsAsFactors = FALSE)
snp_data <- read.csv("data/snp_data.csv", stringsAsFactors = FALSE)
