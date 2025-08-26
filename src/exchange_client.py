import ccxt
import time

def get_price(exchange_id, symbol):
    """
    Fetches the last price for a given symbol from a specific exchange.

    :param exchange_id: The ID of the exchange (e.g., 'binance').
    :param symbol: The trading symbol (e.g., 'BTC/USDT').
    :return: The last price as a float, or None if an error occurs.
    """
    try:
        exchange_class = getattr(ccxt, exchange_id)
        exchange = exchange_class({
            'options': {
                'adjustForTimeDifference': True,
            },
        })

        # Load markets if not already loaded to ensure the symbol is available
        if not exchange.markets:
            exchange.load_markets()

        ticker = exchange.fetch_ticker(symbol)
        return ticker['last']
    except ccxt.ExchangeNotAvailable as e:
        print(f"Exchange {exchange_id} is not available: {e}")
        return None
    except ccxt.NetworkError as e:
        print(f"Network error with {exchange_id}: {e}")
        return None
    except ccxt.BadSymbol as e:
        print(f"Symbol {symbol} not found on {exchange_id}: {e}")
        return None
    except ccxt.ExchangeError as e:
        print(f"General exchange error with {exchange_id}: {e}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred with {exchange_id}: {e}")
        return None

if __name__ == '__main__':
    # --- Example Usage ---
    # Load settings from the config file for demonstration
    from configs import config

    exchanges_to_check = config.EXCHANGES
    symbol_to_check = config.SYMBOL_TO_WATCH

    print(f"Fetching prices for {symbol_to_check} from {', '.join(exchanges_to_check)}...\n")

    for exchange_id in exchanges_to_check:
        price = get_price(exchange_id, symbol_to_check)
        if price is not None:
            print(f"  - {exchange_id.capitalize()}: ${price:,.2f}")
        else:
            print(f"  - Could not fetch price from {exchange_id.capitalize()}.")

        # A small delay to respect exchange rate limits
        time.sleep(1)
