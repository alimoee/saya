//+------------------------------------------------------------------+
//|                                                RangeFilter.mqh |
//|                                  Copyright 2024, Jules The AI |
//|          MQL5 implementation of the Range Filter indicator       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

#include <Arrays\ArrayDouble.mqh>

//+------------------------------------------------------------------+
//| CRangeFilter Class                                               |
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
    void CalculateCondEMA(CArrayDouble *source, CArrayDouble *dest, int period);

public:
    CRangeFilter(void);
    bool Init(int rng_per, double rng_qty, int smooth_per, bool smooth_range);
    int Calculate(int rates_total, const double &high[], const double &low[], const double &close[]);

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

int CRangeFilter::Calculate(int rates_total, const double &high[], const double &low[], const double &close[])
{
    if(rates_total < MathMax(m_rng_per, m_smooth_per) + 2) return 0;
    m_rates_total = rates_total;

    ArrayResize(m_filter_buf, rates_total);
    ArrayResize(m_hi_band_buf, rates_total);
    ArrayResize(m_lo_band_buf, rates_total);

    CArrayDouble *mov_src = new CArrayDouble();
    CArrayDouble *ac_src = new CArrayDouble();
    for(int i=0; i<rates_total; i++)
    {
        mov_src.Add((high[i] + low[i]) / 2.0);
        if(i>0) ac_src.Add(MathAbs(mov_src.At(i) - mov_src.At(i-1)));
        else ac_src.Add(0);
    }

    CArrayDouble *ac_ema = new CArrayDouble();
    CalculateCondEMA(ac_src, ac_ema, m_rng_per);

    CArrayDouble *rng_size_arr = new CArrayDouble();
    for(int i=0; i<rates_total; i++) rng_size_arr.Add(m_rng_qty * ac_ema.At(i));

    CArrayDouble *r_arr = new CArrayDouble();
    if(m_smooth_range)
    {
       CalculateCondEMA(rng_size_arr, r_arr, m_smooth_per);
    }
    else
    {
       r_arr.AssignArray(rng_size_arr);
    }

    m_filter_buf[0] = mov_src.At(0);
    for(int i=1; i<rates_total; i++)
    {
        double r = r_arr.At(i);
        if(high[i] >= m_filter_buf[i-1] + r)
            m_filter_buf[i] = m_filter_buf[i-1] + floor(MathAbs(high[i] - m_filter_buf[i-1]) / r) * r;
        else if(low[i] <= m_filter_buf[i-1] - r)
            m_filter_buf[i] = m_filter_buf[i-1] - floor(MathAbs(low[i] - m_filter_buf[i-1]) / r) * r;
        else
            m_filter_buf[i] = m_filter_buf[i-1];

        m_hi_band_buf[i] = m_filter_buf[i] + r;
        m_lo_band_buf[i] = m_filter_buf[i] - r;
    }

    delete mov_src;
    delete ac_src;
    delete ac_ema;
    delete rng_size_arr;
    delete r_arr;

    return rates_total;
}

void CRangeFilter::CalculateCondEMA(CArrayDouble *source, CArrayDouble *dest, int period)
{
    dest.Clear();
    if(source.Total() == 0) return;

    dest.Resize(source.Total());
    double alpha = 2.0 / (period + 1.0);
    double ema_val = source.At(0);
    dest.Update(0, ema_val);

    for(int i=1; i<source.Total(); i++)
    {
        ema_val = (source.At(i) - ema_val) * alpha + ema_val;
        dest.Update(i, ema_val);
    }
}
//+------------------------------------------------------------------+
