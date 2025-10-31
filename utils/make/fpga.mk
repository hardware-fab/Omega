#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    fpga.mk
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#
# This file was originally part of the ESP project source code, available at:
# https://github.com/sld-columbia/esp
#----------------------------------------------------------------------------

# Copyright (c) 2011-2023 Columbia University, System Level Design Group
# SPDX-License-Identifier: Apache-2.0

ifneq ($(findstring profpga, $(BOARD)),)
fpga-program: profpga-prog-fpga
	$(QUIET_INFO) echo "Waiting for DDR calibration..."
	@sleep 5

fpga-program-emu: profpga-prog-fpga-emu
	$(QUIET_INFO) echo "Waiting for DDR calibration..."
	@sleep 5
else
fpga-program: vivado-prog-fpga
	$(QUIET_INFO) echo "Waiting for DDR calibration..."
	@sleep 5

fpga-program-partial:
	BIT=$(subst ./vivado,$(DESIGN_PATH)/vivado,$(BITSTREAM)); \
	$(MAKE) -C . vivado-prog-fpga-partial BIT=$$BIT
	$(QUIET_INFO) echo "Waiting for DDR calibration..."
	@sleep 5
endif


fpga-run: esplink soft
	@./$(ESP_CFG_BUILD)/esplink --soft-reset
	@./$(ESP_CFG_BUILD)/esplink --soft-reset
	@./$(ESP_CFG_BUILD)/esplink --brom -i $(SOFT_BUILD)/prom.bin
	@./$(ESP_CFG_BUILD)/esplink --dram -i $(SOFT_BUILD)/systest.bin
	@./$(ESP_CFG_BUILD)/esplink --soft-reset
	@./$(ESP_CFG_BUILD)/esplink --soft-reset

fpga-run-linux: esplink soft
	@./$(ESP_CFG_BUILD)/esplink --soft-reset
	@./$(ESP_CFG_BUILD)/esplink --brom -i $(SOFT_BUILD)/prom.bin
	@./$(ESP_CFG_BUILD)/esplink --dram -i $(SOFT_BUILD)/linux.bin
	@./$(ESP_CFG_BUILD)/esplink --soft-reset

fpga-run-proxy: esplink esplink-fpga-proxy soft
	@./$(ESP_CFG_BUILD)/esplink --soft-reset
	@./$(ESP_CFG_BUILD)/esplink --brom -i $(SOFT_BUILD)/prom.bin
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --dram -i $(SOFT_BUILD)/systest.bin
	@./$(ESP_CFG_BUILD)/esplink --soft-reset

fpga-run-iolink: esplink esplink-fpga-proxy soft
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --soft-reset
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --brom -i $(SOFT_BUILD)/prom.bin
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --dram -i $(SOFT_BUILD)/systest.bin
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --soft-reset

fpga-run-linux-proxy: esplink esplink-fpga-proxy soft
	@./$(ESP_CFG_BUILD)/esplink --soft-reset
	@./$(ESP_CFG_BUILD)/esplink --brom -i $(SOFT_BUILD)/prom.bin
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --dram -i $(SOFT_BUILD)/linux.bin
	@./$(ESP_CFG_BUILD)/esplink --soft-reset

fpga-run-linux-iolink: esplink esplink-fpga-proxy soft
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --soft-reset
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --brom -i $(SOFT_BUILD)/prom.bin
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --dram -i $(SOFT_BUILD)/linux.bin
	@./$(ESP_CFG_BUILD)/esplink-fpga-proxy --soft-reset

fpga-run-jtag: esplink-fpga-proxy
	@python $(ESP_ROOT)/utils/scripts/jtag_test/jtag_esplink.py $(STIM_FILE)

fpga-reset-start: esplink soft
	@./$(ESP_CFG_BUILD)/esplink --start-reset

fpga-reset-release: esplink soft
	@./$(ESP_CFG_BUILD)/esplink --release-reset
	@./$(ESP_CFG_BUILD)/esplink --soft-reset
	@./$(ESP_CFG_BUILD)/esplink --soft-reset

fpga-reset: esplink soft
	@./$(ESP_CFG_BUILD)/esplink --hard-reset
	@./$(ESP_CFG_BUILD)/esplink --soft-reset
	@./$(ESP_CFG_BUILD)/esplink --soft-reset

.PHONY: fpga-run fpga-run-linux fpga-program fpga-run-proxy fpga-run-linux-proxy
