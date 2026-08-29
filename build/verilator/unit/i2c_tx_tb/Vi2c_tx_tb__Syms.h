// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VI2C_TX_TB__SYMS_H_
#define VERILATED_VI2C_TX_TB__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vi2c_tx_tb.h"

// INCLUDE MODULE CLASSES
#include "Vi2c_tx_tb___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vi2c_tx_tb__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vi2c_tx_tb* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vi2c_tx_tb___024root           TOP;

    // SCOPE NAMES
    VerilatedScope __Vscope_i2c_tx_tb;
    VerilatedScope __Vscope_i2c_tx_tb__unnamedblk4;

    // CONSTRUCTORS
    Vi2c_tx_tb__Syms(VerilatedContext* contextp, const char* namep, Vi2c_tx_tb* modelp);
    ~Vi2c_tx_tb__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
