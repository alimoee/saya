# --- General Settings ---
# List of exchange IDs from CCXT to monitor.
# Add or remove exchanges as needed.
# Make sure the exchange is supported by CCXT and available in your region.
EXCHANGES = [
    'kraken',
    'gateio',
    'bitstamp',
    # 'bittrex', # Disabled as it seems to be delisted or ID changed in CCXT.
    # 'binance', # Disabled due to regional restrictions, can be re-enabled by user.
]

# --- Symbol & Arbitrage Settings ---
# The trading symbol to watch for arbitrage opportunities.
# Format: 'BASE/QUOTE', e.g., 'BTC/USDT', 'ETH/BTC'.
SYMBOL_TO_WATCH = 'BTC/USDT'

# The minimum profit percentage to trigger an arbitrage alert.
# This should be greater than the combined fees of the two exchanges.
# e.g., 0.1 means a 0.1% profit is required.
MIN_PROFIT_PERCENTAGE = 0.1

# --- Bot Settings ---
# Delay in seconds between each arbitrage check cycle.
LOOP_DELAY_SECONDS = 60


# --- Fee Settings ---
# Default taker fee for exchanges. This is a general approximation.
# For higher accuracy, this could be expanded to a dictionary with specific fees
# per exchange, e.g., FEES = {'kraken': 0.002, 'gateio': 0.002}
DEFAULT_TAKER_FEE = 0.002  # 0.2%
