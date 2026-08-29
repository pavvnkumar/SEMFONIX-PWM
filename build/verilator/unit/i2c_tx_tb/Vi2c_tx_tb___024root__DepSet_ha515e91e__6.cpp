// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vi2c_tx_tb.h for the primary calling header

#include "Vi2c_tx_tb__pch.h"
#include "Vi2c_tx_tb___024root.h"

VL_INLINE_OPT VlCoroutine Vi2c_tx_tb___024root___eval_initial__TOP__Vtiming__2(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_initial__TOP__Vtiming__2\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (1U) {
        co_await vlSelfRef.__VdlySched.delay(0x1388ULL, 
                                             nullptr, 
                                             "tb/unit/i2c/i2c_tx_tb.sv", 
                                             138);
        vlSelfRef.i2c_tx_tb__DOT__clk_ref = (1U & (~ (IData)(vlSelfRef.i2c_tx_tb__DOT__clk_ref)));
    }
}

void Vi2c_tx_tb___024root___act_comb__TOP__0(Vi2c_tx_tb___024root* vlSelf);

void Vi2c_tx_tb___024root___eval_act(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_act\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((5ULL & vlSelfRef.__VactTriggered.word(0U))) {
        Vi2c_tx_tb___024root___act_comb__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vi2c_tx_tb___024root___act_comb__TOP__0(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___act_comb__TOP__0\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.i2c_tx_tb__DOT__bare_sda_oe = ((~ ((IData)(vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q) 
                                                 >> 7U)) 
                                             & (IData)(vlSelfRef.i2c_tx_tb__DOT__bare_tx_drive_en));
    vlSelfRef.i2c_tx_tb__DOT__sda_line = (1U & (~ (
                                                   ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__master_sda_val)) 
                                                    & (IData)(vlSelfRef.i2c_tx_tb__DOT__master_sda_drive)) 
                                                   | ((7U 
                                                       == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))
                                                       ? (IData)(vlSelfRef.i2c_tx_tb__DOT__tx_sda_oe)
                                                       : (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_sda_oe)))));
}

void Vi2c_tx_tb___024root___nba_sequent__TOP__0(Vi2c_tx_tb___024root* vlSelf);
void Vi2c_tx_tb___024root___nba_sequent__TOP__1(Vi2c_tx_tb___024root* vlSelf);

