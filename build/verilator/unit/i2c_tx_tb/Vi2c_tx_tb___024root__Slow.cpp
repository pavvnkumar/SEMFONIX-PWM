// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vi2c_tx_tb.h for the primary calling header

#include "Vi2c_tx_tb__pch.h"
#include "Vi2c_tx_tb__Syms.h"
#include "Vi2c_tx_tb___024root.h"

void Vi2c_tx_tb___024root___ctor_var_reset(Vi2c_tx_tb___024root* vlSelf);

Vi2c_tx_tb___024root::Vi2c_tx_tb___024root(Vi2c_tx_tb__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vi2c_tx_tb___024root___ctor_var_reset(this);
}

void Vi2c_tx_tb___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vi2c_tx_tb___024root::~Vi2c_tx_tb___024root() {
}
