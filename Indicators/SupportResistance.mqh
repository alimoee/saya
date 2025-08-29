//+------------------------------------------------------------------+
//|                                        SupportResistance.mqh |
//|                                  Copyright 2024, Jules The AI |
//|     MQL5 implementation of the Support/Resistance calculator     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayObj.mqh>

// --- Struct to hold pivot point data ---
class CPivotPoint : public CObject
{
public:
    datetime time;
    double price;
};

//+------------------------------------------------------------------+
//| CSupportResistance Class (Corrected Version)                     |
//+------------------------------------------------------------------+
class CSupportResistance
{
private:
    // --- Settings ---
    int m_strength;
    int m_prd;      // Lookback period
    int m_pivot_bars; // left/right bars for pivot detection

    // --- Data ---
    CArrayDouble *m_sr_levels;

    // --- Private Helper ---
    void FindPivots(CArrayObj *pivots, int rates_total, const double &high[], const double &low[]);

public:
    CSupportResistance(void);
    ~CSupportResistance(void);

    bool Init(int strength, int prd, int pivot_bars);
    int Calculate(int rates_total, const double &high[], const double &low[]);

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
}

bool CSupportResistance::Init(int strength, int prd, int pivot_bars)
{
    m_strength = strength;
    m_prd = prd;
    m_pivot_bars = pivot_bars;
    return(true);
}

int CSupportResistance::Calculate(int rates_total, const double &high[], const double &low[])
{
    if(rates_total < m_prd) return 0;

    m_sr_levels->Clear();

    // --- 1. Find all pivots in the lookback period ---
    CArrayObj *all_pivots = new CArrayObj();
    all_pivots->SetFreeMode(true); // Important: Array will delete the CPivotPoint objects
    FindPivots(all_pivots, rates_total, high, low);

    // --- 2. Optimized Clustering Logic ---
    bool used_pivots[];
    ArrayResize(used_pivots, all_pivots->Total());
    ArrayInitialize(used_pivots, false);

    double prd_high = high[rates_total-1];
    double prd_low = low[rates_total-1];
    for(int i=1; i<m_prd; i++)
    {
       if(high[rates_total-1-i] > prd_high) prd_high = high[rates_total-1-i];
       if(low[rates_total-1-i] < prd_low) prd_low = low[rates_total-1-i];
    }
    double channel_width = (prd_high - prd_low) * 0.10; // ChannelW = 10%

    for(int i=0; i<all_pivots->Total(); i++)
    {
        if(used_pivots[i]) continue;

        CPivotPoint *pivot1 = all_pivots->At(i);
        if(CheckPointer(pivot1) != POINTER_DYNAMIC) continue;

        double upper_channel = pivot1->price + channel_width;
        double lower_channel = pivot1->price - channel_width;

        int points_in_channel = 0;
        CArrayInt *channel_indices = new CArrayInt();

        for(int j=0; j<all_pivots->Total(); j++)
        {
            CPivotPoint *pivot2 = all_pivots->At(j);
            if(CheckPointer(pivot2) != POINTER_DYNAMIC) continue;

            if(pivot2->price >= lower_channel && pivot2->price <= upper_channel)
            {
                points_in_channel++;
                channel_indices->Add(j);
            }
        }

        if(points_in_channel >= m_strength)
        {
            m_sr_levels->Add(pivot1->price);
            for(int k=0; k<channel_indices->Total(); k++)
            {
                used_pivots[channel_indices->At(k)] = true;
            }
        }
        delete channel_indices;
    }

    delete all_pivots;
    return m_sr_levels->Total();
}

// --- Manual Pivot Detection to match Pine Script's ta.pivothigh/low ---
void CSupportResistance::FindPivots(CArrayObj *pivots, int rates_total, const double &high[], const double &low[])
{
    // Look from the start of the lookback period up to the present
    int start_idx = rates_total - m_prd;
    if(start_idx < m_pivot_bars) start_idx = m_pivot_bars;

    for(int i = start_idx; i < rates_total - m_pivot_bars; i++)
    {
        // Check for Pivot High
        bool is_ph = true;
        for(int j=1; j<=m_pivot_bars; j++)
        {
            if(high[i] < high[i-j] || high[i] <= high[i+j])
            {
                is_ph = false;
                break;
            }
        }
        if(is_ph)
        {
            CPivotPoint *p = new CPivotPoint();
            p->price = high[i];
            pivots->Add(p);
        }

        // Check for Pivot Low
        bool is_pl = true;
        for(int j=1; j<=m_pivot_bars; j++)
        {
            if(low[i] > low[i-j] || low[i] >= low[i+j])
            {
                is_pl = false;
                break;
            }
        }
        if(is_pl)
        {
            CPivotPoint *p = new CPivotPoint();
            p->price = low[i];
            pivots->Add(p);
        }
    }
}
//+------------------------------------------------------------------+
