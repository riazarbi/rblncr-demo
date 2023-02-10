# Load libraries ----
library(rblncr)

# Set parameters from ENV variables ----
trading_mode = "paper"
alpaca_paper_key <- Sys.getenv("ALPACA_PAPER_KEY")
alpaca_paper_secret <- Sys.getenv("ALPACA_PAPER_SECRET")

alpaca_live_key <- Sys.getenv("ALPACA_LIVE_KEY")
alpaca_live_secret <- Sys.getenv("ALPACA_LIVE_SECRET")

# Create backend connections -----
t_conn <- alpaca_connect(trading_mode,
                         alpaca_paper_key,
                         alpaca_paper_secret)
d_conn <- alpaca_connect("data",
                         alpaca_live_key,
                         alpaca_live_secret)

# Read in portfolio model and rebalancing history ----
portfolio_model <- read_portfolio_model("model.yaml")
rebalance_dates_file <- "last_rebalance"

# Extract last_rebalance timestamp ----
if(file.exists(rebalance_dates_file)) {
  rebalance_dates <- readLines(rebalance_dates_file) |>
    lubridate::as_datetime()
  last_rebalance <-max(rebalance_dates)
} else {
  last_rebalance <- NULL
}

# Check cooldown period ----
still_cooldown <- !(cooldown_elapsed(last_rebalance, portfolio_model$cooldown$days))

# Balance portfolio (if cooldown elapsed) ----
if(still_cooldown) {
  message("Cooldown period still in force.")
} else {

  balanced <- FALSE
  cooldown_elapsed
  i <- 1
  attempts <- list()

  while(!balanced) {

  attempt <- balance_portfolio(portfolio_model = portfolio_model,
                                 trading_connection = t_conn,
                                 pricing_connection = d_conn,
                                 min_order_size = 1000,
                                 max_order_size = 100000,
                                 daily_vol_pct_limit = 0.02,
                                 pricing_spread_tolerance = 0.01,
                                 pricing_overrides = NULL,
                                 trader_life = 30,
                                 buy_only = FALSE,
                                 resubmit_interval = 5,
                                 verbose = TRUE)
    # Record drift change
    # (We assume you can get the order log from your broker. Else save those as well.)
    current_timestamp <- lubridate::now()
    attempt$drift |>
      dplyr::mutate(timestamp = current_timestamp) |>
      dplyr::relocate(timestamp, .before = symbol) |>
      readr::write_csv(file = "drift_changes.csv", append = TRUE)

    balanced <- attempt$portfolio_balanced

    attempts[[i]] <- attempt
    i <- i + 1

  }



  # Record rebalance date for cooldown tracking
  current_timestamp <- lubridate::now()
  nowtext <-  strftime(current_timestamp,"%Y-%m-%d %H:%M:%S")
  write(nowtext, rebalance_dates_file, append = TRUE)

  # Record current portfolio percentages
  current_balances <- get_portfolio_current(t_conn) |>
    load_portfolio_targets(portfolio_model) |>
    price_portfolio(d_conn)
  current_balances$cash |>
    dplyr::rename(symbol = currency) |>
    dplyr::bind_rows(current_balances$assets) |>
    dplyr::mutate(timestamp = current_timestamp) |>
    dplyr::select(timestamp, symbol, percent_target, percent_held) |>
    tidyr::pivot_longer(cols = c(percent_target, percent_held),
                 names_prefix = "percent_",
                 names_to = "type",
                 values_to = "percent") |>
    readr::write_csv(file = "percent_holdings.csv", append = TRUE)


}
