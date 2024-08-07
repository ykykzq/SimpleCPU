.PHONY: clean
IVERILOG_DIR = project/loongson.sim/sim_1/behav/iverilog
iverilog : $(IVERILOG_DIR)/gettrace
	cd $(IVERILOG_DIR) && vvp ./gettrace

$(IVERILOG_DIR)/gettrace:
	mkdir -p $(IVERILOG_DIR) && iverilog -Wall -o $(IVERILOG_DIR)/gettrace ../../../myCPU/*.v ../rtl/*.v ../rtl/*/*.v  sync_ram.v mycpu_tb.v  -I ../../../myCPU/

clean : 
	rm -rf ./project 
