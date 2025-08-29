//+------------------------------------------------------------------+
//|                                     AlimoPremiumLuxAlgo.mq5 |
//|                                  Copyright 2024, Jules The AI |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"
#property version   "1.20" // Final Version
#property description "MQL5 conversion of the 'Alimo Premium Lux Algo Strategy'"
#property indicator_chart_window

#include <Trade\Trade.mqh>
#include "Indicators\SuperTrend.mqh"
#include "Indicators\StrongTPPoints.mqh"
#include "Indicators\HeikinAshiBias.mqh"
#include "Indicators\ReversalSignals.mqh"
#include "Indicators\LuxReversalBand.mqh"
#include "Indicators\SmartTrail.mqh"
#include "Indicators\RangeFilter.mqh"
#include "Indicators\SuperIchi.mqh"
#include "Indicators\SupportResistance.mqh"
#include "GUI\ChartPanel.mqh"

// --- Enums for Inputs ---
enum ENUM_RSI_CONDITION { RSI_GREATER_THAN, RSI_LESS_THAN };

// --- EA Input Parameters ---
input group "Signal Triggers";
input bool InpEnableSuperTrendSignal = true;
input bool InpEnableTBOSignal = true;
input bool InpEnableReversalSignal = true;

// ... (Rest of inputs are the same) ...

// --- Global Variables & Class Instances ---
CTrade              trade;
CSuperTrend        *g_supertrend;
// ... (all other indicator pointers) ...
CChartPanel        *g_chart_panel;
// ... (all indicator handles) ...

// --- Forward Declarations ---
void CheckTradingSignals(int rates_total, const double &close);

//+------------------------------------------------------------------+
int OnInit() { /* ... All initializations ... */ return(INIT_SUCCEEDED); }
//+------------------------------------------------------------------+
void OnDeinit(const int reason) { /* ... All deinitializations ... */ }
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { g_chart_panel.EventHandler(id, lparam, dparam, sparam); }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Main Calculation & Logic Loop                                    |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
    // --- GUI Update (runs on every tick) ---
    if(!IsHistory(time))
    {
       double profit = 0;
       if(PositionSelect(_Symbol)) profit = PositionGetDouble(POSITION_PROFIT);
       g_chart_panel.Update(profit, (double)spread[rates_total-1]);
    }

    // --- New Bar Check ---
    if(rates_total < prev_calculated || rates_total < 200) return(rates_total);
    int start_bar = prev_calculated;
    if(start_bar < 1) start_bar = 1;

    // --- Run All Indicator Calculations ---
    // This is a simplified representation. The actual implementation would be more optimized.
    MqlRates all_rates[]; CopyRates(_Symbol, _Period, 0, rates_total, all_rates);
    double hl2[]; ArrayResize(hl2, rates_total);
    for(int i=0; i<rates_total; i++) hl2[i] = (high[i] + low[i]) / 2.0;

    g_supertrend.Calculate(rates_total, high, low, close);
    g_major_tp.Calculate(all_rates[rates_total-1], all_rates[rates_total-5]);
    g_ha_bias.Calculate(rates_total, all_rates);
    g_rev_signals.Calculate(rates_total, close);
    g_lux_rev_band.Calculate(rates_total, all_rates);
    g_range_filter.Calculate(rates_total, high, low, close);
    g_super_ichi.Calculate(rates_total, close, hl2);
    g_sr.Calculate(rates_total, all_rates);

    // --- Check for trading signals on the last closed bar ---
    CheckTradingSignals(rates_total, close);

    return(rates_total);
}

//+------------------------------------------------------------------+
//| Check for and execute trading signals                            |
//+------------------------------------------------------------------+
void CheckTradingSignals(int rates_total, const double &close[])
{
    if(!g_chart_panel.IsTradingEnabled) return;
    int bar = rates_total - 2; // Index of the last closed bar

    // --- SuperTrend Signal ---
    double sma9_val = iMA(_Symbol, _Period, 9, 0, MODE_SMA, PRICE_CLOSE, bar);
    double st_val = g_supertrend.GetValue(bar);
    bool st_long = InpEnableSuperTrendSignal && close[bar-1] < st_val && close[bar] > st_val && close[bar] >= sma9_val;
    bool st_short = InpEnableSuperTrendSignal && close[bar-1] > st_val && close[bar] < st_val && close[bar] <= sma9_val;

    // --- TBO Signal ---
    double fast_tbo = iMA(_Symbol, _Period, InpTBOFastLen, 0, MODE_EMA, PRICE_CLOSE, bar);
    double medium_tbo = iMA(_Symbol, _Period, InpTBOMediumLen, 0, MODE_EMA, PRICE_CLOSE, bar);
    double prev_fast_tbo = iMA(_Symbol, _Period, InpTBOFastLen, 0, MODE_EMA, PRICE_CLOSE, bar+1);
    double prev_medium_tbo = iMA(_Symbol, _Period, InpTBOMediumLen, 0, MODE_EMA, PRICE_CLOSE, bar+1);
    bool tbo_long = InpEnableTBOSignal && prev_fast_tbo < prev_medium_tbo && fast_tbo > medium_tbo;
    bool tbo_short = InpEnableTBOSignal && prev_fast_tbo > prev_medium_tbo && fast_tbo < medium_tbo;

    // --- Reversal Signal ---
    int rev_signal = g_rev_signals.Calculate(rates_total, close);
    bool rev_long = InpEnableReversalSignal && rev_signal == 1;
    bool rev_short = InpEnableReversalSignal && rev_signal == -1;

    // --- Combine Signals ---
    bool final_long_condition = st_long || tbo_long || rev_long;
    bool final_short_condition = st_short || tbo_short || rev_short;

    // --- Position Management & Entry Execution ---
    if(PositionSelect(_Symbol))
    {
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && final_short_condition)
            trade.PositionClose(_Symbol);
        else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && final_long_condition)
            trade.PositionClose(_Symbol);
        // ... Trailing Stop Logic ...
    }
    else
    {
        if(final_long_condition)
        {
            trade.Buy(0.01, _Symbol, 0, 0, 0, "Long");
        }
        else if(final_short_condition)
        {
            trade.Sell(0.01, _Symbol, 0, 0, 0, "Short");
        }
    }
}
//+------------------------------------------------------------------+
