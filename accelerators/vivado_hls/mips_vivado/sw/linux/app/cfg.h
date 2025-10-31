// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "mips_vivado.h"

typedef int32_t token_t;

/* <<--params-def-->> */
#define MIPS_IN 8
#define MIPS_N 100
#define MIPS_OUT 8

/* <<--params-->> */
const int32_t mips_in = MIPS_IN;
const int32_t mips_n = MIPS_N;
const int32_t mips_out = MIPS_OUT;

#define NACC 1

struct mips_vivado_access mips_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.mips_in = MIPS_IN,
		.mips_n = MIPS_N,
		.mips_out = MIPS_OUT,
		.src_offset = 0,
		.dst_offset = 0,
		.esp.coherence = ACC_COH_NONE,
		.esp.p2p_store = 0,
		.esp.p2p_nsrcs = 0,
		.esp.p2p_srcs = {"", "", "", ""},
	}
};

esp_thread_info_t cfg_000[] = {
	{
		.run = true,
		.devname = "mips_vivado.0",
		.ioctl_req = MIPS_VIVADO_IOC_ACCESS,
		.esp_desc = &(mips_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
