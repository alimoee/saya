import logging
import requests
from web3 import Web3

def get_eth_balance(w3_provider_url, address):
    """
    Fetches the ETH balance for a given wallet address.
    """
    try:
        session = requests.Session()
        session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        })
        w3 = Web3(Web3.HTTPProvider(w3_provider_url, session=session))

        if not w3.is_connected():
            logging.error(f"Failed to connect to Web3 provider at {w3_provider_url}")
            return None

        checksum_address = w3.to_checksum_address(address)
        balance_wei = w3.eth.get_balance(checksum_address)
        balance_eth = w3.from_wei(balance_wei, 'ether')
        return float(balance_eth)

    except Exception as e:
        logging.error(f"Error fetching balance for {address}: {e}")
        return None
