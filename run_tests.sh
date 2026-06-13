#!/bin/bash
PASS=0
FAIL=0
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

run_tb() {
    local folder=$1
    local tb_module=$2
    local files=$3
    echo "----------------------------------------"
    echo "Corriendo: $folder"
    
    # Check syntax directly and hide warnings
    iverilog -g2012 -s $tb_module -o /tmp/tb_out $files 2> /tmp/warn.log
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Falló la compilación de $folder${NC}"
        cat /tmp/warn.log
        FAIL=$((FAIL + 1))
        return
    fi
    
    result=$(vvp /tmp/tb_out 2>&1)
    
    # Direct testbench success indicator
    local error_count=$(echo "$result" | grep -oP "(Total de )?[Ee]rrores:\s*\K[0-9]+" | head -n 1)
    
    if [ "$error_count" == "" ]; then
        local pure_errors=$(echo "$result" | grep "ERROR" | grep -v -i -E "(0 ERROR|Negativo|CRITICO|Total de ERRORES)")
        if [ -n "$pure_errors" ]; then
             echo "$result"
             echo -e "${RED}RESULTADO: FALLÓ en $folder (Errores encontrados)${NC}"
             FAIL=$((FAIL + 1))
        else
             echo -e "${GREEN}RESULTADO: TODOS LOS TESTS PASARON en $folder${NC}"
             PASS=$((PASS + 1))
        fi
    else
        if [ "$error_count" -gt 0 ]; then
             echo "$result"
             echo -e "${RED}RESULTADO: FALLÓ en $folder ($error_count errores reportados)${NC}"
             FAIL=$((FAIL + 1))
        else
             echo -e "${GREEN}RESULTADO: TODOS LOS TESTS PASARON en $folder${NC}"
             PASS=$((PASS + 1))
        fi
    fi
}

ROOT=$(dirname "$0")
SRC="$ROOT/Memory/single_port_ram.sv $ROOT/InstructionMemory.sv $ROOT/ALU/or_gate.sv $ROOT/ALU/adder.sv $ROOT/ALU/logic_shift_left.sv $ROOT/ALU/fulladder.sv $ROOT/ALU/add_sub.sv $ROOT/ALU/aritmethic_shift_right.sv $ROOT/ALU/mux2to1_Nbits.sv $ROOT/ALU/and_gate.sv $ROOT/ALU/logic_shift_right.sv $ROOT/ALU/not_gate.sv $ROOT/ALU/set_lt.sv $ROOT/ALU/ALU.sv $ROOT/ALU/mux8to1.sv $ROOT/ALU/xor_gate.sv $ROOT/ALU/mux2to1.sv $ROOT/ALU/mux4to1.sv $ROOT/PC/pc.sv $ROOT/ControlUnit/alu_decoder.sv $ROOT/ControlUnit/control_unit.sv $ROOT/ControlUnit/main_decoder.sv $ROOT/RegisterFile/reg_file.sv $ROOT/BitSelector/BitSelector.sv $ROOT/Extend/extend.sv $ROOT/PC/pc_increment.sv $ROOT/Flops/pipeline_regs.sv $ROOT/HazardUnit/hazard_unit.sv $ROOT/BranchPredictor/branch_predictor.sv $ROOT/top.sv"

run_tb "ALU"          "tb_ALU"              "$ROOT/ALU/*.sv"
run_tb "BitSelector"  "tb_BitSelector"      "$ROOT/BitSelector/*.sv"
run_tb "Memory"       "tb_single_port_ram"  "$ROOT/Memory/*.sv"
run_tb "PC"           "pc_increment_tb"     "$ROOT/PC/*.sv $ROOT/ALU/mux2to1_Nbits.sv $ROOT/ALU/fulladder.sv $ROOT/ALU/adder.sv $ROOT/ALU/mux2to1.sv"
run_tb "RegisterFile" "tb_reg_file"         "$ROOT/RegisterFile/*.sv"
run_tb "Extend"       "tb_extend"           "$ROOT/Extend/*.sv"
run_tb "ControlUnit"  "tb_control_unit" "$ROOT/ControlUnit/main_decoder.sv $ROOT/ControlUnit/alu_decoder.sv $ROOT/ControlUnit/control_unit.sv $ROOT/ControlUnit/tb_control_unit.sv"
run_tb "Top_Pipeline" "tb_top"              "$ROOT/tb_top.sv $SRC"
run_tb "Prog1_Math"    "tb_prog1" "$ROOT/Programs/tb_prog1.sv $SRC" "$ROOT/Programs"
run_tb "Prog2_Collatz" "tb_prog2" "$ROOT/Programs/tb_prog2.sv $SRC" "$ROOT/Programs"
run_tb "HazardUnit"     "tb_hazard_unit"     "$ROOT/HazardUnit/*.sv"
run_tb "Pipeline_Regs"   "tb_pipeline_regs"   "$ROOT/Flops/*.sv $ROOT/ALU/mux2to1_Nbits.sv $ROOT/ALU/fulladder.sv $ROOT/ALU/adder.sv $ROOT/ALU/mux2to1.sv"
run_tb "BranchPredictor"   "tb_branch_predictor" "$ROOT/BranchPredictor/*.sv"
echo -e "  Módulos OK:   ${GREEN}$PASS${NC}"
echo -e "  Módulos FAIL: ${RED}$FAIL${NC}"
