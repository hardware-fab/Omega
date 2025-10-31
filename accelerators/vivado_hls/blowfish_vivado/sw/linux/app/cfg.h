// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "blowfish_vivado.h"

typedef int8_t token_t;

/* <<--params-def-->> */
#define BLOWFISH_N 40
#define BLOWFISH_N 10
#define BLOWFISH_SIZE 5200

/* <<--params-->> */
const int32_t blowfish_N = BLOWFISH_N;
const int32_t blowfish_n = BLOWFISH_N;
const int32_t blowfish_size = BLOWFISH_SIZE;

#define NACC 1

struct blowfish_vivado_access blowfish_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.blowfish_N = BLOWFISH_N,
		.blowfish_n = BLOWFISH_N,
		.blowfish_size = BLOWFISH_SIZE,
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
		.devname = "blowfish_vivado.0",
		.ioctl_req = BLOWFISH_VIVADO_IOC_ACCESS,
		.esp_desc = &(blowfish_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
