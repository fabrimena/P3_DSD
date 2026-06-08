#!/bin/bash
get_repo_root() {
    DIR=$(cd "$(dirname "$0")" && pwd)
    while [ "$DIR" != "/" ]; do
        if [ -f "$DIR/top.sv" ] || [ -f "$DIR/InstructionMemory.sv" ] || [ -f "$DIR/run_tests.sh" ]; then
            echo "$DIR"
            return
        fi
        DIR=$(dirname "$DIR")
    done
    echo "$(cd "$(dirname "$0")" && pwd)"
}
ROOT=$(get_repo_root)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TB=tb_prog2
SRC="$ROOT/Memory/single_port_ram.sv $ROOT/InstructionMemory.sv $ROOT/ALU/or_gate.sv $ROOT/ALU/adder.sv $ROOT/ALU/logic_shift_left.sv $ROOT/ALU/fulladder.sv $ROOT/ALU/add_sub.sv $ROOT/ALU/aritmethic_shift_right.sv $ROOT/ALU/mux2to1_Nbits.sv $ROOT/ALU/and_gate.sv $ROOT/ALU/logic_shift_right.sv $ROOT/ALU/not_gate.sv $ROOT/ALU/set_lt.sv $ROOT/ALU/ALU.sv $ROOT/ALU/mux8to1.sv $ROOT/ALU/xor_gate.sv $ROOT/ALU/mux2to1.sv $ROOT/ALU/mux4to1.sv $ROOT/PC/pc.sv $ROOT/ControlUnit/alu_decoder.sv $ROOT/ControlUnit/control_unit.sv $ROOT/ControlUnit/main_decoder.sv $ROOT/RegisterFile/reg_file.sv $ROOT/BitSelector/BitSelector.sv $ROOT/Extend/extend.sv $ROOT/PC/pc_increment.sv $ROOT/Flops/pipeline_regs.sv $ROOT/HazardUnit/hazard_unit.sv $ROOT/top.sv"
FILES="$SCRIPT_DIR/tb_prog2.sv $SRC"
echo "Compilando $TB -> $FILES"
iverilog -g2012 -s $TB -o /tmp/tb_out $FILES 2> /tmp/warn.log
if [ $? -ne 0 ]; then
    echo "Fallo la compilacion:"; cat /tmp/warn.log; exit 1
fi
cd "$SCRIPT_DIR" || exit 1
vvp /tmp/tb_out
