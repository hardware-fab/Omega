// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "dfdiv_vivado.h"

typedef int64_t token_t;

/* <<--params-def-->> */
#define DFDIV_N 100
#define DFDIV_IN 2
#define DFDIV_OUT 1

/* <<--params-->> */
const int32_t dfdiv_n = DFDIV_N;
const int32_t dfdiv_in = DFDIV_IN;
const int32_t dfdiv_out = DFDIV_OUT;

#define NACC 1

struct dfdiv_vivado_access dfdiv_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.dfdiv_n = DFDIV_N,
		.dfdiv_in = DFDIV_IN,
		.dfdiv_out = DFDIV_OUT,
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
		.devname = "dfdiv_vivado.0",
		.ioctl_req = DFDIV_VIVADO_IOC_ACCESS,
		.esp_desc = &(dfdiv_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