void Vi2c_tx_tb___024root___eval_nba(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_nba\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vi2c_tx_tb___024root___nba_sequent__TOP__0(vlSelf);
    }
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vi2c_tx_tb___024root___nba_sequent__TOP__1(vlSelf);
    }
    if ((7ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vi2c_tx_tb___024root___act_comb__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vi2c_tx_tb___024root___nba_sequent__TOP__0(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___nba_sequent__TOP__0\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(vlSelfRef.i2c_tx_tb__DOT__bare_tx_load)) {
        VL_WRITEF_NX("[TX DEBUG] TX LOAD: tx_load=%b enable=%b tx_data=0x%02x shift_before=0x%02x shift_after=0x%02x scl=%b\n",0,
                     1,vlSelfRef.i2c_tx_tb__DOT__bare_tx_load,
                     1,(IData)(vlSelfRef.i2c_tx_tb__DOT__bare_tx_drive_en),
                     8,vlSelfRef.i2c_tx_tb__DOT__bare_tx_data,
                     8,(IData)(vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q),
                     8,vlSelfRef.i2c_tx_tb__DOT__bare_tx_data,
                     1,(IData)(vlSelfRef.i2c_tx_tb__DOT__bare_scl));
    }
    if (VL_UNLIKELY((((IData)(vlSelfRef.i2c_tx_tb__DOT__bare_tx_drive_en) 
                      & ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__bare_scl)) 
                         & (IData)(vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__scl_sync_prev_q))) 
                     & (~ (IData)(vlSelfRef.i2c_tx_tb__DOT__bare_tx_load))))) {
        VL_WRITEF_NX("[TX DEBUG] SHIFT: shift_before=0x%02x shift_after=0x%02x scl=%b\n",0,
                     8,vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q,
                     8,(0xfeU & ((IData)(vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q) 
                                 << 1U)),1,(IData)(vlSelfRef.i2c_tx_tb__DOT__bare_scl));
    }
    if (VL_UNLIKELY(((IData)(vlSelfRef.i2c_tx_tb__DOT__rd_byte) 
                     | (IData)(vlSelfRef.i2c_tx_tb__DOT__tx_load)))) {
        VL_WRITEF_NX("[READ PIPE DEBUG] rd_byte=%b tx_load=%b ptr=0x%02x rb_addr=0x%02x rb_rdata=0x%02x rd_data=0x%02x tx_drive=%b tx_sda_oe=%b\n",0,
                     1,vlSelfRef.i2c_tx_tb__DOT__rd_byte,
                     1,(IData)(vlSelfRef.i2c_tx_tb__DOT__tx_load),
                     8,vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q,
                     8,(IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q),
                     8,vlSelfRef.i2c_tx_tb__DOT__rb_rdata,
                     8,(IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__rd_data_q),
                     1,(7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)),
                     1,(IData)(vlSelfRef.i2c_tx_tb__DOT__tx_sda_oe));
    }
    if (VL_UNLIKELY(vlSelfRef.i2c_tx_tb__DOT__tx_load)) {
        VL_WRITEF_NX("[TX DEBUG] TX LOAD: tx_load=%b enable=%b tx_data=0x%02x shift_before=0x%02x shift_after=0x%02x scl=%b\n",0,
                     1,vlSelfRef.i2c_tx_tb__DOT__tx_load,
                     1,(7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)),
                     8,(IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__rd_data_q),
                     8,vlSelfRef.i2c_tx_tb__DOT__dut__DOT__shift_reg_q,
                     8,(IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__rd_data_q),
                     1,vlSelfRef.i2c_tx_tb__DOT__scl_sync);
    }
    if (VL_UNLIKELY((((7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                      & ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__scl_sync)) 
                         & (IData)(vlSelfRef.i2c_tx_tb__DOT__dut__DOT__scl_sync_prev_q))) 
                     & (~ (IData)(vlSelfRef.i2c_tx_tb__DOT__tx_load))))) {
        VL_WRITEF_NX("[TX DEBUG] SHIFT: shift_before=0x%02x shift_after=0x%02x scl=%b\n",0,
                     8,vlSelfRef.i2c_tx_tb__DOT__dut__DOT__shift_reg_q,
                     8,(0xfeU & ((IData)(vlSelfRef.i2c_tx_tb__DOT__dut__DOT__shift_reg_q) 
                                 << 1U)),1,(IData)(vlSelfRef.i2c_tx_tb__DOT__scl_sync));
    }
    if (VL_UNLIKELY(((((2U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                       | (4U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) 
                      | (6U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) 
                     | (8U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))))) {
        VL_WRITEF_NX("[I2C ACK DEBUG] state=%0# addr7=0x%02x rw=%b addr_match=%b gc_match=%b sda_oe=%b tx_load=%b tx_en=%b rd_data_event=%b shift=0x%02x scl=%b sda=%b\n",0,
                     4,vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q,
                     7,(IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__addr7_q),
                     1,vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__rw_q,
                     1,((IData)(vlSelfRef.i2c_tx_tb__DOT__gc_match) 
                        | (0x55U == (IData)(vlSelfRef.i2c_tx_tb__DOT__dut_addr7))),
                     1,(IData)(vlSelfRef.i2c_tx_tb__DOT__gc_match),
                     1,vlSelfRef.i2c_tx_tb__DOT__rx_sda_oe,
                     1,(IData)(vlSelfRef.i2c_tx_tb__DOT__tx_load),
                     1,(7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)),
                     1,(IData)(vlSelfRef.i2c_tx_tb__DOT__rd_byte),
                     8,vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q,
                     1,(IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q),
                     1,vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q);
    }
    if (VL_UNLIKELY(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete)) {
        VL_WRITEF_NX("[I2C DEBUG] BYTE COMPLETE: state=%0# shift_reg=0x%02x bit_cnt=%0# scl=%b sda=%b\n",0,
                     4,vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q,
                     8,(IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q),
                     4,vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q,
                     1,(IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q),
                     1,vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q);
    }
    if (VL_UNLIKELY(vlSelfRef.i2c_tx_tb__DOT__ptr_set)) {
        VL_WRITEF_NX("[I2C DEBUG] PTR EVENT: ptr_set_data_o=0x%02x\n",0,
                     8,vlSelfRef.i2c_tx_tb__DOT__ptr_set_data);
    }
    if (VL_UNLIKELY(vlSelfRef.i2c_tx_tb__DOT__wr_byte)) {
        VL_WRITEF_NX("[I2C DEBUG] WR EVENT: wr_byte_data_o=0x%02x\n",0,
                     8,vlSelfRef.i2c_tx_tb__DOT__wr_byte_data);
    }
    if (VL_UNLIKELY(vlSelfRef.i2c_tx_tb__DOT__rd_byte)) {
        VL_WRITEF_NX("[I2C DEBUG] RD EVENT: rd_byte_o=1 tx_load_pending=1\n",0);
    }
    if (VL_UNLIKELY(vlSelfRef.i2c_tx_tb__DOT__tx_load)) {
        VL_WRITEF_NX("[I2C DEBUG] TX LOAD: tx_load_o=1\n",0);
    }
}

