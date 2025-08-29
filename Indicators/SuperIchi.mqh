//+------------------------------------------------------------------+
//|                                                  SuperIchi.mqh |
//|                                  Copyright 2024, Jules The AI |
//|           MQL5 implementation of the SuperIchi indicator         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

//+------------------------------------------------------------------+
//| CSuperIchi Class (Corrected Version)                             |
//+------------------------------------------------------------------+
class CSuperIchi
{
private:
    // --- Settings ---
    int m_tenkan_len, m_kijun_len, m_spanB_len;
    double m_tenkan_mult, m_kijun_mult, m_spanB_mult;

    // --- Indicator Handles ---
    int m_atr_tenkan_handle;
    int m_atr_kijun_handle;
    int m_atr_spanB_handle;

    // --- Buffers ---
    double m_tenkan_buf[];
    double m_kijun_buf[];
    double m_senkouA_buf[];
    double m_senkouB_buf[];

    int m_rates_total;

    // --- Private Helper Methods ---
    void CalculateAvg(const double &price[], const double &hl2[], int atr_handle, double mult, double &avg_buffer[]);

public:
    CSuperIchi(void);
    ~CSuperIchi(void);
    bool Init(string symbol, ENUM_TIMEFRAMES timeframe, int tenkan_len, double tenkan_mult, int kijun_len, double kijun_mult, int spanB_len, double spanB_mult);
    int Calculate(int rates_total, const double &close[], const double &hl2[]);

    // --- Access Methods ---
    double GetTenkan(int shift) { if(shift < m_rates_total) return m_tenkan_buf[shift]; return 0; }
    double GetKijun(int shift) { if(shift < m_rates_total) return m_kijun_buf[shift]; return 0; }
    double GetSenkouA(int shift) { if(shift < m_rates_total) return m_senkouA_buf[shift]; return 0; }
    double GetSenkouB(int shift) { if(shift < m_rates_total) return m_senkouB_buf[shift]; return 0; }
};

CSuperIchi::CSuperIchi(void) : m_rates_total(0), m_atr_tenkan_handle(INVALID_HANDLE),
                               m_atr_kijun_handle(INVALID_HANDLE), m_atr_spanB_handle(INVALID_HANDLE)
{
}

CSuperIchi::~CSuperIchi(void)
{
    IndicatorRelease(m_atr_tenkan_handle);
    IndicatorRelease(m_atr_kijun_handle);
    IndicatorRelease(m_atr_spanB_handle);
}

bool CSuperIchi::Init(string symbol, ENUM_TIMEFRAMES timeframe, int tenkan_len, double tenkan_mult, int kijun_len, double kijun_mult, int spanB_len, double spanB_mult)
{
    m_tenkan_len = tenkan_len; m_tenkan_mult = tenkan_mult;
    m_kijun_len = kijun_len; m_kijun_mult = kijun_mult;
    m_spanB_len = spanB_len; m_spanB_mult = spanB_mult;

    m_atr_tenkan_handle = iATR(symbol, timeframe, m_tenkan_len);
    m_atr_kijun_handle = iATR(symbol, timeframe, m_kijun_len);
    m_atr_spanB_handle = iATR(symbol, timeframe, m_spanB_len);

    if(m_atr_tenkan_handle==INVALID_HANDLE || m_atr_kijun_handle==INVALID_HANDLE || m_atr_spanB_handle==INVALID_HANDLE)
    {
        printf("CSuperIchi::Init - Failed to create ATR handles");
        return false;
    }
    return(true);
}

int CSuperIchi::Calculate(int rates_total, const double &close[], const double &hl2[])
{
    if(rates_total < MathMax(m_tenkan_len, MathMax(m_kijun_len, m_spanB_len)) + 1) return 0;
    m_rates_total = rates_total;

    ArrayResize(m_tenkan_buf, rates_total);
    ArrayResize(m_kijun_buf, rates_total);
    ArrayResize(m_senkouA_buf, rates_total);
    ArrayResize(m_senkouB_buf, rates_total);

    CalculateAvg(close, hl2, m_atr_tenkan_handle, m_tenkan_mult, m_tenkan_buf);
    CalculateAvg(close, hl2, m_atr_kijun_handle, m_kijun_mult, m_kijun_buf);
    CalculateAvg(close, hl2, m_atr_spanB_handle, m_spanB_mult, m_senkouB_buf);

    for(int i=0; i<rates_total; i++)
    {
        m_senkouA_buf[i] = (m_kijun_buf[i] + m_tenkan_buf[i]) / 2.0;
    }

    return rates_total;
}

void CSuperIchi::CalculateAvg(const double &price[], const double &hl2[], int atr_handle, double mult, double &avg_buffer[])
{
    int rates_total = ArraySize(price);
    double atr_buf[];
    ArrayResize(atr_buf, rates_total);
    CopyBuffer(atr_handle, 0, 0, rates_total, atr_buf);

    double upper_band[], lower_band[];
    ArrayResize(upper_band, rates_total);
    ArrayResize(lower_band, rates_total);

    int os[]; ArrayResize(os, rates_total);
    double max_val[], min_val[]; ArrayResize(max_val, rates_total); ArrayResize(min_val, rates_total);
    double spt[]; ArrayResize(spt, rates_total);

    for(int i=1; i<rates_total; i++)
    {
        double atr = atr_buf[i] * mult;
        double up = hl2[i] + atr;
        double dn = hl2[i] - atr;

        upper_band[i] = (price[i-1] < upper_band[i-1]) ? MathMin(up, upper_band[i-1]) : up;
        lower_band[i] = (price[i-1] > lower_band[i-1]) ? MathMax(dn, lower_band[i-1]) : dn;

        if(price[i] > upper_band[i]) os[i] = 1;
        else if(price[i] < lower_band[i]) os[i] = 0;
        else os[i] = os[i-1];

        spt[i] = (os[i] == 1) ? lower_band[i] : upper_band[i];

        bool is_cross = (price[i-1] < spt[i-1] && price[i] > spt[i]) || (price[i-1] > spt[i-1] && price[i] < spt[i]);

        if(is_cross)
        {
            max_val[i] = MathMax(price[i], max_val[i-1]);
            min_val[i] = MathMin(price[i], min_val[i-1]);
        }
        else
        {
            max_val[i] = (os[i] == 1) ? MathMax(price[i], max_val[i-1]) : spt[i];
            min_val[i] = (os[i] == 0) ? MathMin(price[i], min_val[i-1]) : spt[i];
        }

        avg_buffer[i] = (max_val[i] + min_val[i]) / 2.0;
    }
}
//+------------------------------------------------------------------+
