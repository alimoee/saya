import logging
import time
from .exchange_client import get_price

def find_spatial_arbitrage(exchanges, symbol, taker_fee):
    """
    Finds spatial arbitrage opportunities for a given symbol across a list of exchanges.
    """
    prices = []
    logging.info(f"Fetching prices for {symbol} spatial arbitrage check...")
    for exchange_id in exchanges:
        price = get_price(exchange_id, symbol)
        if price is not None:
            prices.append({'exchange': exchange_id, 'price': price})
        time.sleep(1)

    if len(prices) < 2:
        logging.warning("Not enough prices to compare for spatial arbitrage.")
        return []

    opportunities = []
    for i in range(len(prices)):
        for j in range(len(prices)):
            if i == j:
                continue

            buy_exchange_data = prices[i]
            sell_exchange_data = prices[j]

            buy_price = buy_exchange_data['price']
            sell_price = sell_exchange_data['price']

            profit_percentage = ((sell_price - buy_price) / buy_price) * 100
            # A more accurate calculation considering fees:
            # effective_buy_price = buy_price * (1 + taker_fee)
            # effective_sell_price = sell_price * (1 - taker_fee)
            # profit_percentage = ((effective_sell_price - effective_buy_price) / effective_buy_price) * 100

            # Simplified check for now
            if profit_percentage > (taker_fee * 2 * 100): # Check if profit > total fees
                opportunity = {
                    'buy_on': buy_exchange_data['exchange'],
                    'sell_on': sell_exchange_data['exchange'],
                    'buy_price': buy_price,
                    'sell_price': sell_price,
                    'profit_percentage': round(profit_percentage - (taker_fee * 2 * 100), 4)
                }
                opportunities.append(opportunity)

    return opportunities
