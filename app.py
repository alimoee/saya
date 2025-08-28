import time
import logging
import threading
from flask import Flask, render_template, redirect, url_for, request, flash, get_flashed_messages
from src.utils import load_config, save_config, load_wallets, save_wallets
from src.logger_setup import setup_logger
from src.bot_engine import run_bot_cycle
from src.wallet_manager import get_eth_balance

# --- App Setup ---
app = Flask(__name__)
app.secret_key = 'supersecretkey_for_development_2'
setup_logger()

# --- Bot State Management ---
class BotState:
    def __init__(self):
        self.thread = None
        self.stop_event = threading.Event()
bot_state = BotState()

def bot_worker():
    """The target function for the bot's background thread."""
    logging.info("Bot worker thread started.")
    while not bot_state.stop_event.is_set():
        config = load_config()
        if not config:
            logging.error("Bot cycle skipped: Could not load config.")
            bot_state.stop_event.wait(30)
            continue

        run_bot_cycle()
        delay = config.get('loop_delay_seconds', 60)
        logging.info(f"Cycle complete. Waiting for {delay} seconds...")
        bot_state.stop_event.wait(delay)

    logging.info("Bot worker thread stopped.")

# --- Main Routes ---
@app.route('/')
def dashboard():
    """Renders the main dashboard page."""
    return render_template('index.html')

@app.route('/settings', methods=['GET', 'POST'])
def settings():
    """Handles both displaying and saving the configuration settings."""
    if request.method == 'POST':
        try:
            new_config = {
                'exchanges': [exc.strip() for exc in request.form['exchanges'].split(',')],
                'symbol_to_watch': request.form['symbol_to_watch'],
                'min_profit_percentage': float(request.form['min_profit_percentage']),
                'loop_delay_seconds': int(request.form['loop_delay_seconds']),
                'default_taker_fee': float(request.form['default_taker_fee'])
            }
            if save_config(new_config):
                flash("تنظیمات با موفقیت ذخیره شد.", "success")
            else:
                flash("خطا در ذخیره تنظیمات.", "error")
        except Exception as e:
            flash(f"خطای داخلی هنگام پردازش فرم: {e}", "error")
        return redirect(url_for('settings'))

    config = load_config()
    return render_template('settings.html', config=config)

# --- Bot Control Routes ---
@app.route('/start_bot')
def start_bot():
    if not bot_state.thread or not bot_state.thread.is_alive():
        logging.info("Starting bot...")
        bot_state.stop_event.clear()
        bot_state.thread = threading.Thread(target=bot_worker, daemon=True)
        bot_state.thread.start()
    return redirect(url_for('dashboard'))

@app.route('/stop_bot')
def stop_bot():
    if bot_state.thread and bot_state.thread.is_alive():
        logging.info("Stopping bot...")
        bot_state.stop_event.set()
    return redirect(url_for('dashboard'))

@app.route('/wallets')
def wallets():
    config = load_config()
    wallets = load_wallets()
    provider_url = config.get('flash_loan_settings', {}).get('web3_provider_url')

    for wallet in wallets:
        if provider_url and "YOUR_INFURA" not in provider_url:
             wallet['balance'] = get_eth_balance(provider_url, wallet['address'])
        else:
            wallet['balance'] = "Invalid Web3 Settings"
    return render_template('wallets.html', wallets=wallets)

@app.route('/add_wallet', methods=['POST'])
def add_wallet():
    wallets = load_wallets()
    wallets.append({"name": request.form['wallet_name'], "address": request.form['wallet_address']})
    save_wallets(wallets)
    return redirect(url_for('wallets'))

@app.route('/remove_wallet/<address>')
def remove_wallet(address):
    wallets = load_wallets()
    wallets = [w for w in wallets if w['address'] != address]
    save_wallets(wallets)
    return redirect(url_for('wallets'))

# --- API Endpoints for Live Data ---
@app.route('/api/status')
def api_status():
    status = "Running" if bot_state.thread and bot_state.thread.is_alive() else "Stopped"
    return {"status": status}

@app.route('/api/logs')
def api_logs():
    try:
        with open('logs/trades.log', 'r') as f:
            return "".join(f.readlines()[-50:])
    except FileNotFoundError:
        return "Log file not found."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
