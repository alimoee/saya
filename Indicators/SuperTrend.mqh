//+------------------------------------------------------------------+
//|                                                 SuperTrend.mqh |
//|                                  Copyright 2024, Jules The AI |
//|            MQL5 implementation of the SuperTrend indicator     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

//+------------------------------------------------------------------+
//| CSuperTrend Class (Corrected/Robust Version)                     |
//+------------------------------------------------------------------+
class CSuperTrend
{
private:
    // --- Settings ---
    double m_factor;
    int m_atr_period;
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;

    // --- Indicator handles ---
    int m_atr_handle;

    // --- Data buffers ---
    double m_super_trend_buf[];
    int m_direction_buf[];

    int m_rates_total;

public:
    CSuperTrend(void);
    ~CSuperTrend(void);

    bool Init(string symbol, ENUM_TIMEFRAMES timeframe, double factor, int atr_period);
    int Calculate(int rates_total, const double &high[], const double &low[], const double &close[]);

    double GetValue(int shift) { if(shift < m_rates_total) return m_super_trend_buf[shift]; return 0; }
    int GetDirection(int shift) { if(shift < m_rates_total) return m_direction_buf[shift]; return 0;}
};

CSuperTrend::CSuperTrend(void) : m_factor(0), m_atr_period(0), m_atr_handle(INVALID_HANDLE), m_rates_total(0)
{
}

CSuperTrend::~CSuperTrend(void)
{
    if(m_atr_handle != INVALID_HANDLE) IndicatorRelease(m_atr_handle);
}

bool CSuperTrend::Init(string symbol, ENUM_TIMEFRAMES timeframe, double factor, int atr_period)
{
    m_symbol = symbol; m_timeframe = timeframe;
    m_factor = factor; m_atr_period = atr_period;

    m_atr_handle = iATR(m_symbol, m_timeframe, m_atr_period);
    if(m_atr_handle == INVALID_HANDLE)
    {
        printf("CSuperTrend::Init - Failed to create iATR handle. Error %d", GetLastError());
        return(false);
    }
    return(true);
}

int CSuperTrend::Calculate(int rates_total, const double &high[], const double &low[], const double &close[])
{
    if(rates_total <= m_atr_period) return 0;
    m_rates_total = rates_total;

    ArrayResize(m_super_trend_buf, rates_total);
    ArrayResize(m_direction_buf, rates_total);

    double atr_buffer[]; ArrayResize(atr_buffer, rates_total);
    if(CopyBuffer(m_atr_handle, 0, 0, rates_total, atr_buffer) <= 0) return 0;

    double upper_band_buf[]; ArrayResize(upper_band_buf, rates_total);
    double lower_band_buf[]; ArrayResize(lower_band_buf, rates_total);

    for(int i = 1; i < rates_total; i++)
    {
        double hl2 = (high[i] + low[i]) / 2.0;
        double atr = atr_buffer[i];

        double upper_band_basic = hl2 + m_factor * atr;
        double lower_band_basic = hl2 - m_factor * atr;

        if(lower_band_basic > lower_band_buf[i-1] || close[i-1] < lower_band_buf[i-1])
            lower_band_buf[i] = lower_band_basic;
        else
            lower_band_buf[i] = lower_band_buf[i-1];

        if(upper_band_basic < upper_band_buf[i-1] || close[i-1] > upper_band_buf[i-1])
            upper_band_buf[i] = upper_band_basic;
        else
            upper_band_buf[i] = upper_band_buf[i-1];

        // --- Robust direction logic using previous direction state ---
        if (m_direction_buf[i-1] == 1) // Previous trend was UP
        {
            m_direction_buf[i] = (close[i] > upper_band_buf[i]) ? -1 : 1;
        }
        else // Previous trend was DOWN
        {
            m_direction_buf[i] = (close[i] < lower_band_buf[i]) ? 1 : -1;
        }

        // --- Set final SuperTrend value based on Pine Script's unique logic ---
        m_super_trend_buf[i] = (m_direction_buf[i] == -1) ? lower_band_buf[i] : upper_band_buf[i];
    }
    return(rates_total);
}
//+------------------------------------------------------------------+
