// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vi2c_tx_tb.h for the primary calling header

#ifndef VERILATED_VI2C_TX_TB___024ROOT_H_
#define VERILATED_VI2C_TX_TB___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vi2c_tx_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vi2c_tx_tb___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ i2c_tx_tb__DOT__clk_ref;
        CData/*0:0*/ i2c_tx_tb__DOT__rst_n;
        CData/*0:0*/ i2c_tx_tb__DOT__bare_scl;
        CData/*0:0*/ i2c_tx_tb__DOT__bare_tx_load;
        CData/*0:0*/ i2c_tx_tb__DOT__bare_tx_drive_en;
        CData/*7:0*/ i2c_tx_tb__DOT__bare_tx_data;
        CData/*0:0*/ i2c_tx_tb__DOT__bare_sda_oe;
        CData/*0:0*/ i2c_tx_tb__DOT__master_scl;
        CData/*0:0*/ i2c_tx_tb__DOT__master_sda_drive;
        CData/*0:0*/ i2c_tx_tb__DOT__master_sda_val;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_sda_oe;
        CData/*0:0*/ i2c_tx_tb__DOT__tx_sda_oe;
        CData/*0:0*/ i2c_tx_tb__DOT__sda_line;
        CData/*0:0*/ i2c_tx_tb__DOT__scl_sync;
        CData/*0:0*/ i2c_tx_tb__DOT__sda_sync;
        CData/*6:0*/ i2c_tx_tb__DOT__dut_addr7;
        CData/*0:0*/ i2c_tx_tb__DOT__dut_rw;
        CData/*0:0*/ i2c_tx_tb__DOT__gc_match;
        CData/*0:0*/ i2c_tx_tb__DOT__ptr_set;
        CData/*0:0*/ i2c_tx_tb__DOT__wr_byte;
        CData/*0:0*/ i2c_tx_tb__DOT__rd_byte;
        CData/*7:0*/ i2c_tx_tb__DOT__ptr_set_data;
        CData/*7:0*/ i2c_tx_tb__DOT__wr_byte_data;
        CData/*0:0*/ i2c_tx_tb__DOT__tx_load;
        CData/*7:0*/ i2c_tx_tb__DOT__rb_rdata;
        CData/*7:0*/ i2c_tx_tb__DOT__unnamedblk4__DOT__unnamedblk5__DOT__unnamedblk6__DOT__rand_byte;
        CData/*0:0*/ i2c_tx_tb__DOT__dut_bare__DOT__scl_sync_prev_q;
        CData/*7:0*/ i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q;
        CData/*0:0*/ i2c_tx_tb__DOT__bus_sync__DOT__scl_meta_q;
        CData/*0:0*/ i2c_tx_tb__DOT__bus_sync__DOT__sda_meta_q;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__scl_prev_q;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__sda_prev_q;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__scl_rise;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__scl_fall;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__start_cond;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__stop_cond;
        CData/*3:0*/ i2c_tx_tb__DOT__rx_dut__DOT__state_q;
        CData/*7:0*/ i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q;
        CData/*3:0*/ i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q;
        CData/*6:0*/ i2c_tx_tb__DOT__rx_dut__DOT__addr7_q;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__rw_q;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__master_nack_q;
        CData/*7:0*/ i2c_tx_tb__DOT__rx_dut__DOT__byte_latched_q;
        CData/*1:0*/ i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__tx_load_pending_q;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__capture_state;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__byte_complete;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__ack_end;
        CData/*0:0*/ i2c_tx_tb__DOT__rx_dut__DOT__address_ack_ok;
        CData/*7:0*/ i2c_tx_tb__DOT__rdec__DOT__ptr_q;
        CData/*7:0*/ i2c_tx_tb__DOT__rdec__DOT__rd_data_q;
        CData/*7:0*/ i2c_tx_tb__DOT__rbank__DOT__mode1_r;
        CData/*7:0*/ i2c_tx_tb__DOT__rbank__DOT__mode2_r;
        CData/*7:0*/ i2c_tx_tb__DOT__rbank__DOT__subadr1_r;
        CData/*7:0*/ i2c_tx_tb__DOT__rbank__DOT__subadr2_r;
        CData/*7:0*/ i2c_tx_tb__DOT__rbank__DOT__subadr3_r;
        CData/*7:0*/ i2c_tx_tb__DOT__rbank__DOT__allcalladr_r;
        CData/*7:0*/ i2c_tx_tb__DOT__rbank__DOT__prescale_r;
        CData/*0:0*/ i2c_tx_tb__DOT__rbank__DOT__is_led_addr;
        CData/*0:0*/ i2c_tx_tb__DOT__dut__DOT__scl_sync_prev_q;
        CData/*7:0*/ i2c_tx_tb__DOT__dut__DOT__shift_reg_q;
        CData/*7:0*/ __Vtask_i2c_tx_tb__DOT__m_send_byte__51__data;
    };
    struct {
        CData/*7:0*/ __Vtask_i2c_tx_tb__DOT__m_read_byte__86__data;
        CData/*0:0*/ __Vtask_i2c_tx_tb__DOT__m_read_byte__86__master_nack;
        CData/*7:0*/ __Vtask_i2c_tx_tb__DOT__m_send_byte__106__data;
        CData/*7:0*/ __Vtask_i2c_tx_tb__DOT__m_send_byte__123__data;
        CData/*0:0*/ __VstlFirstIteration;
        CData/*0:0*/ __Vtrigprevexpr___TOP__i2c_tx_tb__DOT__clk_ref__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__i2c_tx_tb__DOT__rst_n__0;
        CData/*0:0*/ __VactContinue;
        SData/*15:0*/ i2c_tx_tb__DOT__rbank__DOT__chan_enable_r;
        SData/*15:0*/ i2c_tx_tb__DOT__rbank__DOT__chan_polarity_r;
        IData/*31:0*/ i2c_tx_tb__DOT__errors;
        IData/*31:0*/ i2c_tx_tb__DOT__checks;
        IData/*31:0*/ i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q;
        IData/*31:0*/ i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q;
        IData/*31:0*/ __VactIterCount;
        VlUnpacked<SData/*11:0*/, 16> i2c_tx_tb__DOT__rbank__DOT__shadow_on_count;
        VlUnpacked<SData/*11:0*/, 16> i2c_tx_tb__DOT__rbank__DOT__shadow_off_count;
        VlUnpacked<CData/*0:0*/, 16> i2c_tx_tb__DOT__rbank__DOT__shadow_full_on;
        VlUnpacked<CData/*0:0*/, 16> i2c_tx_tb__DOT__rbank__DOT__shadow_full_off;
    };
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h2c9fe19e__0;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<3> __VactTriggered;
    VlTriggerVec<3> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vi2c_tx_tb__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vi2c_tx_tb___024root(Vi2c_tx_tb__Syms* symsp, const char* v__name);
    ~Vi2c_tx_tb___024root();
    VL_UNCOPYABLE(Vi2c_tx_tb___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
