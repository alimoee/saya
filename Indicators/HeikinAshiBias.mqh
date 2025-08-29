//+------------------------------------------------------------------+
//|                                             HeikinAshiBias.mqh |
//|                                  Copyright 2024, Jules The AI |
//|        MQL5 implementation of the Heikin-Ashi Market Bias        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

#include <Arrays\ArrayObj.mqh>

//+------------------------------------------------------------------+
//| CHeikinAshiBias Class                                            |
//| Replicates the logic of the 'Ha Market Bias' section from the    |
//| Pine Script.                                                     |
//+------------------------------------------------------------------+
class CHeikinAshiBias
{
private:
    // --- Settings ---
    int m_ha_len1;
    int m_ha_len2;
    int m_osc_len;
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;

    // --- Indicator Handles for initial smoothing (ha_len1) ---
    int m_h_ema1_handle;
    int m_l_ema1_handle;
    int m_o_ema1_handle;
    int m_c_ema1_handle;

    // --- Buffers for intermediate and final values ---
    double m_ha_open[];
    double m_ha_close[];
    double m_ha_high[];
    double m_ha_low[];

    double m_o2_buf[]; // Smoothed HA Open
    double m_c2_buf[]; // Smoothed HA Close

    double m_osc_bias_buf[];
    double m_osc_smooth_buf[];

public:
    // --- Constructor ---
    CHeikinAshiBias(void);

    // --- Initialization ---
    bool Init(string symbol, ENUM_TIMEFRAMES timeframe, int ha_len1, int ha_len2, int osc_len);

    // --- Calculation ---
    int Calculate(int rates_total, const MqlRates &rates[]);

    // --- Access Methods ---
    double GetOscBias(int shift) { return ArraySize(m_osc_bias_buf) > shift ? m_osc_bias_buf[shift] : 0; }
    double GetOscSmooth(int shift) { return ArraySize(m_osc_smooth_buf) > shift ? m_osc_smooth_buf[shift] : 0; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CHeikinAshiBias::CHeikinAshiBias(void) : m_ha_len1(0),
                                         m_ha_len2(0),
                                         m_osc_len(0),
                                         m_h_ema1_handle(INVALID_HANDLE),
                                         m_l_ema1_handle(INVALID_HANDLE),
                                         m_o_ema1_handle(INVALID_HANDLE),
                                         m_c_ema1_handle(INVALID_HANDLE)
{
}

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
bool CHeikinAshiBias::Init(string symbol, ENUM_TIMEFRAMES timeframe, int ha_len1, int ha_len2, int osc_len)
{
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_ha_len1 = ha_len1;
    m_ha_len2 = ha_len2;
    m_osc_len = osc_len;

    // --- Create handles for initial EMA smoothing ---
    m_o_ema1_handle = iMA(m_symbol, m_timeframe, m_ha_len1, 0, MODE_EMA, PRICE_OPEN);
    m_c_ema1_handle = iMA(m_symbol, m_timeframe, m_ha_len1, 0, MODE_EMA, PRICE_CLOSE);
    m_h_ema1_handle = iMA(m_symbol, m_timeframe, m_ha_len1, 0, MODE_EMA, PRICE_HIGH);
    m_l_ema1_handle = iMA(m_symbol, m_timeframe, m_ha_len1, 0, MODE_EMA, PRICE_LOW);

    if(m_o_ema1_handle == INVALID_HANDLE || m_c_ema1_handle == INVALID_HANDLE ||
       m_h_ema1_handle == INVALID_HANDLE || m_l_ema1_handle == INVALID_HANDLE)
    {
        printf("CHeikinAshiBias::Init - Failed to create initial EMA handles.");
        return(false);
    }

    return(true);
}

//+------------------------------------------------------------------+
//| Calculation method                                               |
//+------------------------------------------------------------------+
int CHeikinAshiBias::Calculate(int rates_total, const MqlRates &rates[])
{
    if(rates_total < MathMax(m_ha_len1, m_ha_len2) + m_osc_len) return 0;

    // --- Resize all buffers ---
    ArrayResize(m_ha_open, rates_total);
    ArrayResize(m_ha_close, rates_total);
    ArrayResize(m_ha_high, rates_total);
    ArrayResize(m_ha_low, rates_total);
    ArrayResize(m_o2_buf, rates_total);
    ArrayResize(m_c2_buf, rates_total);
    ArrayResize(m_osc_bias_buf, rates_total);
    ArrayResize(m_osc_smooth_buf, rates_total);

    // --- Copy data from initial EMA indicators ---
    double o1_buf[], c1_buf[], h1_buf[], l1_buf[];
    ArrayResize(o1_buf, rates_total);
    ArrayResize(c1_buf, rates_total);
    ArrayResize(h1_buf, rates_total);
    ArrayResize(l1_buf, rates_total);

    CopyBuffer(m_o_ema1_handle, 0, 0, rates_total, o1_buf);
    CopyBuffer(m_c_ema1_handle, 0, 0, rates_total, c1_buf);
    CopyBuffer(m_h_ema1_handle, 0, 0, rates_total, h1_buf);
    CopyBuffer(m_l_ema1_handle, 0, 0, rates_total, l1_buf);

    // --- Calculate first layer of Heikin-Ashi values ---
    for(int i = 1; i < rates_total; i++)
    {
        m_ha_close[i] = (o1_buf[i] + h1_buf[i] + l1_buf[i] + c1_buf[i]) / 4.0;
        double xhaopen = (o1_buf[i] + c1_buf[i]) / 2.0;
        m_ha_open[i] = (m_ha_open[i-1] + m_ha_close[i-1]) / 2.0;
        if(i==1) m_ha_open[i] = xhaopen; // Base case from Pine Script

        m_ha_high[i] = MathMax(h1_buf[i], MathMax(m_ha_open[i], m_ha_close[i]));
        m_ha_low[i] = MathMin(l1_buf[i], MathMin(m_ha_open[i], m_ha_close[i]));
    }

    // --- Manually calculate the second layer of EMA smoothing ---
    // This is required because iMA cannot use a calculated array as input.
    double alpha2 = 2.0 / (m_ha_len2 + 1.0);
    double alpha_osc = 2.0 / (m_osc_len + 1.0);

    for(int i = 1; i < rates_total; i++)
    {
        // EMA of ha_open and ha_close
        m_o2_buf[i] = m_ha_open[i] * alpha2 + m_o2_buf[i-1] * (1 - alpha2);
        m_c2_buf[i] = m_ha_close[i] * alpha2 + m_c2_buf[i-1] * (1 - alpha2);

        // Calculate oscillator
        m_osc_bias_buf[i] = 100 * (m_c2_buf[i] - m_o2_buf[i]);

        // EMA of oscillator
        m_osc_smooth_buf[i] = m_osc_bias_buf[i] * alpha_osc + m_osc_smooth_buf[i-1] * (1 - alpha_osc);
    }

    return rates_total;
}
//+------------------------------------------------------------------+
