import time
import logging
from .utils import load_config
from .arbitrage_finder import find_spatial_arbitrage
from .logger_setup import setup_logger

def run_bot_cycle():
    """
    Runs a single cycle of the spatial arbitrage bot logic.
    """
    logger = logging.getLogger()
    config = load_config()
    if not config:
        logger.error("Bot cycle skipped: Could not load config.")
        return

    logger.info(f"Running spatial arbitrage check for {config['symbol_to_watch']}...")

    opportunities = find_spatial_arbitrage(
        config['exchanges'],
        config['symbol_to_watch'],
        config['default_taker_fee']
    )

    if not opportunities:
        logger.info("No spatial arbitrage opportunities found in this cycle.")
    else:
        for opp in opportunities:
            if opp['profit_percentage'] >= config['min_profit_percentage']:
                logger.info(f"!!! PROFITABLE SPATIAL OPPORTUNITY FOUND !!!")
                logger.info(opp)
                # In the future, we would log this to a trade history file.

def main_cli_runner():
    """
    A simple command-line runner for the bot engine for testing purposes.
    """
    setup_logger()
    config = load_config()
    if not config:
        logging.error("Could not load configuration. Exiting.")
        return

    try:
        while True:
            run_bot_cycle()
            delay = config.get('loop_delay_seconds', 60)
            logging.info(f"Cycle complete. Waiting for {delay} seconds...")
            time.sleep(delay)
    except KeyboardInterrupt:
        logging.info("Bot stopped by user.")

if __name__ == "__main__":
    main_cli_runner()
