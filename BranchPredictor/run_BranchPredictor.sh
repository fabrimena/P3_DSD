#!/usr/bin/env bash
# run_BranchPredictor.sh
# Compila y simula tb_branch_predictor.sv con Icarus Verilog.
# Uso: ./run_BranchPredictor.sh [--wave]   (--wave abre GTKWave)

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

SRC="${DIR}/branch_predictor.sv"
TB="${DIR}/tb_branch_predictor.sv"
OUT="${DIR}/tb_bp_sim"
VCD="${DIR}/tb_branch_predictor.vcd"

echo "=== Compilando ==="
iverilog -g2012 -o "${OUT}" "${SRC}" "${TB}"

echo "=== Simulando ==="
vvp "${OUT}"

if [[ "${1:-}" == "--wave" ]]; then
    echo "=== Abriendo GTKWave ==="
    gtkwave "${VCD}" &
fi