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
TB=tb_single_port_ram
FILES="$ROOT/Memory/*.sv"
echo "Compilando $TB -> $FILES"
iverilog -g2012 -s $TB -o /tmp/tb_out $FILES 2> /tmp/warn.log
if [ $? -ne 0 ]; then
    echo "Fallo la compilacion:"; cat /tmp/warn.log; exit 1
fi
vvp /tmp/tb_out
