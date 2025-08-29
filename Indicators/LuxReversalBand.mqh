//+------------------------------------------------------------------+
//|                                            LuxReversalBand.mqh |
//|                                  Copyright 2024, Jules The AI |
//|     MQL5 implementation of the Lux Algo Reversal Band indicator  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

//+------------------------------------------------------------------+
//| CLuxReversalBand Class                                           |
//+------------------------------------------------------------------+
class CLuxReversalBand
{
private:
    // --- Settings ---
    int m_length;
    double m_bd1, m_bd2, m_bd3;

    // --- Indicator Handles ---
    int m_kama_basis_handle;

    // --- Buffers ---
    double m_rg_buf[];          // KAMA of True Range
    double m_basis_buf[];       // KAMA of Close price
    double m_upper1_buf[], m_upper2_buf[], m_upper3_buf[];
    double m_lower1_buf[], m_lower2_buf[], m_lower3_buf[];

    int m_rates_total;

    // --- Private Methods ---
    void CalculateKamaOnBuffer(const double &source[], double &destination[], int period);

public:
    // --- Constructor ---
    CLuxReversalBand(void);

    // --- Initialization ---
    bool Init(string symbol, ENUM_TIMEFRAMES timeframe, int length, double bd1, double bd2, double bd3);

    // --- Calculation ---
    int Calculate(int rates_total, const MqlRates &rates[]);

    // --- Access Methods (add more as needed) ---
    double GetUpper1(int shift) { if(shift < m_rates_total) return m_upper1_buf[shift]; return 0; }
    double GetLower1(int shift) { if(shift < m_rates_total) return m_lower1_buf[shift]; return 0; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLuxReversalBand::CLuxReversalBand(void) : m_length(0), m_bd1(0), m_bd2(0), m_bd3(0),
                                           m_kama_basis_handle(INVALID_HANDLE), m_rates_total(0)
{
}

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
bool CLuxReversalBand::Init(string symbol, ENUM_TIMEFRAMES timeframe, int length, double bd1, double bd2, double bd3)
{
    m_length = length;
    m_bd1 = bd1;
    m_bd2 = bd2;
    m_bd3 = bd3;

    m_kama_basis_handle = iKAMA(symbol, timeframe, m_length, 2, 30, PRICE_CLOSE);
    if(m_kama_basis_handle == INVALID_HANDLE)
    {
        printf("CLuxReversalBand::Init - Failed to create iKAMA handle. Error %d", GetLastError());
        return(false);
    }
    return(true);
}

//+------------------------------------------------------------------+
//| Main Calculation Method                                          |
//+------------------------------------------------------------------+
int CLuxReversalBand::Calculate(int rates_total, const MqlRates &rates[])
{
    if(rates_total < m_length + 1) return 0;
    m_rates_total = rates_total;

    // --- Resize buffers ---
    ArrayResize(m_rg_buf, rates_total);
    ArrayResize(m_basis_buf, rates_total);
    ArrayResize(m_upper1_buf, rates_total);
    ArrayResize(m_upper2_buf, rates_total);
    ArrayResize(m_upper3_buf, rates_total);
    ArrayResize(m_lower1_buf, rates_total);
    ArrayResize(m_lower2_buf, rates_total);
    ArrayResize(m_lower3_buf, rates_total);

    // --- Calculate True Range manually ---
    double tr_buf[];
    ArrayResize(tr_buf, rates_total);
    for(int i = 1; i < rates_total; i++)
    {
        tr_buf[i] = MathMax(rates[i].high, rates[i-1].close) - MathMin(rates[i].low, rates[i-1].close);
    }

    // --- Calculate KAMA of True Range ---
    CalculateKamaOnBuffer(tr_buf, m_rg_buf, m_length);

    // --- Copy basis KAMA values ---
    if(CopyBuffer(m_kama_basis_handle, 0, 0, rates_total, m_basis_buf) <= 0)
    {
        printf("CLuxReversalBand::Calculate - Failed to copy KAMA basis buffer.");
        return 0;
    }

    // --- Calculate final bands ---
    for(int i = 0; i < rates_total; i++)
    {
        m_upper1_buf[i] = m_basis_buf[i] + m_rg_buf[i] * m_bd1;
        m_upper2_buf[i] = m_basis_buf[i] + m_rg_buf[i] * m_bd2;
        m_upper3_buf[i] = m_basis_buf[i] + m_rg_buf[i] * m_bd3;
        m_lower1_buf[i] = m_basis_buf[i] - m_rg_buf[i] * m_bd1;
        m_lower2_buf[i] = m_basis_buf[i] - m_rg_buf[i] * m_bd2;
        m_lower3_buf[i] = m_basis_buf[i] - m_rg_buf[i] * m_bd3;
    }

    return rates_total;
}

//+------------------------------------------------------------------+
//| Helper to calculate KAMA on a buffer                             |
//+------------------------------------------------------------------+
void CLuxReversalBand::CalculateKamaOnBuffer(const double &source[], double &destination[], int period)
{
    double fast_ema_alpha = 2.0 / (2.0 + 1.0);
    double slow_ema_alpha = 2.0 / (30.0 + 1.0);

    for(int i = 1; i < ArraySize(source); i++)
    {
        double change = MathAbs(source[i] - source[i-period > 0 ? i-period : 0]);
        double volatility = 0;
        for(int j = 0; j < period && i-j > 0; j++)
        {
            volatility += MathAbs(source[i-j] - source[i-j-1]);
        }

        if(volatility == 0)
        {
            destination[i] = destination[i-1];
            continue;
        }

        double er = change / volatility; // Efficiency Ratio
        double sc = MathPow(er * (fast_ema_alpha - slow_ema_alpha) + slow_ema_alpha, 2); // Smoothing Constant

        destination[i] = destination[i-1] + sc * (source[i] - destination[i-1]);
    }
}
//+------------------------------------------------------------------+
