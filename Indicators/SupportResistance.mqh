//+------------------------------------------------------------------+
//|                                        SupportResistance.mqh |
//|                                  Copyright 2024, Jules The AI |
//|     MQL5 implementation of the Support/Resistance calculator     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

#include <Arrays\ArrayDouble.mqh>

struct S_PivotPoint
{
    datetime time;
    double price;
};

//+------------------------------------------------------------------+
//| CSupportResistance Class                                         |
//+------------------------------------------------------------------+
class CSupportResistance
{
private:
    // --- Settings ---
    int m_strength;
    int m_prd;      // Lookback period
    int m_pivot_bars; // left/right bars for pivot detection

    // --- Buffers and Data ---
    CArrayDouble *m_sr_levels;

    // --- Handles ---
    int m_fractals_up_handle;
    int m_fractals_down_handle;

public:
    CSupportResistance(void);
    ~CSupportResistance(void);

    bool Init(int strength, int prd, int pivot_bars);
    int Calculate(int rates_total, const MqlRates &rates[]);

    CArrayDouble* GetLevels() { return m_sr_levels; }
};

CSupportResistance::CSupportResistance(void)
{
    m_sr_levels = new CArrayDouble();
}

CSupportResistance::~CSupportResistance(void)
{
    if(CheckPointer(m_sr_levels) == POINTER_DYNAMIC)
        delete m_sr_levels;
    IndicatorRelease(m_fractals_up_handle);
    IndicatorRelease(m_fractals_down_handle);
}


bool CSupportResistance::Init(int strength, int prd, int pivot_bars)
{
    m_strength = strength;
    m_prd = prd;
    m_pivot_bars = pivot_bars; // This corresponds to 'rb' in Pine

    // In MQL5, iFractals uses a fixed 2-bar left/right shoulder. We will use this as an approximation.
    // A more precise implementation would require manual pivot detection.
    m_fractals_up_handle = iFractals(_Symbol, _Period, MODE_UPPER);
    m_fractals_down_handle = iFractals(_Symbol, _Period, MODE_LOWER);

    return(m_fractals_up_handle != INVALID_HANDLE && m_fractals_down_handle != INVALID_HANDLE);
}

int CSupportResistance::Calculate(int rates_total, const MqlRates &rates[])
{
    if(rates_total < m_prd) return 0;

    m_sr_levels.Clear();

    // --- Get all pivots from the last m_prd bars ---
    CArrayObj *all_pivots = new CArrayObj();
    double up_frac[], down_frac[];
    ArrayResize(up_frac, m_prd);
    ArrayResize(down_frac, m_prd);

    CopyBuffer(m_fractals_up_handle, 0, 1, m_prd, up_frac);
    CopyBuffer(m_fractals_down_handle, 0, 1, m_prd, down_frac);

    for(int i=0; i<m_prd; i++)
    {
        if(up_frac[i] > 0)
        {
            S_PivotPoint *p = new S_PivotPoint();
            p.price = up_frac[i];
            p.time = rates[rates_total-1-i].time;
            all_pivots.Add(p);
        }
        if(down_frac[i] > 0)
        {
            S_PivotPoint *p = new S_PivotPoint();
            p.price = down_frac[i];
            p.time = rates[rates_total-1-i].time;
            all_pivots.Add(p);
        }
    }

    // --- Optimized Clustering Logic ---
    bool used_pivots[];
    ArrayResize(used_pivots, all_pivots.Total());
    ArrayInitialize(used_pivots, false);

    double prd_high = 0, prd_low = 999999;
    for(int i=0; i<m_prd; i++)
    {
       if(rates[rates_total-1-i].high > prd_high) prd_high = rates[rates_total-1-i].high;
       if(rates[rates_total-1-i].low < prd_low) prd_low = rates[rates_total-1-i].low;
    }
    double channel_width = (prd_high - prd_low) * 0.10; // ChannelW = 10%

    for(int i=0; i<all_pivots.Total(); i++)
    {
        if(used_pivots[i]) continue;

        S_PivotPoint *pivot1 = all_pivots.At(i);
        double upper_channel = pivot1.price + channel_width;
        double lower_channel = pivot1.price - channel_width;

        int points_in_channel = 0;
        CArrayInt *channel_indices = new CArrayInt();

        for(int j=0; j<all_pivots.Total(); j++)
        {
            S_PivotPoint *pivot2 = all_pivots.At(j);
            if(pivot2.price >= lower_channel && pivot2.price <= upper_channel)
            {
                points_in_channel++;
                channel_indices.Add(j);
            }
        }

        if(points_in_channel >= m_strength)
        {
            m_sr_levels.Add(pivot1.price);
            // Mark all pivots in this channel as used
            for(int k=0; k<channel_indices.Total(); k++)
            {
                used_pivots[channel_indices.At(k)] = true;
            }
        }
        delete channel_indices;
    }

    delete all_pivots;
    return m_sr_levels.Total();
}
//+------------------------------------------------------------------+
