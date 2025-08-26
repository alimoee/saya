import logging
import os

def setup_logger():
    """
    Sets up the root logger to output to both console and a file.
    """
    # Create logs directory if it doesn't exist
    if not os.path.exists('logs'):
        os.makedirs('logs')

    # Get the root logger
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    # Prevent adding handlers multiple times if this function is called more than once
    if logger.hasHandlers():
        logger.handlers.clear()

    # Create a file handler to log trades and significant events
    file_handler = logging.FileHandler('logs/trades.log', mode='a')
    file_handler.setLevel(logging.INFO)

    # Create a console handler for general output
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)

    # Create a formatter and set it for both handlers
    # Example format: 2023-10-27 15:30:00,123 - INFO - Your log message
    formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)

    # Add the handlers to the root logger
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    return logger
