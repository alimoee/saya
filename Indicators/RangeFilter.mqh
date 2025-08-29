//+------------------------------------------------------------------+
//|                                                RangeFilter.mqh |
//|                                  Copyright 2024, Jules The AI |
//|          MQL5 implementation of the Range Filter indicator       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

#include <Arrays\ArrayDouble.mqh>

//+------------------------------------------------------------------+
//| CRangeFilter Class (Corrected Version)                           |
//+------------------------------------------------------------------+
class CRangeFilter
{
private:
    // --- Settings ---
    int m_rng_per;
    double m_rng_qty;
    int m_smooth_per;
    bool m_smooth_range;

    // --- Buffers ---
    double m_filter_buf[];
    double m_hi_band_buf[];
    double m_lo_band_buf[];

    int m_rates_total;

    // --- Private Helper Methods ---
    void CalculateEMA(const double &source[], double &dest[], int period);

public:
    CRangeFilter(void);
    bool Init(int rng_per, double rng_qty, int smooth_per, bool smooth_range);
    int Calculate(int rates_total, const double &high[], const double &low[]);

    double GetFilter(int shift) { if(shift < m_rates_total) return m_filter_buf[shift]; return 0; }
    double GetHiBand(int shift) { if(shift < m_rates_total) return m_hi_band_buf[shift]; return 0; }
    double GetLoBand(int shift) { if(shift < m_rates_total) return m_lo_band_buf[shift]; return 0; }
};

CRangeFilter::CRangeFilter(void) : m_rng_per(0), m_rng_qty(0), m_smooth_per(0),
                                   m_smooth_range(false), m_rates_total(0)
{
}

bool CRangeFilter::Init(int rng_per, double rng_qty, int smooth_per, bool smooth_range)
{
    m_rng_per = rng_per;
    m_rng_qty = rng_qty;
    m_smooth_per = smooth_per;
    m_smooth_range = smooth_range;
    return(true);
}

int CRangeFilter::Calculate(int rates_total, const double &high[], const double &low[])
{
    if(rates_total < MathMax(m_rng_per, m_smooth_per) + 2) return 0;
    m_rates_total = rates_total;

    ArrayResize(m_filter_buf, rates_total);
    ArrayResize(m_hi_band_buf, rates_total);
    ArrayResize(m_lo_band_buf, rates_total);

    // --- Intermediate Buffers (as raw arrays for efficiency) ---
    double mov_src[]; ArrayResize(mov_src, rates_total);
    double ac_src[]; ArrayResize(ac_src, rates_total);
    for(int i=0; i<rates_total; i++)
    {
        mov_src[i] = (high[i] + low[i]) / 2.0;
        if(i>0) ac_src[i] = MathAbs(mov_src[i] - mov_src[i-1]);
        else ac_src[i] = 0;
    }

    double ac_ema[]; ArrayResize(ac_ema, rates_total);
    CalculateEMA(ac_src, ac_ema, m_rng_per);

    double rng_size[]; ArrayResize(rng_size, rates_total);
    for(int i=0; i<rates_total; i++) rng_size[i] = m_rng_qty * ac_ema[i];

    double r[]; ArrayResize(r, rates_total);
    if(m_smooth_range)
    {
       CalculateEMA(rng_size, r, m_smooth_per);
    }
    else
    {
       ArrayCopy(r, rng_size);
    }

    // --- Main Filter Logic (rng_filt) ---
    m_filter_buf[0] = mov_src[0];
    for(int i=1; i<rates_total; i++)
    {
        double current_r = r[i];
        if(current_r == 0) // Avoid division by zero
        {
            m_filter_buf[i] = m_filter_buf[i-1];
        }
        else if(high[i] >= m_filter_buf[i-1] + current_r)
        {
            m_filter_buf[i] = m_filter_buf[i-1] + floor(MathAbs(high[i] - m_filter_buf[i-1]) / current_r) * current_r;
        }
        else if(low[i] <= m_filter_buf[i-1] - current_r)
        {
            m_filter_buf[i] = m_filter_buf[i-1] - floor(MathAbs(low[i] - m_filter_buf[i-1]) / current_r) * current_r;
        }
        else
        {
            m_filter_buf[i] = m_filter_buf[i-1];
        }

        m_hi_band_buf[i] = m_filter_buf[i] + current_r;
        m_lo_band_buf[i] = m_filter_buf[i] - current_r;
    }

    return rates_total;
}

void CRangeFilter::CalculateEMA(const double &source[], double &dest[], int period)
{
    if(ArraySize(source) == 0) return;

    double alpha = 2.0 / (period + 1.0);
    dest[0] = source[0];

    for(int i=1; i<ArraySize(source); i++)
    {
        dest[i] = (source[i] * alpha) + (dest[i-1] * (1.0 - alpha));
    }
}
//+------------------------------------------------------------------+
