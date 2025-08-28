import json
import logging

def load_config():
    """Loads the configuration from config.json."""
    try:
        with open('config.json', 'r') as f:
            return json.load(f)
    except Exception as e:
        logging.error(f"Error loading config.json: {e}")
        return None

def save_config(data):
    """Saves the configuration data to config.json."""
    try:
        with open('config.json', 'w') as f:
            json.dump(data, f, indent=4)
        return True
    except Exception as e:
        logging.error(f"Error saving config.json: {e}")
        return False

def load_wallets():
    """Loads the list of wallets from wallets.json."""
    try:
        with open('wallets.json', 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []

def save_wallets(wallets):
    """Saves the list of wallets to wallets.json."""
    try:
        with open('wallets.json', 'w') as f:
            json.dump(wallets, f, indent=4)
        return True
    except Exception as e:
        logging.error(f"Error saving wallets.json: {e}")
        return False
