// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vi2c_tx_tb__pch.h"
#include "Vi2c_tx_tb.h"
#include "Vi2c_tx_tb___024root.h"

// FUNCTIONS
Vi2c_tx_tb__Syms::~Vi2c_tx_tb__Syms()
{
}

Vi2c_tx_tb__Syms::Vi2c_tx_tb__Syms(VerilatedContext* contextp, const char* namep, Vi2c_tx_tb* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(304);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    // Setup scopes
    __Vscope_i2c_tx_tb.configure(this, name(), "i2c_tx_tb", "i2c_tx_tb", "<null>", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_i2c_tx_tb__unnamedblk4.configure(this, name(), "i2c_tx_tb.unnamedblk4", "unnamedblk4", "<null>", -9, VerilatedScope::SCOPE_OTHER);
}
