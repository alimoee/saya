import pandas as pd
import pandas_ta as ta

def run_backtest():
    # --- 1. Configuration & Data Loading ---
    # Strategy Parameters
    fast_ma_period = 10
    slow_ma_period = 20
    rsi_period = 14
    rsi_overbought = 70
    rsi_oversold = 30
    adx_period = 14
    adx_threshold = 25

    # Risk Management Parameters
    initial_balance = 10000.0
    risk_per_trade_pct = 2.0
    trailing_stop_pct = 1.5

    # Load data
    try:
        df = pd.read_csv('mql5_trading_bot/data/EURUSD_1H_sample.csv')
    except FileNotFoundError:
        print("Error: Data file not found.")
        return

    # --- 2. Indicator Calculation ---
    adx_cols = (f'ADX_{adx_period}', f'DMP_{adx_period}', f'DMN_{adx_period}')

    df.ta.ema(length=fast_ma_period, append=True, col_names=(f'EMA_{fast_ma_period}',))
    df.ta.ema(length=slow_ma_period, append=True, col_names=(f'EMA_{slow_ma_period}',))
    df.ta.rsi(length=rsi_period, append=True, col_names=(f'RSI_{rsi_period}',))
    df.ta.adx(length=adx_period, append=True, col_names=adx_cols)

    df.dropna(inplace=True)
    df.reset_index(drop=True, inplace=True)

    # --- 3. Backtesting Simulation ---
    balance = initial_balance
    position = None  # Can be 'LONG', 'SHORT', or None
    entry_price = 0
    trailing_stop = 0
    trades = []

    print("--- Starting Backtest ---")
    print(f"Initial Balance: ${balance:,.2f}")
    print("-" * 25)

    for i in range(1, len(df)):
        prev = df.iloc[i-1]
        curr = df.iloc[i]

        # --- Exit and Trailing Stop Logic ---
        if position is not None:
            exit_price = 0
            exit_reason = ""

            # Crossover Exit Signal
            if position == 'LONG' and prev[f'EMA_{fast_ma_period}'] > prev[f'EMA_{slow_ma_period}'] and curr[f'EMA_{fast_ma_period}'] < curr[f'EMA_{slow_ma_period}']:
                exit_price = curr['Close']
                exit_reason = "Crossover"
            elif position == 'SHORT' and prev[f'EMA_{fast_ma_period}'] < prev[f'EMA_{slow_ma_period}'] and curr[f'EMA_{fast_ma_period}'] > curr[f'EMA_{slow_ma_period}']:
                exit_price = curr['Close']
                exit_reason = "Crossover"

            # Trailing Stop Logic
            if position == 'LONG':
                new_trailing_stop = curr['Close'] * (1 - trailing_stop_pct / 100)
                trailing_stop = max(trailing_stop, new_trailing_stop)
                if curr['Low'] <= trailing_stop:
                    exit_price = trailing_stop
                    exit_reason = "TSL"
            elif position == 'SHORT':
                new_trailing_stop = curr['Close'] * (1 + trailing_stop_pct / 100)
                trailing_stop = min(trailing_stop, new_trailing_stop)
                if curr['High'] >= trailing_stop:
                    exit_price = trailing_stop
                    exit_reason = "TSL"

            if exit_price > 0:
                profit = 0
                if position == 'LONG':
                    profit = (exit_price - entry_price) * (initial_balance * risk_per_trade_pct / 100 / entry_price)
                elif position == 'SHORT':
                    profit = (entry_price - exit_price) * (initial_balance * risk_per_trade_pct / 100 / entry_price)

                balance += profit
                trades.append({'type': position, 'entry': entry_price, 'exit': exit_price, 'profit': profit})
                print(f"Trade Closed ({exit_reason}): {position} @ {exit_price:.5f}, Profit: ${profit:,.2f}, Balance: ${balance:,.2f}")
                position = None

        # --- Entry Signals ---
        if position is None:
            # Buy Signal
            if prev[f'EMA_{fast_ma_period}'] < prev[f'EMA_{slow_ma_period}'] and curr[f'EMA_{fast_ma_period}'] > curr[f'EMA_{slow_ma_period}']:
                if curr[f'RSI_{rsi_period}'] < rsi_overbought and curr[f'ADX_{adx_period}'] > adx_threshold:
                    position = 'LONG'
                    entry_price = curr['Close']
                    trailing_stop = entry_price * (1 - trailing_stop_pct / 100)
                    print(f"Trade Opened:   LONG @ {entry_price:.5f} on {curr['Date']} {curr['Time']}")
            # Sell Signal
            elif prev[f'EMA_{fast_ma_period}'] > prev[f'EMA_{slow_ma_period}'] and curr[f'EMA_{fast_ma_period}'] < curr[f'EMA_{slow_ma_period}']:
                if curr[f'RSI_{rsi_period}'] > rsi_oversold and curr[f'ADX_{adx_period}'] > adx_threshold:
                    position = 'SHORT'
                    entry_price = curr['Close']
                    trailing_stop = entry_price * (1 + trailing_stop_pct / 100)
                    print(f"Trade Opened:   SHORT @ {entry_price:.5f} on {curr['Date']} {curr['Time']}")

    # --- Close any open trade at the end of the data ---
    if position is not None:
        exit_price = df.iloc[-1]['Close']
        profit = 0
        if position == 'LONG':
            profit = (exit_price - entry_price) * (initial_balance * risk_per_trade_pct / 100 / entry_price)
        elif position == 'SHORT':
            profit = (entry_price - exit_price) * (initial_balance * risk_per_trade_pct / 100 / entry_price)

        balance += profit
        trades.append({'type': position, 'entry': entry_price, 'exit': exit_price, 'profit': profit})
        print(f"Trade Closed (End of Data): {position} @ {exit_price:.5f}, Profit: ${profit:,.2f}, Balance: ${balance:,.2f}")

    # --- 4. Results ---
    print("\n--- Backtest Finished ---")

    if not trades:
        print("No trades were executed.")
    else:
        wins = [t for t in trades if t['profit'] > 0]
        losses = [t for t in trades if t['profit'] <= 0]
        win_rate = (len(wins) / len(trades)) * 100 if trades else 0
        total_profit = sum(t['profit'] for t in trades)

        print(f"Total Trades:   {len(trades)}")
        print(f"Winning Trades: {len(wins)}")
        print(f"Losing Trades:  {len(losses)}")
        print(f"Win Rate:       {win_rate:.2f}%")
        print(f"Total Profit:   ${total_profit:,.2f}")

    print(f"Final Balance:  ${balance:,.2f}")
    print("-" * 25)

if __name__ == "__main__":
    run_backtest()
