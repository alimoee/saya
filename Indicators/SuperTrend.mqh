//+------------------------------------------------------------------+
//|                                                 SuperTrend.mqh |
//|                                  Copyright 2024, Jules The AI |
//|            MQL5 implementation of the SuperTrend indicator     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

//+------------------------------------------------------------------+
//| CSuperTrend Class                                                |
//| Replicates the logic of the custom 'supertrend' function from    |
//| the Pine Script.                                                 |
//+------------------------------------------------------------------+
class CSuperTrend
{
private:
    // --- Indicator settings ---
    double m_factor;
    int m_atr_period;
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;

    // --- Indicator handles ---
    int m_atr_handle;

    // --- Data buffers ---
    double m_upper_band_buf[];
    double m_lower_band_buf[];
    double m_super_trend_buf[];
    int m_direction_buf[];

    int m_rates_total;

public:
    // --- Constructor/Destructor ---
    CSuperTrend(void);
    ~CSuperTrend(void);

    // --- Initialization ---
    bool Init(string symbol, ENUM_TIMEFRAMES timeframe, double factor, int atr_period);

    // --- Calculation ---
    int Calculate(int rates_total, const double &high[], const double &low[], const double &close[]);

    // --- Access methods ---
    double GetValue(int shift) { if(shift < m_rates_total) return m_super_trend_buf[shift]; return 0; }
    int GetDirection(int shift) { if(shift < m_rates_total) return m_direction_buf[shift]; return 0;}
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSuperTrend::CSuperTrend(void) : m_factor(0),
                                 m_atr_period(0),
                                 m_atr_handle(INVALID_HANDLE),
                                 m_rates_total(0)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSuperTrend::~CSuperTrend(void)
{
    if(m_atr_handle != INVALID_HANDLE)
        IndicatorRelease(m_atr_handle);
}

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
bool CSuperTrend::Init(string symbol, ENUM_TIMEFRAMES timeframe, double factor, int atr_period)
{
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_factor = factor;
    m_atr_period = atr_period;

    m_atr_handle = iATR(m_symbol, m_timeframe, m_atr_period);
    if(m_atr_handle == INVALID_HANDLE)
    {
        printf("CSuperTrend::Init - Failed to create iATR handle. Error %d", GetLastError());
        return(false);
    }
    return(true);
}

//+------------------------------------------------------------------+
//| Calculation method                                               |
//+------------------------------------------------------------------+
int CSuperTrend::Calculate(int rates_total, const double &high[], const double &low[], const double &close[])
{
    if(rates_total <= m_atr_period) return 0;

    m_rates_total = rates_total;

    ArrayResize(m_upper_band_buf, rates_total);
    ArrayResize(m_lower_band_buf, rates_total);
    ArrayResize(m_super_trend_buf, rates_total);
    ArrayResize(m_direction_buf, rates_total);

    double atr_buffer[];
    ArrayResize(atr_buffer, rates_total);

    if(CopyBuffer(m_atr_handle, 0, 0, rates_total, atr_buffer) <= 0)
    {
        printf("CSuperTrend::Calculate - Failed to copy ATR buffer. Error %d", GetLastError());
        return(0);
    }

    // --- Main calculation loop ---
    for(int i = 1; i < rates_total; i++)
    {
        double hl2 = (high[i] + low[i]) / 2.0;
        double atr = atr_buffer[i];

        // --- Calculate basic bands for the current bar ---
        double upper_band_basic = hl2 + m_factor * atr;
        double lower_band_basic = hl2 - m_factor * atr;

        // --- Pine Script 'lowerBand :=' logic ---
        if(lower_band_basic > m_lower_band_buf[i-1] || close[i-1] < m_lower_band_buf[i-1])
            m_lower_band_buf[i] = lower_band_basic;
        else
            m_lower_band_buf[i] = m_lower_band_buf[i-1];

        // --- Pine Script 'upperBand :=' logic ---
        if(upper_band_basic < m_upper_band_buf[i-1] || close[i-1] > m_upper_band_buf[i-1])
            m_upper_band_buf[i] = upper_band_basic;
        else
            m_upper_band_buf[i] = m_upper_band_buf[i-1];

        // --- Pine Script 'direction :=' logic ---
        if(atr_buffer[i-1] == 0) // Equivalent to na(atrat[1])
        {
            m_direction_buf[i] = 1;
        }
        else if(m_super_trend_buf[i-1] == m_upper_band_buf[i-1]) // prevSuperTrend == prevUpperBand
        {
            m_direction_buf[i] = (close[i] > m_upper_band_buf[i]) ? -1 : 1;
        }
        else // prevSuperTrend == prevLowerBand
        {
            m_direction_buf[i] = (close[i] < m_lower_band_buf[i]) ? 1 : -1;
        }

        // --- Pine Script 'superTrend :=' logic ---
        m_super_trend_buf[i] = (m_direction_buf[i] == -1) ? m_lower_band_buf[i] : m_upper_band_buf[i];
    }
    return(rates_total);
}
//+------------------------------------------------------------------+
