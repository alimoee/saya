//+------------------------------------------------------------------+
//|                                                          UI.mqh  |
//|                                        Copyright 2024, Jules AI  |
//|                                     User Interface Component     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Jules AI"

class CUI
{
private:
    string m_chart_prefix;
    // --- Object Names ---
    string m_panel_name;
    string m_button_auto_name;
    string m_label_status_name;
    // --- Stat Labels ---
    string m_label_trades_name;
    string m_label_winrate_name;
    string m_label_profit_name;
    // --- Buttons ---
    string m_button_reset_name;
    string m_button_stop_name;
    string m_button_manual_buy_name;
    string m_button_manual_sell_name;


public:
    void Create(long chart_id);
    void Destroy();
    void UpdateStatus(string status_text, color text_color);
    void UpdateStats(int total_trades, int wins, double total_profit);
    void EventHandler(const int id, const long& lparam, const double& dparam, const string& sparam);
};

void CUI::Create(long chart_id)
{
    m_chart_prefix = "TradeBot_" + IntegerToString(chart_id) + "_";
    m_panel_name = m_chart_prefix + "Panel";
    m_button_auto_name = m_chart_prefix + "BtnAuto";
    m_label_status_name = m_chart_prefix + "LblStatus";
    m_label_trades_name = m_chart_prefix + "LblTrades";
    m_label_winrate_name = m_chart_prefix + "LblWinrate";
    m_label_profit_name = m_chart_prefix + "LblProfit";
    m_button_reset_name = m_chart_prefix + "BtnReset";
    m_button_stop_name = m_chart_prefix + "BtnStop";
    m_button_manual_buy_name = m_chart_prefix + "BtnManBuy";
    m_button_manual_sell_name = m_chart_prefix + "BtnManSell";

    // --- Create Main Panel ---
    ObjectCreate(chart_id, m_panel_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(chart_id, m_panel_name, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(chart_id, m_panel_name, OBJPROP_YDISTANCE, 10);
    ObjectSetInteger(chart_id, m_panel_name, OBJPROP_XSIZE, 200);
    ObjectSetInteger(chart_id, m_panel_name, OBJPROP_YSIZE, 180); // Increased size
    ObjectSetInteger(chart_id, m_panel_name, OBJPROP_BGCOLOR, clrDarkSlateGray);
    ObjectSetInteger(chart_id, m_panel_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);

    // --- Create AutoTrade Button ---
    ObjectCreate(chart_id, m_button_auto_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(chart_id, m_button_auto_name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(chart_id, m_button_auto_name, OBJPROP_YDISTANCE, 30);
    ObjectSetInteger(chart_id, m_button_auto_name, OBJPROP_XSIZE, 80);
    ObjectSetInteger(chart_id, m_button_auto_name, OBJPROP_YSIZE, 20);
    ObjectSetString(chart_id, m_button_auto_name, OBJPROP_TEXT, "Auto Off");
    ObjectSetInteger(chart_id, m_button_auto_name, OBJPROP_BGCOLOR, clrGray);

    // --- Create Status Label ---
    ObjectCreate(chart_id, m_label_status_name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(chart_id, m_label_status_name, OBJPROP_XDISTANCE, 110);
    ObjectSetInteger(chart_id, m_label_status_name, OBJPROP_YDISTANCE, 35);
    ObjectSetString(chart_id, m_label_status_name, OBJPROP_TEXT, "Auto Trading is OFF");
    ObjectSetInteger(chart_id, m_label_status_name, OBJPROP_COLOR, clrRed);

    // --- Create Statistics Labels ---
    int y_pos = 60;
    ObjectCreate(chart_id, m_label_trades_name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(chart_id, m_label_trades_name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(chart_id, m_label_trades_name, OBJPROP_YDISTANCE, y_pos);
    ObjectSetString(chart_id, m_label_trades_name, OBJPROP_TEXT, "Trades: 0");
    ObjectSetInteger(chart_id, m_label_trades_name, OBJPROP_COLOR, clrWhite);

    ObjectCreate(chart_id, m_label_winrate_name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(chart_id, m_label_winrate_name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(chart_id, m_label_winrate_name, OBJPROP_YDISTANCE, y_pos + 20);
    ObjectSetString(chart_id, m_label_winrate_name, OBJPROP_TEXT, "Win Rate: 0.0%");
    ObjectSetInteger(chart_id, m_label_winrate_name, OBJPROP_COLOR, clrWhite);

    ObjectCreate(chart_id, m_label_profit_name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(chart_id, m_label_profit_name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(chart_id, m_label_profit_name, OBJPROP_YDISTANCE, y_pos + 40);
    ObjectSetString(chart_id, m_label_profit_name, OBJPROP_TEXT, "Profit: $0.00");
    ObjectSetInteger(chart_id, m_label_profit_name, OBJPROP_COLOR, clrWhite);

    // --- Create Control Buttons ---
    ObjectCreate(chart_id, m_button_reset_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(chart_id, m_button_reset_name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(chart_id, m_button_reset_name, OBJPROP_YDISTANCE, y_pos + 65);
    ObjectSetInteger(chart_id, m_button_reset_name, OBJPROP_XSIZE, 80);
    ObjectSetInteger(chart_id, m_button_reset_name, OBJPROP_YSIZE, 20);
    ObjectSetString(chart_id, m_button_reset_name, OBJPROP_TEXT, "Reset Stats");

    ObjectCreate(chart_id, m_button_stop_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(chart_id, m_button_stop_name, OBJPROP_XDISTANCE, 110);
    ObjectSetInteger(chart_id, m_button_stop_name, OBJPROP_YDISTANCE, y_pos + 65);
    ObjectSetInteger(chart_id, m_button_stop_name, OBJPROP_XSIZE, 80);
    ObjectSetInteger(chart_id, m_button_stop_name, OBJPROP_YSIZE, 20);
    ObjectSetString(chart_id, m_button_stop_name, OBJPROP_TEXT, "Close All");
    ObjectSetInteger(chart_id, m_button_stop_name, OBJPROP_BGCOLOR, C'255,69,0'); // RedOrange

    // --- Manual Trade Buttons ---
    int y_manual_pos = y_pos + 95;
    ObjectCreate(chart_id, m_button_manual_buy_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(chart_id, m_button_manual_buy_name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(chart_id, m_button_manual_buy_name, OBJPROP_YDISTANCE, y_manual_pos);
    ObjectSetInteger(chart_id, m_button_manual_buy_name, OBJPROP_XSIZE, 80);
    ObjectSetInteger(chart_id, m_button_manual_buy_name, OBJPROP_YSIZE, 20);
    ObjectSetString(chart_id, m_button_manual_buy_name, OBJPROP_TEXT, "Manual Buy");
    ObjectSetInteger(chart_id, m_button_manual_buy_name, OBJPROP_BGCOLOR, clrGreen);

    ObjectCreate(chart_id, m_button_manual_sell_name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(chart_id, m_button_manual_sell_name, OBJPROP_XDISTANCE, 110);
    ObjectSetInteger(chart_id, m_button_manual_sell_name, OBJPROP_YDISTANCE, y_manual_pos);
    ObjectSetInteger(chart_id, m_button_manual_sell_name, OBJPROP_XSIZE, 80);
    ObjectSetInteger(chart_id, m_button_manual_sell_name, OBJPROP_YSIZE, 20);
    ObjectSetString(chart_id, m_button_manual_sell_name, OBJPROP_TEXT, "Manual Sell");
    ObjectSetInteger(chart_id, m_button_manual_sell_name, OBJPROP_BGCOLOR, clrRed);
}

void CUI::Destroy()
{
    string objects_to_delete[] = {
        m_panel_name, m_button_auto_name, m_label_status_name,
        m_label_trades_name, m_label_winrate_name, m_label_profit_name,
        m_button_reset_name, m_button_stop_name,
        m_button_manual_buy_name, m_button_manual_sell_name
    };
    for(int i = 0; i < ArraySize(objects_to_delete); i++)
    {
        ObjectDelete(0, objects_to_delete[i]);
    }
}

void CUI::UpdateStatus(string status_text, color text_color)
{
    ObjectSetString(0, m_label_status_name, OBJPROP_TEXT, status_text);
    ObjectSetInteger(0, m_label_status_name, OBJPROP_COLOR, text_color);
    ObjectSetString(0, m_button_auto_name, OBJPROP_TEXT, StringContains(status_text, "ON") ? "Auto On" : "Auto Off");
    ObjectSetInteger(0, m_button_auto_name, OBJPROP_BGCOLOR, StringContains(status_text, "ON") ? clrLimeGreen : clrGray);
    ChartRedraw();
}

void CUI::UpdateStats(int total_trades, int wins, double total_profit)
{
    ObjectSetString(0, m_label_trades_name, OBJPROP_TEXT, "Trades: " + (string)total_trades);

    double win_rate = (total_trades > 0) ? ((double)wins / total_trades) * 100.0 : 0.0;
    ObjectSetString(0, m_label_winrate_name, OBJPROP_TEXT, "Win Rate: " + StringFormat("%.1f", win_rate) + "%");

    string profit_str = "Profit: " + StringFormat("%.2f", total_profit);
    ObjectSetString(0, m_label_profit_name, OBJPROP_TEXT, profit_str);
    ObjectSetInteger(0, m_label_profit_name, OBJPROP_COLOR, (total_profit >= 0) ? clrLimeGreen : clrRed);

    ChartRedraw();
}

void CUI::EventHandler(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == m_button_auto_name)
        {
            // This event will be handled in the main .mq5 file
            // to toggle the global 'isAutoTradingEnabled' variable.
        }
    }
}
//+------------------------------------------------------------------+
