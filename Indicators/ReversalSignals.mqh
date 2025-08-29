//+------------------------------------------------------------------+
//|                                            ReversalSignals.mqh |
//|                                  Copyright 2024, Jules The AI |
//|    MQL5 implementation of the Reversal Signals (custom RSI)      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

//+------------------------------------------------------------------+
//| CReversalSignals Class                                           |
//| Replicates the custom RSI logic from the Pine Script.            |
//+------------------------------------------------------------------+
class CReversalSignals
{
private:
    // --- Settings ---
    int m_period;
    double m_overbought;
    double m_oversold;

    // --- Data buffers ---
    double m_upwardd_buf[];
    double m_dnwardd_buf[];
    double m_source_rsi_buf[];

    int m_rates_total;

public:
    // --- Constructor ---
    CReversalSignals(void);

    // --- Initialization ---
    bool Init(int period, double overbought, double oversold);

    // --- Calculation ---
    int Calculate(int rates_total, const double &close[]);

    // --- Access Methods ---
    double GetRsi(int shift) { if(shift < m_rates_total) return m_source_rsi_buf[shift]; return 0; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CReversalSignals::CReversalSignals(void) : m_period(0),
                                           m_overbought(0),
                                           m_oversold(0),
                                           m_rates_total(0)
{
}

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
bool CReversalSignals::Init(int period, double overbought, double oversold)
{
    m_period = period;
    m_overbought = overbought;
    m_oversold = oversold;
    return(true);
}

//+------------------------------------------------------------------+
//| Calculation method                                               |
//+------------------------------------------------------------------+
int CReversalSignals::Calculate(int rates_total, const double &close[])
{
    if(rates_total < m_period + 1) return 0;

    m_rates_total = rates_total;

    // --- Resize all buffers ---
    ArrayResize(m_upwardd_buf, rates_total);
    ArrayResize(m_dnwardd_buf, rates_total);
    ArrayResize(m_source_rsi_buf, rates_total);

    // --- Calculate custom RSI ---
    double alpha = 1.0 / m_period;

    for(int i = 1; i < rates_total; i++)
    {
        double change = close[i] - close[i-1];

        double up = change > 0 ? change : 0;
        double dn = change < 0 ? -change : 0;

        // Pine: ta.rma(source, length) => alpha = 1/length; smma = (smma[1] * (length - 1) + source) / length
        // which is equivalent to: smma = source * alpha + smma[1] * (1 - alpha)
        m_upwardd_buf[i] = up * alpha + m_upwardd_buf[i-1] * (1 - alpha);
        m_dnwardd_buf[i] = dn * alpha + m_dnwardd_buf[i-1] * (1 - alpha);

        if(m_dnwardd_buf[i] == 0)
        {
            m_source_rsi_buf[i] = 100;
        }
        else if(m_upwardd_buf[i] == 0)
        {
            m_source_rsi_buf[i] = 0;
        }
        else
        {
            m_source_rsi_buf[i] = 100.0 - (100.0 / (1.0 + m_upwardd_buf[i] / m_dnwardd_buf[i]));
        }
    }

    // --- Check for signals ---
    // We only care about the most recent signal on the last closed bar
    int result = 0;
    int bar_to_check = rates_total - 2; // Last closed bar

    // revup = ta.crossover(sourceRSI, oversold)
    if(m_source_rsi_buf[bar_to_check-1] < m_oversold && m_source_rsi_buf[bar_to_check] > m_oversold)
    {
        result = 1; // Buy reversal
    }

    // revdn = ta.crossunder(sourceRSI, overbought)
    if(m_source_rsi_buf[bar_to_check-1] > m_overbought && m_source_rsi_buf[bar_to_check] < m_overbought)
    {
        result = -1; // Sell reversal
    }

    return result;
}
//+------------------------------------------------------------------+