VL_INLINE_OPT void Vi2c_tx_tb___024root___nba_sequent__TOP__1(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___nba_sequent__TOP__1\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*7:0*/ __Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__Vfuncout;
    __Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__Vfuncout = 0;
    CData/*7:0*/ __Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__addr;
    __Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__addr = 0;
    CData/*7:0*/ __Vdly__i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q;
    __Vdly__i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q = 0;
    IData/*31:0*/ __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q = 0;
    CData/*0:0*/ __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q = 0;
    IData/*31:0*/ __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q = 0;
    CData/*0:0*/ __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q = 0;
    CData/*3:0*/ __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q = 0;
    CData/*7:0*/ __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q = 0;
    CData/*1:0*/ __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q = 0;
    CData/*3:0*/ __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 0;
    CData/*7:0*/ __Vdly__i2c_tx_tb__DOT__rdec__DOT__ptr_q;
    __Vdly__i2c_tx_tb__DOT__rdec__DOT__ptr_q = 0;
    CData/*7:0*/ __Vdly__i2c_tx_tb__DOT__dut__DOT__shift_reg_q;
    __Vdly__i2c_tx_tb__DOT__dut__DOT__shift_reg_q = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0 = 0;
    CData/*3:0*/ __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0;
    __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1 = 0;
    CData/*3:0*/ __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1;
    __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v2;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v2 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v2;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v2 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v3;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v3 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v4;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v4 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v5;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v5 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v6;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v6 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v7;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v7 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v8;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v8 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v9;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v9 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v10;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v10 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v11;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v11 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v12;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v12 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v13;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v13 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v14;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v14 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v15;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v15 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v16;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v16 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v17;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v17 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v18;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v18 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v18;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v18 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v19;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v19 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v20;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v20 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v21;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v21 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v22;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v22 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v23;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v23 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v24;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v24 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v25;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v25 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v26;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v26 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v27;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v27 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v28;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v28 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v29;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v29 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v30;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v30 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v31;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v31 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v32;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v32 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v33;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v33 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v34;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v34 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0 = 0;
    CData/*3:0*/ __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0;
    __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1 = 0;
    CData/*3:0*/ __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1;
    __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v2;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v2 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v2;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v2 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v3;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v3 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v4;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v4 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v5;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v5 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v6;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v6 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v7;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v7 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v8;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v8 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v9;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v9 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v10;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v10 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v11;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v11 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v12;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v12 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v13;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v13 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v14;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v14 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v15;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v15 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v16;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v16 = 0;
    CData/*7:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v17;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v17 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v18;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v18 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v18;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v18 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v19;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v19 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v20;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v20 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v21;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v21 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v22;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v22 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v23;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v23 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v24;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v24 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v25;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v25 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v26;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v26 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v27;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v27 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v28;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v28 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v29;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v29 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v30;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v30 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v31;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v31 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v32;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v32 = 0;
    CData/*3:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v33;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v33 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v34;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v34 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0 = 0;
    CData/*3:0*/ __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0;
    __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v1;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v1 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v1;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v1 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v2;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v2 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v3;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v3 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v4;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v4 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v5;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v5 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v6;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v6 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v7;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v7 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v8;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v8 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v9;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v9 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v10;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v10 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v11;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v11 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v12;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v12 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v13;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v13 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v14;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v14 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v15;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v15 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v16;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v16 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v17;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v17 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0 = 0;
    CData/*3:0*/ __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0;
    __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v1;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v1 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v1;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v1 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v2;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v2 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v3;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v3 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v4;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v4 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v5;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v5 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v6;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v6 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v7;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v7 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v8;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v8 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v9;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v9 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v10;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v10 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v11;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v11 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v12;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v12 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v13;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v13 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v14;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v14 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v15;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v15 = 0;
    CData/*0:0*/ __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v16;
    __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v16 = 0;
    CData/*0:0*/ __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v17;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v17 = 0;
    // Body
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q 
        = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q 
        = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q 
        = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q;
    __Vdly__i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q 
        = vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q 
        = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q 
        = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q 
        = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q 
        = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q;
    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q;
    __Vdly__i2c_tx_tb__DOT__dut__DOT__shift_reg_q = vlSelfRef.i2c_tx_tb__DOT__dut__DOT__shift_reg_q;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v1 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v17 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v1 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v17 = 0U;
    __Vdly__i2c_tx_tb__DOT__rdec__DOT__ptr_q = vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v2 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v18 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v34 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v2 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v18 = 0U;
    __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v34 = 0U;
    if (vlSelfRef.i2c_tx_tb__DOT__rst_n) {
        if (vlSelfRef.i2c_tx_tb__DOT__bare_tx_load) {
            __Vdly__i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q 
                = vlSelfRef.i2c_tx_tb__DOT__bare_tx_data;
        } else if (((IData)(vlSelfRef.i2c_tx_tb__DOT__bare_tx_drive_en) 
                    & ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__bare_scl)) 
                       & (IData)(vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__scl_sync_prev_q)))) {
            __Vdly__i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q 
                = (0xfeU & ((IData)(vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q) 
                            << 1U));
        }
        if (((IData)(vlSelfRef.i2c_tx_tb__DOT__scl_sync) 
             == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q))) {
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q = 0U;
        } else if ((1U <= vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q)) {
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q 
                = vlSelfRef.i2c_tx_tb__DOT__scl_sync;
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q = 0U;
        } else {
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q 
                = ((IData)(1U) + vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q);
        }
        if (((IData)(vlSelfRef.i2c_tx_tb__DOT__sda_sync) 
             == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q))) {
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q = 0U;
        } else if ((1U <= vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q)) {
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q 
                = vlSelfRef.i2c_tx_tb__DOT__sda_sync;
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q = 0U;
        } else {
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q 
                = ((IData)(1U) + vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q);
        }
        if (vlSelfRef.i2c_tx_tb__DOT__tx_load) {
            __Vdly__i2c_tx_tb__DOT__dut__DOT__shift_reg_q 
                = vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__rd_data_q;
        } else if (((7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                    & ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__scl_sync)) 
                       & (IData)(vlSelfRef.i2c_tx_tb__DOT__dut__DOT__scl_sync_prev_q)))) {
            __Vdly__i2c_tx_tb__DOT__dut__DOT__shift_reg_q 
                = (0xfeU & ((IData)(vlSelfRef.i2c_tx_tb__DOT__dut__DOT__shift_reg_q) 
                            << 1U));
        }
        if (vlSelfRef.i2c_tx_tb__DOT__ptr_set) {
            __Vdly__i2c_tx_tb__DOT__rdec__DOT__ptr_q 
                = vlSelfRef.i2c_tx_tb__DOT__ptr_set_data;
        } else if (((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte) 
                    | (IData)(vlSelfRef.i2c_tx_tb__DOT__rd_byte))) {
            if ((0x20U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__mode1_r))) {
                __Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__addr 
                    = vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q;
                __Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__Vfuncout 
                    = ((0x45U == (IData)(__Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__addr))
                        ? 0U : ((0xfeU == (IData)(__Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__addr))
                                 ? 0U : (0xffU & ((IData)(1U) 
                                                  + (IData)(__Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__addr)))));
                __Vdly__i2c_tx_tb__DOT__rdec__DOT__ptr_q 
                    = __Vfunc_i2c_tx_tb__DOT__rdec__DOT__next_ptr_addr__137__Vfuncout;
            }
        }
        if (vlSelfRef.i2c_tx_tb__DOT__wr_byte) {
            if ((0U != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                if ((1U != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                    if ((2U != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                        if ((3U != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                            if ((4U != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                if ((5U != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                    if ((0xfeU != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                        if ((0x50U 
                                             != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                            if ((0x51U 
                                                 != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                if (
                                                    (0x52U 
                                                     != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                    if (
                                                        (0x53U 
                                                         != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                        if (
                                                            (0x54U 
                                                             != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                            if (
                                                                (0x55U 
                                                                 != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                if (
                                                                    (0x56U 
                                                                     != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                    if (vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__is_led_addr) {
                                                                        if (
                                                                            (2U 
                                                                             & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                                - (IData)(2U)))) {
                                                                            if (
                                                                                (1U 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0 
                                                                                = 
                                                                                (0xfU 
                                                                                & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                                - (IData)(6U)) 
                                                                                >> 2U));
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0 = 1U;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0 
                                                                                = 
                                                                                (0xfU 
                                                                                & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                                - (IData)(6U)) 
                                                                                >> 2U));
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0 = 1U;
                                                                            } else {
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1 
                                                                                = 
                                                                                (0xfU 
                                                                                & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                                - (IData)(6U)) 
                                                                                >> 2U));
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1 = 1U;
                                                                            }
                                                                        }
                                                                        if (
                                                                            (1U 
                                                                             & (~ 
                                                                                (1U 
                                                                                & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                                - (IData)(2U)) 
                                                                                >> 1U))))) {
                                                                            if (
                                                                                (1U 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0 
                                                                                = 
                                                                                (0xfU 
                                                                                & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                                - (IData)(6U)) 
                                                                                >> 2U));
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0 = 1U;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0 
                                                                                = 
                                                                                (0xfU 
                                                                                & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                                - (IData)(6U)) 
                                                                                >> 2U));
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0 = 1U;
                                                                            } else {
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1 
                                                                                = 
                                                                                (0xfU 
                                                                                & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                                - (IData)(6U)) 
                                                                                >> 2U));
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1 = 1U;
                                                                            }
                                                                        }
                                                                    } else {
                                                                        if (
                                                                            (0xfaU 
                                                                             != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                            if (
                                                                                (0xfbU 
                                                                                != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                                if (
                                                                                (0xfcU 
                                                                                != (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                                if (
                                                                                (0xfdU 
                                                                                == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v1 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v1 = 1U;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v2 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v3 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v4 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v5 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v6 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v7 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v8 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v9 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v10 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v11 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v12 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v13 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v14 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v15 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v16 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                }
                                                                                }
                                                                                if (
                                                                                (0xfcU 
                                                                                == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v2 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v2 = 1U;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v3 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v4 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v5 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v6 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v7 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v8 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v9 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v10 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v11 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v12 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v13 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v14 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v15 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v16 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v17 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                                } else if (
                                                                                (0xfdU 
                                                                                == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v18 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v18 = 1U;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v19 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v20 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v21 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v22 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v23 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v24 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v25 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v26 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v27 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v28 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v29 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v30 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v31 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v32 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v33 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                                }
                                                                            }
                                                                            if (
                                                                                (0xfbU 
                                                                                == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v1 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v1 = 1U;
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v2 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v3 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v4 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v5 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v6 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v7 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v8 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v9 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v10 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v11 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v12 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v13 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v14 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v15 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                                __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v16 
                                                                                = 
                                                                                (1U 
                                                                                & ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                                                >> 4U));
                                                                            }
                                                                        }
                                                                        if (
                                                                            (0xfaU 
                                                                             == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v2 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v2 = 1U;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v3 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v4 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v5 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v6 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v7 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v8 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v9 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v10 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v11 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v12 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v13 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v14 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v15 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v16 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v17 
                                                                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                                                        } else if (
                                                                                (0xfbU 
                                                                                == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v18 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v18 = 1U;
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v19 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v20 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v21 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v22 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v23 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v24 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v25 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v26 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v27 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v28 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v29 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v30 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v31 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v32 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                            __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v33 
                                                                                = 
                                                                                (0xfU 
                                                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                if (
                                                    (0x52U 
                                                     == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                    vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_polarity_r 
                                                        = 
                                                        ((0xff00U 
                                                          & (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_polarity_r)) 
                                                         | (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                                } else if (
                                                           (0x53U 
                                                            == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                                    vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_polarity_r 
                                                        = 
                                                        ((0xffU 
                                                          & (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_polarity_r)) 
                                                         | ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                            << 8U));
                                                }
                                            }
                                        }
                                        if ((0x50U 
                                             == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                            vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_enable_r 
                                                = (
                                                   (0xff00U 
                                                    & (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_enable_r)) 
                                                   | (IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data));
                                        } else if (
                                                   (0x51U 
                                                    == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                            vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_enable_r 
                                                = (
                                                   (0xffU 
                                                    & (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_enable_r)) 
                                                   | ((IData)(vlSelfRef.i2c_tx_tb__DOT__wr_byte_data) 
                                                      << 8U));
                                        }
                                    }
                                    if ((0xfeU == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__prescale_r 
                                            = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                    }
                                }
                                if ((5U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                    vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__allcalladr_r 
                                        = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                                }
                            }
                            if ((4U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                                vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__subadr3_r 
                                    = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                            }
                        }
                        if ((3U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                            vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__subadr2_r 
                                = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                        }
                    }
                    if ((2U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__subadr1_r 
                            = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                    }
                }
                if ((1U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                    vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__mode2_r 
                        = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
                }
            }
            if ((0U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))) {
                vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__mode1_r 
                    = vlSelfRef.i2c_tx_tb__DOT__wr_byte_data;
            }
        }
        if (((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete) 
             & (1U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)))) {
            vlSelfRef.i2c_tx_tb__DOT__dut_rw = (1U 
                                                & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q));
            vlSelfRef.i2c_tx_tb__DOT__dut_addr7 = (0x7fU 
                                                   & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q) 
                                                      >> 1U));
        }
        if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__stop_cond) {
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 0U;
        } else if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__start_cond) {
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 1U;
        } else if ((8U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
            if ((4U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
                __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 0U;
            } else if ((2U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
                if ((1U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
                    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 0U;
                } else if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__ack_end) {
                    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 0U;
                }
            } else if ((1U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
                if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete) {
                    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 0xaU;
                }
            } else if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__ack_end) {
                __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q 
                    = ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__master_nack_q)
                        ? 0U : 7U);
            }
        } else if ((4U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
            if ((2U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
                if ((1U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
                    if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete) {
                        __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 8U;
                    }
                } else if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__ack_end) {
                    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 5U;
                }
            } else if ((1U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
                if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete) {
                    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 6U;
                }
            } else if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__ack_end) {
                __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 5U;
            }
        } else if ((2U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
            if ((1U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
                if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete) {
                    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 4U;
                }
            } else if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__ack_end) {
                __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q 
                    = ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__address_ack_ok)
                        ? ((IData)(vlSelfRef.i2c_tx_tb__DOT__gc_match)
                            ? 9U : ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__rw_q)
                                     ? 7U : 3U)) : 0U);
            }
        } else if ((1U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))) {
            if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete) {
                vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__addr7_q 
                    = (0x7fU & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q) 
                                >> 1U));
                vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__rw_q 
                    = (1U & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q));
                __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 2U;
            }
        }
        vlSelfRef.i2c_tx_tb__DOT__tx_load = 0U;
        vlSelfRef.i2c_tx_tb__DOT__tx_load = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__tx_load_pending_q;
        if (vlSelfRef.i2c_tx_tb__DOT__rd_byte) {
            vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__rd_data_q 
                = vlSelfRef.i2c_tx_tb__DOT__rb_rdata;
        }
        vlSelfRef.i2c_tx_tb__DOT__ptr_set = 0U;
        if ((1U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q))) {
            vlSelfRef.i2c_tx_tb__DOT__ptr_set = 1U;
            vlSelfRef.i2c_tx_tb__DOT__ptr_set_data 
                = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_latched_q;
        }
        if (((8U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
             & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_rise))) {
            vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__master_nack_q 
                = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q;
        }
        vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__tx_load_pending_q = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rd_byte = 0U;
        if ((((7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
              & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_fall)) 
             & (0U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q)))) {
            vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__tx_load_pending_q = 1U;
            vlSelfRef.i2c_tx_tb__DOT__rd_byte = 1U;
        }
        vlSelfRef.i2c_tx_tb__DOT__wr_byte = 0U;
        if ((2U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q))) {
            vlSelfRef.i2c_tx_tb__DOT__wr_byte = 1U;
            vlSelfRef.i2c_tx_tb__DOT__wr_byte_data 
                = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_latched_q;
        }
        if (((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__start_cond) 
             | (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__stop_cond))) {
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q = 0U;
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q = 0U;
            __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q = 0U;
            vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_latched_q = 0U;
        } else {
            if (((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__capture_state) 
                 & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_rise))) {
                __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q 
                    = ((0xfeU & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q) 
                                 << 1U)) | (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q));
            }
            if ((0U != (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q))) {
                __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q = 0U;
            }
            if (vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete) {
                __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q = 0U;
                __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q 
                    = ((3U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))
                        ? 1U : ((5U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))
                                 ? 2U : 0U));
                vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_latched_q 
                    = vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q;
            } else if (((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__capture_state) 
                        & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_rise))) {
                if ((8U > (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q))) {
                    __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q 
                        = (0xfU & ((IData)(1U) + (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q)));
                }
            }
        }
    } else {
        __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q = 0U;
        __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q = 0U;
        __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q = 0U;
        __Vdly__i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q = 0U;
        __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q = 1U;
        __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q = 0U;
        __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q = 1U;
        __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q = 0U;
        __Vdly__i2c_tx_tb__DOT__dut__DOT__shift_reg_q = 0U;
        __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v17 = 1U;
        __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v17 = 1U;
        __Vdly__i2c_tx_tb__DOT__rdec__DOT__ptr_q = 0U;
        __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v34 = 1U;
        __VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v34 = 1U;
        vlSelfRef.i2c_tx_tb__DOT__dut_rw = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_polarity_r = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__allcalladr_r = 0xe0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__mode2_r = 4U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__prescale_r = 0x1eU;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__subadr1_r = 0xe2U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_enable_r = 0xffffU;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__subadr2_r = 0xe4U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__subadr3_r = 0xe8U;
        vlSelfRef.i2c_tx_tb__DOT__dut_addr7 = 0U;
        __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__addr7_q = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__rw_q = 0U;
        vlSelfRef.i2c_tx_tb__DOT__tx_load = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__rd_data_q = 0U;
        vlSelfRef.i2c_tx_tb__DOT__ptr_set = 0U;
        vlSelfRef.i2c_tx_tb__DOT__ptr_set_data = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__mode1_r = 0x11U;
        vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__master_nack_q = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__tx_load_pending_q = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rd_byte = 0U;
        vlSelfRef.i2c_tx_tb__DOT__wr_byte = 0U;
        vlSelfRef.i2c_tx_tb__DOT__wr_byte_data = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_latched_q = 0U;
    }
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_prev_q 
        = ((1U & (~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rst_n))) 
           || (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_prev_q 
        = ((1U & (~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rst_n))) 
           || (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q));
    vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q 
        = __Vdly__i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q;
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q 
        = __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q;
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q 
        = __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q;
    vlSelfRef.i2c_tx_tb__DOT__dut__DOT__shift_reg_q 
        = __Vdly__i2c_tx_tb__DOT__dut__DOT__shift_reg_q;
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v0;
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v1) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v1;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[1U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v2;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[2U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v3;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[3U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v4;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[4U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v5;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[5U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v6;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[6U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v7;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[7U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v8;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[8U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v9;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[9U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v10;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xaU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v11;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xbU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v12;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xcU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v13;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xdU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v14;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xeU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v15;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xfU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v16;
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_off__v17) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[1U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[2U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[3U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[4U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[5U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[6U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[7U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[8U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[9U] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xaU] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xbU] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xcU] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xdU] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xeU] = 1U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[0xfU] = 1U;
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v0;
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v1) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v1;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[1U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v2;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[2U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v3;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[3U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v4;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[4U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v5;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[5U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v6;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[6U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v7;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[7U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v8;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[8U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v9;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[9U] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v10;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xaU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v11;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xbU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v12;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xcU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v13;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xdU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v14;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xeU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v15;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xfU] 
            = __VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v16;
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_full_on__v17) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[1U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[2U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[3U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[4U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[5U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[6U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[7U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[8U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[9U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xaU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xbU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xcU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xdU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xeU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[0xfU] = 0U;
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0]) 
               | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v0) 
                  << 8U));
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1]) 
               | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v1));
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v2) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v2));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[1U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [1U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v3));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[2U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [2U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v4));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[3U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [3U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v5));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[4U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [4U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v6));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[5U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [5U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v7));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[6U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [6U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v8));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[7U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [7U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v9));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[8U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [8U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v10));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[9U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [9U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v11));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xaU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xaU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v12));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xbU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xbU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v13));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xcU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xcU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v14));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xdU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xdU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v15));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xeU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xeU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v16));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xfU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xfU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v17));
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v18) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v18) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[1U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [1U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v19) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[2U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [2U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v20) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[3U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [3U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v21) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[4U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [4U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v22) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[5U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [5U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v23) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[6U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [6U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v24) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[7U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [7U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v25) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[8U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [8U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v26) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[9U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [9U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v27) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xaU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xaU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v28) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xbU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xbU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v29) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xcU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xcU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v30) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xdU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xdU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v31) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xeU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xeU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v32) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xfU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                [0xfU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v33) 
                           << 8U));
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_on_count__v34) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[1U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[2U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[3U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[4U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[5U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[6U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[7U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[8U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[9U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xaU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xbU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xcU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xdU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xeU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[0xfU] = 0U;
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0]) 
               | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v0) 
                  << 8U));
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [__VdlyDim0__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1]) 
               | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v1));
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v2) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v2));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[1U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [1U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v3));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[2U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [2U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v4));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[3U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [3U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v5));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[4U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [4U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v6));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[5U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [5U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v7));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[6U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [6U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v8));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[7U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [7U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v9));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[8U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [8U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v10));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[9U] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [9U]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v11));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xaU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xaU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v12));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xbU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xbU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v13));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xcU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xcU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v14));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xdU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xdU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v15));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xeU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xeU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v16));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xfU] 
            = ((0xf00U & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xfU]) | (IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v17));
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v18) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v18) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[1U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [1U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v19) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[2U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [2U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v20) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[3U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [3U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v21) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[4U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [4U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v22) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[5U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [5U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v23) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[6U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [6U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v24) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[7U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [7U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v25) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[8U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [8U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v26) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[9U] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [9U]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v27) 
                         << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xaU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xaU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v28) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xbU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xbU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v29) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xcU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xcU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v30) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xdU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xdU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v31) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xeU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xeU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v32) 
                           << 8U));
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xfU] 
            = ((0xffU & vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                [0xfU]) | ((IData)(__VdlyVal__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v33) 
                           << 8U));
    }
    if (__VdlySet__i2c_tx_tb__DOT__rbank__DOT__shadow_off_count__v34) {
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[1U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[2U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[3U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[4U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[5U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[6U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[7U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[8U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[9U] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xaU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xbU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xcU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xdU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xeU] = 0U;
        vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[0xfU] = 0U;
    }
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q 
        = __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q;
    vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__scl_sync_prev_q 
        = (1U & ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rst_n)) 
                 | (IData)(vlSelfRef.i2c_tx_tb__DOT__bare_scl)));
    vlSelfRef.i2c_tx_tb__DOT__sda_sync = ((1U & (~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rst_n))) 
                                          || (IData)(vlSelfRef.i2c_tx_tb__DOT__bus_sync__DOT__sda_meta_q));
    vlSelfRef.i2c_tx_tb__DOT__dut__DOT__scl_sync_prev_q 
        = (1U & ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rst_n)) 
                 | (IData)(vlSelfRef.i2c_tx_tb__DOT__scl_sync)));
    vlSelfRef.i2c_tx_tb__DOT__gc_match = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__dut_rw)) 
                                          & (0U == (IData)(vlSelfRef.i2c_tx_tb__DOT__dut_addr7)));
    vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q = __Vdly__i2c_tx_tb__DOT__rdec__DOT__ptr_q;
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__address_ack_ok 
        = ((IData)(vlSelfRef.i2c_tx_tb__DOT__gc_match) 
           | (0x55U == (IData)(vlSelfRef.i2c_tx_tb__DOT__dut_addr7)));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_rise 
        = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_prev_q)) 
           & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q 
        = __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q;
    vlSelfRef.i2c_tx_tb__DOT__bus_sync__DOT__sda_meta_q 
        = ((1U & (~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rst_n))) 
           || (1U & (~ (((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__master_sda_val)) 
                         & (IData)(vlSelfRef.i2c_tx_tb__DOT__master_sda_drive)) 
                        | ((7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))
                            ? (IData)(vlSelfRef.i2c_tx_tb__DOT__tx_sda_oe)
                            : (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_sda_oe))))));
    vlSelfRef.i2c_tx_tb__DOT__scl_sync = ((1U & (~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rst_n))) 
                                          || (IData)(vlSelfRef.i2c_tx_tb__DOT__bus_sync__DOT__scl_meta_q));
    vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__is_led_addr 
        = ((6U <= (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q)) 
           & (0x45U >= (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q)));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q 
        = __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q;
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_fall 
        = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q)) 
           & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_prev_q));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q 
        = __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__state_q;
    vlSelfRef.i2c_tx_tb__DOT__rb_rdata = (0xffU & (
                                                   (0U 
                                                    == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                    ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__mode1_r)
                                                    : 
                                                   ((1U 
                                                     == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                     ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__mode2_r)
                                                     : 
                                                    ((2U 
                                                      == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                      ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__subadr1_r)
                                                      : 
                                                     ((3U 
                                                       == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                       ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__subadr2_r)
                                                       : 
                                                      ((4U 
                                                        == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                        ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__subadr3_r)
                                                        : 
                                                       ((5U 
                                                         == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                         ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__allcalladr_r)
                                                         : 
                                                        ((0xfeU 
                                                          == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                          ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__prescale_r)
                                                          : 
                                                         ((0x50U 
                                                           == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                           ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_enable_r)
                                                           : 
                                                          ((0x51U 
                                                            == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                            ? 
                                                           ((IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_enable_r) 
                                                            >> 8U)
                                                            : 
                                                           ((0x52U 
                                                             == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                             ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_polarity_r)
                                                             : 
                                                            ((0x53U 
                                                              == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                              ? 
                                                             ((IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__chan_polarity_r) 
                                                              >> 8U)
                                                              : 
                                                             ((0x54U 
                                                               == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                               ? 0U
                                                               : 
                                                              ((0x55U 
                                                                == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                                ? 0x53U
                                                                : 
                                                               ((0x56U 
                                                                 == (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                                 ? 1U
                                                                 : 
                                                                ((IData)(vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__is_led_addr)
                                                                  ? 
                                                                 ((2U 
                                                                   & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                      - (IData)(2U)))
                                                                   ? 
                                                                  ((1U 
                                                                    & (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                                    ? 
                                                                   ((vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_off
                                                                     [
                                                                     (0xfU 
                                                                      & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                          - (IData)(6U)) 
                                                                         >> 2U))] 
                                                                     << 4U) 
                                                                    | (0xfU 
                                                                       & (vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                                                                          [
                                                                          (0xfU 
                                                                           & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                               - (IData)(6U)) 
                                                                              >> 2U))] 
                                                                          >> 8U)))
                                                                    : 
                                                                   vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_off_count
                                                                   [
                                                                   (0xfU 
                                                                    & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                        - (IData)(6U)) 
                                                                       >> 2U))])
                                                                   : 
                                                                  ((1U 
                                                                    & (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q))
                                                                    ? 
                                                                   ((vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_full_on
                                                                     [
                                                                     (0xfU 
                                                                      & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                          - (IData)(6U)) 
                                                                         >> 2U))] 
                                                                     << 4U) 
                                                                    | (0xfU 
                                                                       & (vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                                                                          [
                                                                          (0xfU 
                                                                           & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                               - (IData)(6U)) 
                                                                              >> 2U))] 
                                                                          >> 8U)))
                                                                    : 
                                                                   vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__shadow_on_count
                                                                   [
                                                                   (0xfU 
                                                                    & (((IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q) 
                                                                        - (IData)(6U)) 
                                                                       >> 2U))]))
                                                                  : 0U))))))))))))))));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q 
        = __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q;
    vlSelfRef.i2c_tx_tb__DOT__bus_sync__DOT__scl_meta_q 
        = ((1U & (~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rst_n))) 
           || (IData)(vlSelfRef.i2c_tx_tb__DOT__master_scl));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__ack_end 
        = (((2U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
            | ((4U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
               | ((6U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                  | ((8U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                     | (0xaU == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)))))) 
           & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_fall));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__capture_state 
        = ((1U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
           | ((3U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
              | ((5U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                 | ((7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                    | (9U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))))));
    vlSelfRef.i2c_tx_tb__DOT__tx_sda_oe = ((~ ((IData)(vlSelfRef.i2c_tx_tb__DOT__dut__DOT__shift_reg_q) 
                                               >> 7U)) 
                                           & (7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__start_cond 
        = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q)) 
           & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q) 
              & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_prev_q)));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__stop_cond 
        = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_prev_q)) 
           & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q) 
              & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q)));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q 
        = __Vdly__i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q;
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete 
        = ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__capture_state) 
           & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_fall) 
              & (8U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q))));
    vlSelfRef.i2c_tx_tb__DOT__rx_sda_oe = ((2U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))
                                            ? (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__address_ack_ok)
                                            : ((4U 
                                                == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                                               | ((6U 
                                                   == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                                                  | ((0xaU 
                                                      == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                                                     & (6U 
                                                        == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_latched_q))))));
}

