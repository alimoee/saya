//+------------------------------------------------------------------+
//|                                                  SmartTrail.mqh |
//|                                  Copyright 2024, Jules The AI |
//|          MQL5 implementation of the Smart Trail indicator        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

//+------------------------------------------------------------------+
//| CSmartTrail Class                                                |
//+------------------------------------------------------------------+
class CSmartTrail
{
private:
    // --- Settings ---
    int m_atr_period;
    double m_atr_factor;
    // Note: Smoothing is for the plot, not implemented in core logic yet

    // --- Buffers ---
    double m_trail_buf[];
    int m_trend_buf[];

    int m_rates_total;

public:
    // --- Constructor ---
    CSmartTrail(void);

    // --- Initialization ---
    bool Init(int atr_period, double atr_factor);

    // --- Calculation ---
    int Calculate(int rates_total, const MqlRates &rates[]);

    // --- Access Methods ---
    double GetValue(int shift) { if(shift < m_rates_total) return m_trail_buf[shift]; return 0; }
    int GetTrend(int shift) { if(shift < m_rates_total) return m_trend_buf[shift]; return 0; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSmartTrail::CSmartTrail(void) : m_atr_period(0),
                                 m_atr_factor(0),
                                 m_rates_total(0)
{
}

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
bool CSmartTrail::Init(int atr_period, double atr_factor)
{
    m_atr_period = atr_period;
    m_atr_factor = atr_factor;
    return(true);
}

//+------------------------------------------------------------------+
//| Calculation method                                               |
//+------------------------------------------------------------------+
int CSmartTrail::Calculate(int rates_total, const MqlRates &rates[])
{
    if(rates_total < m_atr_period + 1) return 0;
    m_rates_total = rates_total;

    // --- Resize buffers ---
    ArrayResize(m_trail_buf, rates_total);
    ArrayResize(m_trend_buf, rates_total);

    // --- Intermediate buffers ---
    double wild_ma_buf[];
    ArrayResize(wild_ma_buf, rates_total);
    double trend_up_buf[];
    ArrayResize(trend_up_buf, rates_total);
    double trend_down_buf[];
    ArrayResize(trend_down_buf, rates_total);

    // --- Calculate custom True Range and its Wilder's MA ---
    double alpha = 1.0 / m_atr_period;
    for(int i = 1; i < rates_total; i++)
    {
        // Pine: HiLo = math.min(norm_h - norm_l, 1.5 * nz(ta.sma(norm_h - norm_l, ATRPeriod)))
        // This part is complex to do efficiently. Using standard TR for now as per 'unmodified' type.
        // The 'modified' type requires another indicator (SMA of H-L) and is a significant complication.
        // For now, we implement the 'unmodified' logic from the Pine Script.
        double tr = MathMax(rates[i].high, rates[i-1].close) - MathMin(rates[i].low, rates[i-1].close);

        // Wilder's MA (SMMA) of True Range
        wild_ma_buf[i] = tr * alpha + wild_ma_buf[i-1] * (1 - alpha);

        double loss = m_atr_factor * wild_ma_buf[i];

        double up_val = rates[i].close - loss;
        double dn_val = rates[i].close + loss;

        // Pine: TrendUp := norm_c[1] > TrendUp[1] ? math.max(Up, TrendUp[1]) : Up
        trend_up_buf[i] = (i > 0 && rates[i-1].close > trend_up_buf[i-1]) ? MathMax(up_val, trend_up_buf[i-1]) : up_val;

        // Pine: TrendDown := norm_c[1] < TrendDown[1] ? math.min(Dn, TrendDown[1]) : Dn
        trend_down_buf[i] = (i > 0 && rates[i-1].close < trend_down_buf[i-1]) ? MathMin(dn_val, trend_down_buf[i-1]) : dn_val;

        // Pine: Trend := norm_c > TrendDown[1] ? 1 : norm_c < TrendUp[1] ? -1 : nz(Trend[1], 1)
        if(i == 0) m_trend_buf[i] = 1;
        else if(rates[i].close > trend_down_buf[i-1]) m_trend_buf[i] = 1;
        else if(rates[i].close < trend_up_buf[i-1]) m_trend_buf[i] = -1;
        else m_trend_buf[i] = m_trend_buf[i-1];

        // Pine: trail = Trend == 1 ? TrendUp : TrendDown
        m_trail_buf[i] = (m_trend_buf[i] == 1) ? trend_up_buf[i] : trend_down_buf[i];
    }

    return rates_total;
}
//+------------------------------------------------------------------+
