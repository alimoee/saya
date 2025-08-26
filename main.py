import time
import logging
from configs import config
from src.arbitrage_finder import find_arbitrage_opportunities
from src.logger_setup import setup_logger

def main():
    """
    The main entry point for the arbitrage bot.
    """
    # Setup the logger to output to console and file
    logger = setup_logger()

    logger.info("==================================================")
    logger.info("  Arbitrage Bot Started in Simulation (Demo) Mode  ")
    logger.info("==================================================")
    logger.info(f"Watching Symbol: {config.SYMBOL_TO_WATCH}")
    logger.info(f"Checking Exchanges: {', '.join(config.EXCHANGES)}")
    logger.info(f"Minimum Profit Threshold: {config.MIN_PROFIT_PERCENTAGE}%")
    logger.info(f"Check Interval: {config.LOOP_DELAY_SECONDS} seconds")
    logger.info("Press Ctrl+C to stop the bot.")
    logger.info("--------------------------------------------------")

    try:
        while True:
            logger.info(f"Starting new arbitrage check for {config.SYMBOL_TO_WATCH}...")

            # Find opportunities
            opportunities = find_arbitrage_opportunities(config.EXCHANGES, config.SYMBOL_TO_WATCH)

            if not opportunities:
                logger.info("No arbitrage opportunities found in this cycle.")
            else:
                for opp in opportunities:
                    # Filter for opportunities that meet our minimum profit threshold
                    if opp['profit_percentage'] >= config.MIN_PROFIT_PERCENTAGE:
                        # Log the profitable opportunity
                        logger.info(f"!!! PROFITABLE ARBITRAGE OPPORTUNITY FOUND !!!")
                        logger.info(
                            f"  Buy on: {opp['buy_on'].capitalize()} at ${opp['buy_price']:,.2f} | "
                            f"Sell on: {opp['sell_on'].capitalize()} at ${opp['sell_price']:,.2f} | "
                            f"Profit: {opp['profit_percentage']}%"
                        )
                    else:
                        # Log the non-profitable opportunity for analytical purposes
                        logging.debug(
                            f"Non-profitable opportunity detected: "
                            f"Buy on {opp['buy_on']}, Sell on {opp['sell_on']}. "
                            f"Profit: {opp['profit_percentage']}% (Below threshold)"
                        )

            logger.info(f"Check complete. Waiting for {config.LOOP_DELAY_SECONDS} seconds...")
            time.sleep(config.LOOP_DELAY_SECONDS)

    except KeyboardInterrupt:
        logger.info("\n--------------------------------------------------")
        logger.info("Bot shutting down gracefully. Goodbye!")
        logger.info("==================================================")

if __name__ == "__main__":
    main()