void Vi2c_tx_tb___024root___timing_resume(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___timing_resume\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        vlSelfRef.__VtrigSched_h2c9fe19e__0.resume(
                                                   "@(posedge i2c_tx_tb.clk_ref)");
    }
    if ((4ULL & vlSelfRef.__VactTriggered.word(0U))) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vi2c_tx_tb___024root___timing_commit(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___timing_commit\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((! (1ULL & vlSelfRef.__VactTriggered.word(0U)))) {
        vlSelfRef.__VtrigSched_h2c9fe19e__0.commit(
                                                   "@(posedge i2c_tx_tb.clk_ref)");
    }
}

void Vi2c_tx_tb___024root___eval_triggers__act(Vi2c_tx_tb___024root* vlSelf);

bool Vi2c_tx_tb___024root___eval_phase__act(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_phase__act\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<3> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vi2c_tx_tb___024root___eval_triggers__act(vlSelf);
    Vi2c_tx_tb___024root___timing_commit(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vi2c_tx_tb___024root___timing_resume(vlSelf);
        Vi2c_tx_tb___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vi2c_tx_tb___024root___eval_phase__nba(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_phase__nba\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vi2c_tx_tb___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vi2c_tx_tb___024root___dump_triggers__nba(Vi2c_tx_tb___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vi2c_tx_tb___024root___dump_triggers__act(Vi2c_tx_tb___024root* vlSelf);
#endif  // VL_DEBUG

void Vi2c_tx_tb___024root___eval(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vi2c_tx_tb___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("tb/unit/i2c/i2c_tx_tb.sv", 60, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelfRef.__VactIterCount))) {
#ifdef VL_DEBUG
                Vi2c_tx_tb___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("tb/unit/i2c/i2c_tx_tb.sv", 60, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vi2c_tx_tb___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vi2c_tx_tb___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vi2c_tx_tb___024root___eval_debug_assertions(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_debug_assertions\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
