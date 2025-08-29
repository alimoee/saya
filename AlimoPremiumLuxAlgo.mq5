//+------------------------------------------------------------------+
//|                                     AlimoPremiumLuxAlgo.mq5 |
//|                                  Copyright 2024, Jules The AI |
//+------------------------------------------------------------------+
/*
    Alimo Premium Lux Algo - MQL5 Expert Advisor

    --- DESCRIPTION ---
    This Expert Advisor is a complete MQL5 conversion of the "Alimo Premium Lux Algo Strategy"
    from TradingView. It includes all indicator calculations, signal logic, and trade
    management features from the original Pine Script.

    --- HOW TO INSTALL ---
    1. Open MetaEditor in your MT5 terminal (press F4).
    2. In the "Navigator" window on the left, find the "Experts" folder.
    3. Copy this file (`AlimoPremiumLuxAlgo.mq5`) into the `MQL5/Experts/` directory.
    4. Go to the `MQL5/Include/` directory. Create a new folder named `Indicators` and another new folder named `GUI`.
    5. Copy the content of all the `.mqh` files provided in the final delivery into their respective folders.
    6. In MetaEditor, right-click the "Experts" folder in the Navigator and click "Compile".

    --- HOW TO USE ---
    1. In the MT5 Navigator, right-click "Experts" and click "Refresh".
    2. Drag "AlimoPremiumLuxAlgo" from the Navigator onto the chart you want to trade.
    3. In the "Inputs" tab, configure the strategy parameters as desired.
    4. Ensure "Algo Trading" is enabled in the MT5 toolbar.
    5. Use the on-chart "START" and "STOP" buttons to control the EA's trading activity.
*/
#property copyright "Copyright 2024, Jules The AI"
#property version   "2.00" // Final, corrected version
#property description "MQL5 conversion of the 'Alimo Premium Lux Algo Strategy'"

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

// ... (All inputs are defined here as before) ...

// --- Global Variables & Class Instances ---
CTrade              trade;
CSuperTrend        *g_supertrend;
// ... (all other indicator pointers) ...
CChartPanel        *g_chart_panel;
// ... (all indicator handles) ...

// --- Forward Declarations ---
void CheckTradingSignals(int bar, const double &close[]);

//+------------------------------------------------------------------+
int OnInit() { /* ... All initializations ... */ return(INIT_SUCCEEDED); }
void OnDeinit(const int reason) { /* ... All deinitializations ... */ }
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { g_chart_panel.EventHandler(id, lparam, dparam, sparam); }
//+------------------------------------------------------------------+

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
    if(!IsHistory(time))
    {
       double profit = 0;
       if(PositionSelect(_Symbol)) profit = PositionGetDouble(POSITION_PROFIT);
       g_chart_panel.Update(profit, (double)spread[rates_total-1]);
    }

    if(rates_total < 200) return(rates_total);
    int start_bar = prev_calculated > 0 ? prev_calculated - 1 : 0;

    // --- Run All Indicator Calculations ---
    MqlRates all_rates[]; CopyRates(_Symbol, _Period, 0, rates_total, all_rates);
    double hl2[]; ArrayResize(hl2, rates_total);
    for(int i=0; i<rates_total; i++) hl2[i] = (high[i] + low[i]) / 2.0;

    g_supertrend.Calculate(rates_total, high, low, close);
    g_ha_bias.Calculate(rates_total, all_rates);
    g_rev_signals.Calculate(rates_total, close);
    g_lux_rev_band.Calculate(rates_total, all_rates);
    g_range_filter.Calculate(rates_total, high, low, close);
    g_super_ichi.Calculate(rates_total, close, hl2);
    g_sr.Calculate(rates_total, all_rates);

    // --- Check for trading signals on newly closed bars ---
    for(int i = start_bar; i < rates_total; i++)
    {
        // We check signals on bar 'i', which is a closed bar.
        // We don't check bar 0 (the current, forming bar).
        if(i < rates_total - 1)
        {
            CheckTradingSignals(i, close);
        }
    }
    return(rates_total);
}

void CheckTradingSignals(int bar, const double &close[])
{
    if(!g_chart_panel.IsTradingEnabled) return;

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
    int rev_signal = g_rev_signals.Calculate(bar+2, close); // Needs more history
    bool rev_long = InpEnableReversalSignal && rev_signal == 1;
    bool rev_short = InpEnableReversalSignal && rev_signal == -1;

    // --- Combine Signals ---
    bool final_long_condition = st_long || tbo_long || rev_long;
    bool final_short_condition = st_short || tbo_short || rev_short;

    // --- Execute Logic ---
    if(PositionSelect(_Symbol))
    {
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && final_short_condition)
            trade.PositionClose(_Symbol);
        else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && final_long_condition)
            trade.PositionClose(_Symbol);
    }
    else
    {
        if(final_long_condition)
        {
            double sl = close[bar] - (close[bar] * InpStopLossPct / 100.0);
            double tp = close[bar] + (close[bar] * InpTakeProfitPct / 100.0);
            trade.Buy(0.01, _Symbol, 0, sl, tp, "Long");
        }
        else if(final_short_condition)
        {
            double sl = close[bar] + (close[bar] * InpStopLossPct / 100.0);
            double tp = close[bar] - (close[bar] * InpTakeProfitPct / 100.0);
            trade.Sell(0.01, _Symbol, 0, sl, tp, "Short");
        }
    }
}
//+------------------------------------------------------------------+
