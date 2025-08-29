//+------------------------------------------------------------------+
//|                                             StrongTPPoints.mqh |
//|                                  Copyright 2024, Jules The AI |
//|        MQL5 implementation of the 'lele' function for TP Points  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

//+------------------------------------------------------------------+
//| CStrongTPPoints Class                                            |
//| Replicates the logic of the 'lele' function from the Pine Script.|
//+------------------------------------------------------------------+
class CStrongTPPoints
{
private:
    // --- Settings ---
    int m_qual;
    int m_len;
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;

    // --- Indicator Handles ---
    int m_highest_handle;
    int m_lowest_handle;

    // --- State variables (counters) ---
    int m_bindex;
    int m_sindex;

public:
    // --- Constructor ---
    CStrongTPPoints(void);

    // --- Initialization ---
    bool Init(string symbol, ENUM_TIMEFRAMES timeframe, int qual, int len);

    // --- Calculation ---
    int Calculate(const MqlRates &current_bar, const MqlRates &prev_bar_4);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStrongTPPoints::CStrongTPPoints(void) : m_qual(0),
                                         m_len(0),
                                         m_highest_handle(INVALID_HANDLE),
                                         m_lowest_handle(INVALID_HANDLE),
                                         m_bindex(0),
                                         m_sindex(0)
{
}

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
bool CStrongTPPoints::Init(string symbol, ENUM_TIMEFRAMES timeframe, int qual, int len)
{
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_qual = qual;
    m_len = len;

    // --- Create indicator handles ---
    m_highest_handle = iHighest(m_symbol, m_timeframe, MODE_HIGH, m_len, 0);
    if(m_highest_handle == INVALID_HANDLE)
    {
        printf("CStrongTPPoints::Init - Failed to create iHighest handle. Error %d", GetLastError());
        return(false);
    }

    m_lowest_handle = iLowest(m_symbol, m_timeframe, MODE_LOW, m_len, 0);
    if(m_lowest_handle == INVALID_HANDLE)
    {
        printf("CStrongTPPoints::Init - Failed to create iLowest handle. Error %d", GetLastError());
        return(false);
    }

    return(true);
}

//+------------------------------------------------------------------+
//| Calculation method (call on each new bar)                        |
//+------------------------------------------------------------------+
int CStrongTPPoints::Calculate(const MqlRates &current_bar, const MqlRates &prev_bar_4)
{
    // --- Get Highest/Lowest values ---
    double highest_buf[], lowest_buf[];
    if(CopyBuffer(m_highest_handle, 0, 1, 1, highest_buf) < 1 || CopyBuffer(m_lowest_handle, 0, 1, 1, lowest_buf) < 1)
    {
        // Not enough data yet
        return 0;
    }
    double highest_val = highest_buf[0];
    double lowest_val = lowest_buf[0];

    // --- Pine Script 'bindex' and 'sindex' logic ---
    if(current_bar.close > prev_bar_4.close)
    {
        m_bindex++;
    }
    if(current_bar.close < prev_bar_4.close)
    {
        m_sindex++;
    }

    int result = 0;

    // --- Pine Script 'sell' condition ---
    // if bindex > qual and close < open and high >= ta.highest(high, len)
    if(m_bindex > m_qual && current_bar.close < current_bar.open && current_bar.high >= highest_val)
    {
        m_bindex = 0;
        result = -1; // Sell signal
    }

    // --- Pine Script 'buy' condition ---
    // if sindex > qual and close > open and low <= ta.lowest(low, len)
    if(m_sindex > m_qual && current_bar.close > current_bar.open && current_bar.low <= lowest_val)
    {
        m_sindex = 0;
        result = 1; // Buy signal
    }

    return result;
}
//+------------------------------------------------------------------+
