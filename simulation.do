setenv LMC_TIMEUNIT -9
vlib work
vmap work work
vcom -work work "radio_utils.vhd"
vcom -work work "divider.vhd"
vcom -work work "fifo.vhd"
vcom -work work "fifo_2out.vhd"
vcom -work work "fifo_3out.vhd"
vcom -work work "add.vhd"
vcom -work work "sub_op.vhd"
vcom -work work "square.vhd"
vcom -work work "multiply.vhd"
vcom -work work "demodulate.vhd"
vcom -work work "fir.vhd"
vcom -work work "fir_cmplx.vhd"
vcom -work work "gain.vhd"
vcom -work work "iir.vhd"
vcom -work work "readIQ.vhd"
vcom -work work "radio_top.vhd"
vcom -work work "radio_tb.vhd"
vsim +notimingchecks -L work work.radio_tb -wlf radio_sim.wlf

add wave -noupdate -group radio_tb
add wave -noupdate -group radio_tb -radix hexadecimal /radio_tb/*
add wave -noupdate -group radio_tb/radio_top_inst
add wave -noupdate -group radio_tb/radio_top_inst -radix hexadecimal /radio_tb/radio_top_inst/*
run -all
