//+------------------------------------------------------------------+
//|                                                  ChartPanel.mqh |
//|                                  Copyright 2024, Jules The AI |
//|                  Class for creating an on-chart GUI panel        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules The AI"

//+------------------------------------------------------------------+
//| CChartPanel Class                                                |
//+------------------------------------------------------------------+
class CChartPanel
{
private:
    long              m_chart_id;
    string            m_ea_name;
    int               m_panel_x;
    int               m_panel_y;

    // --- Object Names ---
    string            m_prefix;
    string            m_panel_name;
    string            m_start_button_name;
    string            m_stop_button_name;
    string            m_status_label_name;
    string            m_profit_label_name;

    void CreateLabel(string name, int x, int y, string text, color clr);
    void CreateButton(string name, int x, int y, string text, int width, int height);

public:
    bool              IsTradingEnabled;

                      CChartPanel(void);
                     ~CChartPanel(void);

    void              Init(long chart_id, string ea_name, int x_pos, int y_pos);
    void              Update(double profit, double spread);
    void              EventHandler(const int id, const long &lparam, const double &dparam, const string &sparam);
    void              Destroy(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CChartPanel::CChartPanel(void) : IsTradingEnabled(true) // Trading is enabled by default
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CChartPanel::~CChartPanel(void)
{
    Destroy();
}

//+------------------------------------------------------------------+
//| Initialize Panel                                                 |
//+------------------------------------------------------------------+
void CChartPanel::Init(long chart_id, string ea_name, int x_pos, int y_pos)
{
    m_chart_id = chart_id;
    m_ea_name = ea_name;
    m_panel_x = x_pos;
    m_panel_y = y_pos;
    m_prefix = m_ea_name + "_";

    // --- Create Panel Background ---
    m_panel_name = m_prefix + "Panel";
    ObjectCreate(m_chart_id, m_panel_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(m_chart_id, m_panel_name, OBJPROP_XDISTANCE, m_panel_x);
    ObjectSetInteger(m_chart_id, m_panel_name, OBJPROP_YDISTANCE, m_panel_y);
    ObjectSetInteger(m_chart_id, m_panel_name, OBJPROP_XSIZE, 180);
    ObjectSetInteger(m_chart_id, m_panel_name, OBJPROP_YSIZE, 100);
    ObjectSetInteger(m_chart_id, m_panel_name, OBJPROP_BGCOLOR, clrBlack);
    ObjectSetInteger(m_chart_id, m_panel_name, OBJPROP_BORDER_COLOR, clrGray);
    ObjectSetInteger(m_chart_id, m_panel_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);

    // --- Create Labels ---
    CreateLabel(m_prefix + "Title", m_panel_x + 10, m_panel_y + 10, m_ea_name, clrWhite);
    m_status_label_name = m_prefix + "Status";
    m_profit_label_name = m_prefix + "Profit";
    CreateLabel(m_status_label_name, m_panel_x + 10, m_panel_y + 30, "Status: Trading ENABLED", clrLime);
    CreateLabel(m_profit_label_name, m_panel_x + 10, m_panel_y + 50, "P/L: 0.00", clrWhite);

    // --- Create Buttons ---
    m_start_button_name = m_prefix + "StartButton";
    m_stop_button_name = m_prefix + "StopButton";
    CreateButton(m_start_button_name, m_panel_x + 10, m_panel_y + 70, "START", 80, 20);
    CreateButton(m_stop_button_name, m_panel_x + 100, m_panel_y + 70, "STOP", 70, 20);
}

//+------------------------------------------------------------------+
//| Update Panel Data                                                |
//+------------------------------------------------------------------+
void CChartPanel::Update(double profit, double spread)
{
    ObjectSetString(m_chart_id, m_profit_label_name, OBJPROP_TEXT, "P/L: " + DoubleToString(profit, 2));
    // Could add spread, etc. here later
}

//+------------------------------------------------------------------+
//| Handle Chart Events                                              |
//+------------------------------------------------------------------+
void CChartPanel::EventHandler(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == m_start_button_name)
        {
            IsTradingEnabled = true;
            ObjectSetString(m_chart_id, m_status_label_name, OBJPROP_TEXT, "Status: Trading ENABLED");
            ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_COLOR, clrLime);
            ChartRedraw(m_chart_id);
        }
        else if(sparam == m_stop_button_name)
        {
            IsTradingEnabled = false;
            ObjectSetString(m_chart_id, m_status_label_name, OBJPROP_TEXT, "Status: Trading DISABLED");
            ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_COLOR, clrRed);
            ChartRedraw(m_chart_id);
        }
    }
}

//+------------------------------------------------------------------+
//| Destroy Panel Objects                                            |
//+------------------------------------------------------------------+
void CChartPanel::Destroy(void)
{
    ObjectDelete(m_chart_id, m_panel_name);
    ObjectDelete(m_chart_id, m_prefix + "Title");
    ObjectDelete(m_chart_id, m_status_label_name);
    ObjectDelete(m_chart_id, m_profit_label_name);
    ObjectDelete(m_chart_id, m_start_button_name);
    ObjectDelete(m_chart_id, m_stop_button_name);
    ChartRedraw(m_chart_id);
}

// --- Helper methods for creating objects ---
void CChartPanel::CreateLabel(string name, int x, int y, string text, color clr)
{
    ObjectCreate(m_chart_id, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(m_chart_id, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(m_chart_id, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(m_chart_id, name, OBJPROP_TEXT, text);
    ObjectSetInteger(m_chart_id, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(m_chart_id, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CChartPanel::CreateButton(string name, int x, int y, string text, int width, int height)
{
    ObjectCreate(m_chart_id, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(m_chart_id, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(m_chart_id, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(m_chart_id, name, OBJPROP_XSIZE, width);
    ObjectSetInteger(m_chart_id, name, OBJPROP_YSIZE, height);
    ObjectSetString(m_chart_id, name, OBJPROP_TEXT, text);
    ObjectSetInteger(m_chart_id, name, OBJPROP_BGCOLOR, clrDimGray);
    ObjectSetInteger(m_chart_id, name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(m_chart_id, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}
//+------------------------------------------------------------------+
