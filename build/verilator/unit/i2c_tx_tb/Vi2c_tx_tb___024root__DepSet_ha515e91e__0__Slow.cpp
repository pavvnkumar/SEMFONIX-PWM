// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vi2c_tx_tb.h for the primary calling header

#include "Vi2c_tx_tb__pch.h"
#include "Vi2c_tx_tb___024root.h"

VL_ATTR_COLD void Vi2c_tx_tb___024root___eval_static__TOP(Vi2c_tx_tb___024root* vlSelf);

VL_ATTR_COLD void Vi2c_tx_tb___024root___eval_static(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_static\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vi2c_tx_tb___024root___eval_static__TOP(vlSelf);
}

VL_ATTR_COLD void Vi2c_tx_tb___024root___eval_static__TOP(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_static__TOP\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.i2c_tx_tb__DOT__errors = 0U;
    vlSelfRef.i2c_tx_tb__DOT__checks = 0U;
}

VL_ATTR_COLD void Vi2c_tx_tb___024root___eval_initial__TOP(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_initial__TOP\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.i2c_tx_tb__DOT__clk_ref = 0U;
}

VL_ATTR_COLD void Vi2c_tx_tb___024root___eval_final(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_final\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vi2c_tx_tb___024root___dump_triggers__stl(Vi2c_tx_tb___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vi2c_tx_tb___024root___eval_phase__stl(Vi2c_tx_tb___024root* vlSelf);

VL_ATTR_COLD void Vi2c_tx_tb___024root___eval_settle(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_settle\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vi2c_tx_tb___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("tb/unit/i2c/i2c_tx_tb.sv", 60, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vi2c_tx_tb___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vi2c_tx_tb___024root___dump_triggers__stl(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___dump_triggers__stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vi2c_tx_tb___024root___stl_sequent__TOP__0(Vi2c_tx_tb___024root* vlSelf);

VL_ATTR_COLD void Vi2c_tx_tb___024root___eval_stl(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vi2c_tx_tb___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vi2c_tx_tb___024root___stl_sequent__TOP__0(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___stl_sequent__TOP__0\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.i2c_tx_tb__DOT__bare_sda_oe = ((~ ((IData)(vlSelfRef.i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q) 
                                                 >> 7U)) 
                                             & (IData)(vlSelfRef.i2c_tx_tb__DOT__bare_tx_drive_en));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_rise 
        = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_prev_q)) 
           & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__start_cond 
        = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q)) 
           & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q) 
              & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_prev_q)));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__stop_cond 
        = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_prev_q)) 
           & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q) 
              & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q)));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__capture_state 
        = ((1U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
           | ((3U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
              | ((5U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                 | ((7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                    | (9U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))))));
    vlSelfRef.i2c_tx_tb__DOT__tx_sda_oe = ((~ ((IData)(vlSelfRef.i2c_tx_tb__DOT__dut__DOT__shift_reg_q) 
                                               >> 7U)) 
                                           & (7U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_fall 
        = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q)) 
           & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_prev_q));
    vlSelfRef.i2c_tx_tb__DOT__gc_match = ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__dut_rw)) 
                                          & (0U == (IData)(vlSelfRef.i2c_tx_tb__DOT__dut_addr7)));
    vlSelfRef.i2c_tx_tb__DOT__rbank__DOT__is_led_addr 
        = ((6U <= (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q)) 
           & (0x45U >= (IData)(vlSelfRef.i2c_tx_tb__DOT__rdec__DOT__ptr_q)));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__ack_end 
        = (((2U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
            | ((4U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
               | ((6U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                  | ((8U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)) 
                     | (0xaU == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q)))))) 
           & (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_fall));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__byte_complete 
        = ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__capture_state) 
           & ((IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__scl_fall) 
              & (8U == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q))));
    vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__address_ack_ok 
        = ((IData)(vlSelfRef.i2c_tx_tb__DOT__gc_match) 
           | (0x55U == (IData)(vlSelfRef.i2c_tx_tb__DOT__dut_addr7)));
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
    vlSelfRef.i2c_tx_tb__DOT__sda_line = (1U & (~ (
                                                   ((~ (IData)(vlSelfRef.i2c_tx_tb__DOT__master_sda_val)) 
                                                    & (IData)(vlSelfRef.i2c_tx_tb__DOT__master_sda_drive)) 
                                                   | ((7U 
                                                       == (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_dut__DOT__state_q))
                                                       ? (IData)(vlSelfRef.i2c_tx_tb__DOT__tx_sda_oe)
                                                       : (IData)(vlSelfRef.i2c_tx_tb__DOT__rx_sda_oe)))));
}

VL_ATTR_COLD void Vi2c_tx_tb___024root___eval_triggers__stl(Vi2c_tx_tb___024root* vlSelf);

