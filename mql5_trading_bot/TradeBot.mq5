//+------------------------------------------------------------------+
//|                                                     TradeBot.mq5 |
//|                                        Copyright 2024, Jules AI |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules AI"
#property link      "https://github.com/example"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include "UI.mqh"

//--- Expert Advisor input parameters
input int      fast_ma_period   = 10;      // Fast MA period
input int      slow_ma_period   = 20;      // Slow MA period
input int      rsi_period       = 14;      // RSI period
input double   rsi_overbought   = 70.0;    // RSI overbought level
input double   rsi_oversold     = 30.0;    // RSI oversold level
input int      adx_period       = 14;      // ADX period
input double   adx_threshold    = 25.0;    // ADX trend strength threshold
input double   risk_per_trade   = 2.0;     // Risk per trade in percentage
input double   trailing_stop_pips = 150;    // Trailing Stop in pips (e.g. 150 for 15 pips)

//--- Global variables
CTrade trade;
CUI    ui; // UI Class instance
bool   isAutoTradingEnabled = false; // This will be controlled by the UI button

// --- Statistics ---
int    g_total_trades = 0;
int    g_wins = 0;
double g_total_profit = 0.0;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Initialization code here ---
   Print("TradeBot EA Initialized. Strategy parameters loaded.");

   ui.Create(ChartID());
   ui.UpdateStats(g_total_trades, g_wins, g_total_profit); // Initialize panel

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Deinitialization code here ---
   Print("TradeBot EA Deinitialized. Reason: ", reason);
   ui.Destroy();
}

//+------------------------------------------------------------------+
//| Chart Event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long& lparam,
                  const double& dparam,
                  const string& sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Extract the object name prefix to handle clicks for the correct chart
      string prefix = "TradeBot_" + IntegerToString(ChartID()) + "_";
      if(sparam == prefix + "BtnAuto")
      {
         isAutoTradingEnabled = !isAutoTradingEnabled; // Toggle the state
         if(isAutoTradingEnabled)
            ui.UpdateStatus("Auto Trading is ON", clrLime);
         else
            ui.UpdateStatus("Auto Trading is OFF", clrRed);
      }
      if(sparam == prefix + "BtnReset")
      {
         ResetStats();
      }
      if(sparam == prefix + "BtnStop")
      {
         CloseAllPositions();
      }
      if(sparam == prefix + "BtnManBuy")
      {
         // Open manual buy trade if no position is open
         if(PositionsTotal() == 0)
         {
            double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double stop_loss = price - (trailing_stop_pips * _Point);
            double lot_size = CalculateLotSize(stop_loss);
            trade.Buy(lot_size, _Symbol, price, stop_loss, 0, "Manual Buy");
            Print("Manual BUY order placed.");
         }
         else { Print("Cannot place manual order, a position is already open."); }
      }
      if(sparam == prefix + "BtnManSell")
      {
         // Open manual sell trade if no position is open
         if(PositionsTotal() == 0)
         {
            double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double stop_loss = price + (trailing_stop_pips * _Point);
            double lot_size = CalculateLotSize(stop_loss);
            trade.Sell(lot_size, _Symbol, price, stop_loss, 0, "Manual Sell");
            Print("Manual SELL order placed.");
         }
         else { Print("Cannot place manual order, a position is already open."); }
      }
   }
}

