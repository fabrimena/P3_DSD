#!/bin/bash
TB=tb_hazard_unit
FILES="hazard_unit.sv tb_hazard_unit.sv"
echo "Compilando $TB -> $FILES"
iverilog -g2012 -s $TB -o /tmp/tb_out $FILES 2> /tmp/warn.log
if [ $? -ne 0 ]; then
    echo "Fallo la compilacion:"; cat /tmp/warn.log; exit 1
fi
vvp /tmp/tb_out
