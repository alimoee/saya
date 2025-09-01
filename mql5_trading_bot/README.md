# MQL5 Trading Bot - AutoTrader

This folder contains a complete MQL5 Expert Advisor (EA) designed to perform automated trading based on a technical analysis strategy. It also includes the Python script used for backtesting the logic.

## Files

- `TradeBot.mq5`: The main source code file for the Expert Advisor.
- `UI.mqh`: An include file that contains all the code for the graphical user interface on the chart.
- `backtester.py`: A Python script used to develop and validate the core trading logic.
- `data/EURUSD_1H_sample.csv`: Sample data used by the Python backtester.

## How to Install and Run the Bot in MetaTrader 5

Follow these steps carefully to get the bot running on your platform.

### Step 1: Place the Files in MetaTrader 5

1.  Open your MetaTrader 5 terminal.
2.  Go to `File` -> `Open Data Folder`. This will open a new window showing the MT5 installation files.
3.  Navigate to the `MQL5` folder, and then into the `Experts` folder. The full path will look something like: `.../MQL5/Experts/`.
4.  Copy the two MQL5 files, **`TradeBot.mq5`** and **`UI.mqh`**, into this `Experts` folder.

### Step 2: Compile the Bot

1.  In your MetaTrader 5 terminal, open the MetaEditor. You can do this by pressing the **`F4`** key or by clicking the **IDE** icon in the toolbar.
2.  In the MetaEditor, look at the "Navigator" panel on the left. Expand the `Experts` folder.
3.  You should see your file `TradeBot.mq5`. **Double-click** it to open it in the editor.
4.  With the `TradeBot.mq5` file open, click the **`Compile`** button in the toolbar.
5.  Check the "Errors" tab at the bottom. If everything was done correctly, you should see `0 error(s), 0 warning(s)`. The bot is now ready.

### Step 3: Run the Bot on a Chart

1.  Go back to the main MetaTrader 5 terminal.
2.  In the "Navigator" panel (on the left), right-click on "Expert Advisors" and select **`Refresh`**.
3.  Expand the "Expert Advisors" list. You should now see your bot named **`TradeBot`**.
4.  Click and drag `TradeBot` from the Navigator onto the chart you want it to run on (e.g., a EURUSD, H1 chart).
5.  A window will pop up.
    *   In the **`Inputs`** tab, you can review and change all the strategy parameters.
    *   In the **`Common`** tab, make sure the **`Allow Algo Trading`** box is checked.
6.  Click **`OK`**.

The bot's graphical panel should now appear on your chart.

## IMPORTANT: Risk Warning

**This is a trading tool, not a money-making machine. Financial markets are risky.**

-   **ALWAYS** test this bot extensively on a **DEMO ACCOUNT** before even considering using it on a live account.
-   Past performance in the backtester or on a demo account does not guarantee future results.
-   You are solely responsible for any financial losses incurred.

---
*This bot was developed by Jules, your AI Software Engineer.*