//+------------------------------------------------------------------+
//| Trade Transaction function                                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      // Check if the deal is an exit
      if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
      {
         if(HistoryDealSelect(trans.deal))
         {
            if(HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT)
            {
               g_total_trades++;
               double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
               g_total_profit += profit;
               if(profit >= 0)
               {
                  g_wins++;
               }
               ui.UpdateStats(g_total_trades, g_wins, g_total_profit);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Helper: Reset Statistics                                         |
//+------------------------------------------------------------------+
void ResetStats()
{
   g_total_trades = 0;
   g_wins = 0;
   g_total_profit = 0.0;
   ui.UpdateStats(g_total_trades, g_wins, g_total_profit);
   Print("Statistics have been reset.");
}

//+------------------------------------------------------------------+
//| Helper: Close All Positions                                      |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol)
      {
         trade.PositionClose(PositionGetTicket(i));
      }
   }
   Print("Close All command executed.");
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Main logic here ---
   if(!isAutoTradingEnabled)
   {
      return; // Do nothing if auto trading is off
   }

   // --- First, check for exit signals or manage trailing stops ---
   if(PositionsTotal() > 0)
   {
      // Check for crossover exit signal
      if(CheckExitSignal())
      {
         return; // Exit occurred, wait for next tick
      }
      // If no exit, manage trailing stop
      HandleTrailingStops();
   }
   // --- If no positions are open, check for entry signals ---
   else
   {
      CheckEntrySignals();
   }
}

//+------------------------------------------------------------------+
//| Handle Trailing Stop for open positions                          |
//+------------------------------------------------------------------+
bool CheckExitSignal()
{
   // Get latest EMA values
   double ema_fast_buffer[2], ema_slow_buffer[2];
   int ema_fast_handle = iMA(_Symbol, _Period, fast_ma_period, 0, MODE_EMA, PRICE_CLOSE);
   int ema_slow_handle = iMA(_Symbol, _Period, slow_ma_period, 0, MODE_EMA, PRICE_CLOSE);
   // Corrected CopyBuffer: Start from index 0 to get current [bar 1] and previous [bar 0] data.
   if(CopyBuffer(ema_fast_handle, 0, 0, 2, ema_fast_buffer) < 2 || CopyBuffer(ema_slow_handle, 0, 0, 2, ema_slow_buffer) < 2) return false;

   double ema_fast_curr = ema_fast_buffer[0];
   double ema_fast_prev = ema_fast_buffer[1];
   double ema_slow_curr = ema_slow_buffer[0];
   double ema_slow_prev = ema_slow_buffer[1];

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol)
      {
         long type = PositionGetInteger(POSITION_TYPE);

         // Exit long position on sell crossover
         if(type == POSITION_TYPE_BUY && ema_fast_prev > ema_slow_prev && ema_fast_curr < ema_slow_curr)
         {
            trade.PositionClose(PositionGetTicket(i));
            Print("Closed BUY position on crossover.");
            return true;
         }
         // Exit short position on buy crossover
         else if(type == POSITION_TYPE_SELL && ema_fast_prev < ema_slow_prev && ema_fast_curr > ema_slow_curr)
         {
            trade.PositionClose(PositionGetTicket(i));
            Print("Closed SELL position on crossover.");
            return true;
         }
      }
   }
   return false;
}
//| Handle Trailing Stop for open positions                          |
//+------------------------------------------------------------------+
void HandleTrailingStops()
{
   if(trailing_stop_pips <= 0) return; // Trailing stop is disabled

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol)
      {
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         long type = PositionGetInteger(POSITION_TYPE);
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double current_price = SymbolInfoDouble(_Symbol, (type == POSITION_TYPE_BUY) ? SYMBOL_BID : SYMBOL_ASK);
         double current_sl = PositionGetDouble(POSITION_SL);

         if(type == POSITION_TYPE_BUY)
         {
            double new_sl = current_price - (trailing_stop_pips * _Point);
            // Check if new SL is higher than open price and also higher than the current SL
            if(new_sl > open_price && new_sl > current_sl)
            {
               if(trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP)))
               {
                  Print("Trailing Stop for BUY position #", ticket, " updated to ", new_sl);
               }
               else
               {
                  Print("Error modifying position #", ticket, ": ", GetLastError());
               }
            }
         }
         else if(type == POSITION_TYPE_SELL)
         {
            double new_sl = current_price + (trailing_stop_pips * _Point);
            // Check if new SL is lower than open price and also lower than the current SL
            if(new_sl < open_price && (current_sl == 0 || new_sl < current_sl))
            {
               if(trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP)))
               {
                  Print("Trailing Stop for SELL position #", ticket, " updated to ", new_sl);
               }
               else
               {
                  Print("Error modifying position #", ticket, ": ", GetLastError());
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check for trade entry signals                                    |
//+------------------------------------------------------------------+
void CheckEntrySignals()
{
   // --- Get Indicator Values ---
   double ema_fast_prev, ema_fast_curr;
   double ema_slow_prev, ema_slow_curr;
   double rsi_curr;
   double adx_curr;

   // Get EMA values
   int ema_fast_handle = iMA(_Symbol, _Period, fast_ma_period, 0, MODE_EMA, PRICE_CLOSE);
   int ema_slow_handle = iMA(_Symbol, _Period, slow_ma_period, 0, MODE_EMA, PRICE_CLOSE);
   double ema_fast_buffer[2], ema_slow_buffer[2];
   // Corrected to start from bar 0, for 2 bars. Data is reversed.
   if(CopyBuffer(ema_fast_handle, 0, 0, 2, ema_fast_buffer) < 2 || CopyBuffer(ema_slow_handle, 0, 0, 2, ema_slow_buffer) < 2)
   {
      Print("Error copying EMA buffers");
      return;
   }
   double ema_fast_curr = ema_fast_buffer[0]; // Current bar's value
   double ema_fast_prev = ema_fast_buffer[1]; // Previous bar's value
   double ema_slow_curr = ema_slow_buffer[0];
   double ema_slow_prev = ema_slow_buffer[1];

   // Get RSI value
   int rsi_handle = iRSI(_Symbol, _Period, rsi_period, PRICE_CLOSE);
   double rsi_buffer[1];
   if(CopyBuffer(rsi_handle, 0, 0, 1, rsi_buffer) < 1)
   {
      Print("Error copying RSI buffer");
      return;
   }
   rsi_curr = rsi_buffer[0];

   // Get ADX value
   int adx_handle = iADX(_Symbol, _Period, adx_period);
   double adx_buffer[];
   if(CopyBuffer(adx_handle, 0, 1, 1, adx_buffer) < 1)
   {
      Print("Error copying ADX buffer");
      return;
   }
   adx_curr = adx_buffer[0];


   // --- Buy Signal Logic ---
   bool is_buy_signal = ema_fast_prev < ema_slow_prev && // Crossover
                        ema_fast_curr > ema_slow_curr &&
                        rsi_curr < rsi_overbought &&     // RSI filter
                        adx_curr > adx_threshold;        // ADX trend filter

   if(is_buy_signal)
   {
      double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double stop_loss = price - (trailing_stop_pips * _Point); // Initial SL
      double take_profit = 0; // No TP, rely on trailing stop
      double lot_size = CalculateLotSize(stop_loss);

      trade.Buy(lot_size, _Symbol, price, stop_loss, take_profit, "Buy signal");
   }

   // --- Sell Signal Logic ---
   bool is_sell_signal = ema_fast_prev > ema_slow_prev && // Crossover
                         ema_fast_curr < ema_slow_curr &&
                         rsi_curr > rsi_oversold &&       // RSI filter
                         adx_curr > adx_threshold;        // ADX trend filter

   if(is_sell_signal)
   {
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double stop_loss = price + (trailing_stop_pips * _Point); // Initial SL
      double take_profit = 0; // No TP, rely on trailing stop
      double lot_size = CalculateLotSize(stop_loss);

      trade.Sell(lot_size, _Symbol, price, stop_loss, take_profit, "Sell signal");
   }
}


//+------------------------------------------------------------------+
//| Helper function to calculate lot size                            |
//+------------------------------------------------------------------+
double CalculateLotSize(double stop_loss_price)
{
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (risk_per_trade / 100.0);
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    double sl_pips = (price - stop_loss_price) / _Point;
    if(sl_pips <= 0) { sl_pips = trailing_stop_pips; } // Fallback

    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lot_size = risk_amount / (sl_pips * tick_value);

    // Normalize lot size to be within server limits
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    lot_size = floor(lot_size / step_lot) * step_lot;
    lot_size = fmax(min_lot, lot_size);
    lot_size = fmin(max_lot, lot_size);

    return lot_size;
}
//+------------------------------------------------------------------+