VL_ATTR_COLD bool Vi2c_tx_tb___024root___eval_phase__stl(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___eval_phase__stl\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vi2c_tx_tb___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vi2c_tx_tb___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vi2c_tx_tb___024root___dump_triggers__act(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___dump_triggers__act\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge i2c_tx_tb.clk_ref)\n");
    }
    if ((2ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @(negedge i2c_tx_tb.rst_n)\n");
    }
    if ((4ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vi2c_tx_tb___024root___dump_triggers__nba(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___dump_triggers__nba\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge i2c_tx_tb.clk_ref)\n");
    }
    if ((2ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @(negedge i2c_tx_tb.rst_n)\n");
    }
    if ((4ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vi2c_tx_tb___024root___ctor_var_reset(Vi2c_tx_tb___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vi2c_tx_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vi2c_tx_tb___024root___ctor_var_reset\n"); );
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->i2c_tx_tb__DOT__errors = 0;
    vlSelf->i2c_tx_tb__DOT__checks = 0;
    vlSelf->i2c_tx_tb__DOT__clk_ref = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rst_n = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__bare_scl = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__bare_tx_load = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__bare_tx_drive_en = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__bare_tx_data = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__bare_sda_oe = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__master_scl = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__master_sda_drive = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__master_sda_val = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_sda_oe = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__tx_sda_oe = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__sda_line = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__scl_sync = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__sda_sync = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__dut_addr7 = VL_RAND_RESET_I(7);
    vlSelf->i2c_tx_tb__DOT__dut_rw = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__gc_match = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__ptr_set = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__wr_byte = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rd_byte = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__ptr_set_data = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__wr_byte_data = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__tx_load = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rb_rdata = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__unnamedblk4__DOT__unnamedblk5__DOT__unnamedblk6__DOT__rand_byte = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__dut_bare__DOT__scl_sync_prev_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__dut_bare__DOT__shift_reg_q = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__bus_sync__DOT__scl_meta_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__bus_sync__DOT__sda_meta_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__scl_filt_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__sda_filt_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__scl_stable_cnt_q = VL_RAND_RESET_I(32);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__sda_stable_cnt_q = VL_RAND_RESET_I(32);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__scl_prev_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__sda_prev_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__scl_rise = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__scl_fall = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__start_cond = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__stop_cond = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__state_q = VL_RAND_RESET_I(4);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__shift_reg_q = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__bit_cnt_q = VL_RAND_RESET_I(4);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__addr7_q = VL_RAND_RESET_I(7);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__rw_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__master_nack_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__byte_latched_q = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__byte_event_pending_q = VL_RAND_RESET_I(2);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__tx_load_pending_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__capture_state = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__byte_complete = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__ack_end = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rx_dut__DOT__address_ack_ok = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__rdec__DOT__ptr_q = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rdec__DOT__rd_data_q = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__mode1_r = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__mode2_r = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__subadr1_r = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__subadr2_r = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__subadr3_r = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__allcalladr_r = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__prescale_r = VL_RAND_RESET_I(8);
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__chan_enable_r = VL_RAND_RESET_I(16);
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__chan_polarity_r = VL_RAND_RESET_I(16);
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        vlSelf->i2c_tx_tb__DOT__rbank__DOT__shadow_on_count[__Vi0] = VL_RAND_RESET_I(12);
    }
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        vlSelf->i2c_tx_tb__DOT__rbank__DOT__shadow_off_count[__Vi0] = VL_RAND_RESET_I(12);
    }
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        vlSelf->i2c_tx_tb__DOT__rbank__DOT__shadow_full_on[__Vi0] = VL_RAND_RESET_I(1);
    }
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        vlSelf->i2c_tx_tb__DOT__rbank__DOT__shadow_full_off[__Vi0] = VL_RAND_RESET_I(1);
    }
    vlSelf->i2c_tx_tb__DOT__rbank__DOT__is_led_addr = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__dut__DOT__scl_sync_prev_q = VL_RAND_RESET_I(1);
    vlSelf->i2c_tx_tb__DOT__dut__DOT__shift_reg_q = VL_RAND_RESET_I(8);
    vlSelf->__Vtask_i2c_tx_tb__DOT__m_send_byte__51__data = VL_RAND_RESET_I(8);
    vlSelf->__Vtask_i2c_tx_tb__DOT__m_read_byte__86__data = VL_RAND_RESET_I(8);
    vlSelf->__Vtask_i2c_tx_tb__DOT__m_read_byte__86__master_nack = 0;
    vlSelf->__Vtask_i2c_tx_tb__DOT__m_send_byte__106__data = VL_RAND_RESET_I(8);
    vlSelf->__Vtask_i2c_tx_tb__DOT__m_send_byte__123__data = VL_RAND_RESET_I(8);
    vlSelf->__Vtrigprevexpr___TOP__i2c_tx_tb__DOT__clk_ref__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__i2c_tx_tb__DOT__rst_n__0 = VL_RAND_RESET_I(1);
}
