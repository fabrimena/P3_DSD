#!/bin/bash
TB=tb_pipeline_regs
FILES="pipeline_regs.sv tb_pipeline_regs.sv"
echo "Compilando $TB -> $FILES"
iverilog -g2012 -s $TB -o /tmp/tb_out $FILES 2> /tmp/warn.log
if [ $? -ne 0 ]; then
    echo "Fallo la compilacion:"; cat /tmp/warn.log; exit 1
fi
vvp /tmp/tb_out
