import ccxt
import logging

def get_price(exchange_id, symbol):
    """
    Fetches the last price for a given symbol from a specific exchange.
    """
    try:
        exchange_class = getattr(ccxt, exchange_id)
        exchange = exchange_class()

        if not exchange.markets:
            exchange.load_markets()

        ticker = exchange.fetch_ticker(symbol)
        return ticker['last']
    except Exception as e:
        logging.error(f"Error fetching ticker from {exchange_id} for {symbol}: {e}")
        return None
