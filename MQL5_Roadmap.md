# MQL5 Expert Advisor Conversion Roadmap

This document outlines the technical plan for converting the "Alimo Premium Lux Algo Strategy" from Pine Script to an MQL5 Expert Advisor (EA).

## 1. EA Input Parameters (`input` variables)

All `input.*` variables from the Pine Script will be converted into MQL5 `input` variables. This will allow for full customization and optimization in the MetaTrader Strategy Tester.

- **Main Settings:** `sensitivity`, `ShowSmartTrail`, `maj`, `enableReversal`, etc.
- **Strategy Settings:** `use_stop_loss`, `use_take_profit`, `stop_loss_pct`, `take_profit_pct`.
- **Trailing Stop Settings:** `use_trailing_stop`, `trail_activation`, `trail_offset`.
- **Indicator-Specific Settings:** All parameters for TBO, Smart Trail, Reversals, S/R, Lux Algo Bands, and MACD will be included.

## 2. Indicator & Logic Implementation Plan

Each logical block from the Pine Script will be re-coded as a separate class or function library in MQL5 for clarity and accuracy.

- **`SuperTrend`:** Create a custom indicator class using the `iATR` buffer. The logic for trend direction and stop-line calculation will be replicated.
- **`Strong TP Points (lele function)`:** This custom logic will be a function that uses `CopyHigh` and `CopyLow` to replicate `ta.highest` and `ta.lowest`.
- **`Ha Market Bias`:** Will be implemented using the built-in `iHeikinAshi` indicator, with additional `iMA` calls to replicate the smoothing.
- **`Range Filter`:** This is a complex module. I will create a dedicated class for it, implementing the conditional moving averages (`Cond_EMA`, `Cond_SMA`) and standard deviation calculations manually.
- **`SuperIchi`:** The custom `avg` function will be translated into an MQL5 function, likely using `iATR` as its base. The Tenkan, Kijun, and Senkou spans will be calculated accordingly.
- **`TBO (Trend Breakout Oscillator)`:** Will be implemented using MQL5's standard `iMA` (for EMA/SMA) and `iRSI` indicators.
- **`Smart Trail`:** The Wilder's Moving Average (`Wild_ma`) will be created using `iMA` with `MODE_SMMA`. The rest of the trailing stop logic will be implemented as a separate C++ class.
- **`Reversal Signals`:** This will use `iMA` (`MODE_SMMA`) to replicate `ta.rma` and calculate the RSI-like value.
- **`Support/Resistance`:** This logic is complex. It will be implemented as a function that analyzes historical data using `CopyHigh`, `CopyLow`, and `iFractals` to identify and cluster S/R levels.
- **`Lux Algo Reversal Band`:** Will be implemented using the standard `iKAMA` (Kaufman's Adaptive Moving Average) indicator available in MQL5.
- **`MACD Candle Coloring`:** Will use the standard `iMACD` indicator. Instead of coloring candles, the logic will be used as a filter for trade entries or as an on-screen status indicator.

## 3. Core Trading Logic

- **Entry Conditions:** The main entry signals (`bull` and `bear` conditions) will be checked in the `OnTick()` function of the EA.
  - `Long Entry:` `close` crosses over `SuperTrend` AND `close` is above `SMA(9)`.
  - `Short Entry:` `close` crosses under `SuperTrend` AND `close` is below `SMA(9)`.
- **Trade Management:** A `CTrade` class instance will be used for all trade operations.
  - **SL/TP:** Stop Loss and Take Profit will be calculated based on the input percentages and applied during the `trade.PositionOpen()` call.
  - **Trailing Stop:** A function within `OnTick()` will monitor open positions and use `trade.PositionModify()` to update the stop-loss according to the dynamic trailing stop logic.
  - **Reversal Exit:** The EA will monitor for opposing signals and close open positions using `trade.PositionClose()`.

## 4. On-Chart GUI

A dedicated class (`CGui`) will be created to manage all on-chart objects.

- **Buttons:** "Start" and "Stop" buttons will be created using `OBJ_BUTTON`. Their state will be checked in `OnChartEvent()` to toggle a global `isTradingEnabled` boolean variable.
- **Info Panel:** A background rectangle (`OBJ_RECTANGLE_LABEL`) and several text labels (`OBJ_LABEL`) will be drawn on the chart. The text will be updated in `OnTick()` to show live data.

## 5. Backtesting & Manual Override

- The final EA will be fully compatible with the MetaTrader 5 Strategy Tester.
- The EA will be programmed to only manage the SL/TP of its own trades. If a user manually adjusts the SL/TP of a trade, the EA will detect the change and will not interfere with the new levels.

This roadmap provides a comprehensive overview of the development process. Each component will be developed and tested methodically to ensure the final EA is robust, reliable, and faithful to the original strategy's logic.
