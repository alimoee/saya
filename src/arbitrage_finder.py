from .exchange_client import get_price
import time
from configs import config

# Fee is now loaded from the config file.
TAKER_FEE = config.DEFAULT_TAKER_FEE

def find_arbitrage_opportunities(exchanges, symbol):
    """
    Finds arbitrage opportunities for a given symbol across a list of exchanges.

    :param exchanges: A list of exchange IDs to check.
    :param symbol: The trading symbol to check.
    :return: A list of dictionaries, where each dictionary represents an arbitrage opportunity.
    """
    prices = []
    print("Fetching prices for arbitrage check...")
    for exchange_id in exchanges:
        price = get_price(exchange_id, symbol)
        if price is not None:
            prices.append({'exchange': exchange_id, 'price': price})
        time.sleep(1) # Respect rate limits

    if len(prices) < 2:
        print("Not enough prices to compare for arbitrage.")
        return []

    print(f"\nPrices fetched: {prices}")

    opportunities = []
    # Compare every exchange with every other exchange
    for i in range(len(prices)):
        for j in range(len(prices)):
            if i == j:
                continue

            buy_exchange_data = prices[i]
            sell_exchange_data = prices[j]

            buy_price = buy_exchange_data['price']
            sell_price = sell_exchange_data['price']

            # Calculate profit percentage after fees
            # We buy on one exchange (price includes fee) and sell on another (price is reduced by fee)
            effective_buy_price = buy_price * (1 + TAKER_FEE)
            effective_sell_price = sell_price * (1 - TAKER_FEE)

            profit_percentage = ((effective_sell_price - effective_buy_price) / effective_buy_price) * 100

            if profit_percentage > 0:
                opportunity = {
                    'buy_on': buy_exchange_data['exchange'],
                    'sell_on': sell_exchange_data['exchange'],
                    'buy_price': buy_price,
                    'sell_price': sell_price,
                    'profit_percentage': round(profit_percentage, 4)
                }
                opportunities.append(opportunity)

    return opportunities

if __name__ == '__main__':
    # Load settings from the config file
    exchanges_to_check = config.EXCHANGES
    symbol_to_check = config.SYMBOL_TO_WATCH
    min_profit = config.MIN_PROFIT_PERCENTAGE

    print(f"Searching for arbitrage opportunities for {symbol_to_check} on {', '.join(exchanges_to_check)}...\n")

    found_opportunities = find_arbitrage_opportunities(exchanges_to_check, symbol_to_check)

    # In the main loop, we would filter by min_profit, but for now, we'll just print it.
    print(f"Minimum profit threshold is set to: {min_profit}%")

    if found_opportunities:
        print("\n--- Arbitrage Opportunities Found! ---")
        for opp in found_opportunities:
            print(
                f"  Buy on: {opp['buy_on'].capitalize()} at ${opp['buy_price']:,.2f}\n"
                f"  Sell on: {opp['sell_on'].capitalize()} at ${opp['sell_price']:,.2f}\n"
                f"  Estimated Profit: {opp['profit_percentage']}%\n"
                "--------------------------------------"
            )
    else:
        print("\n--- No arbitrage opportunities found at the moment. ---")
