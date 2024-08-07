iverilog : gettrace.sim/sim_1/behav/iverilog/gettrace
	cd gettrace.sim/sim_1/behav/iverilog && vvp ./gettrace

gettrace.sim/sim_1/behav/iverilog/gettrace:
	mkdir -p gettrace.sim/sim_1/behav/iverilog && iverilog -Wall -o ./gettrace.sim/sim_1/behav/iverilog/gettrace ./src/*.v ./src/*/*.v 

clean : 
	rm -rf gettrace.sim
	rm golden_trace.txt
