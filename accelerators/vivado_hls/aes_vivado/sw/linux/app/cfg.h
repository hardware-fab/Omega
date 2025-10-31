// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "aes_vivado.h"

typedef int32_t token_t;

/* <<--params-def-->> */
#define AES_KEY 32
#define AES_N 100
#define AES_TEXT 32

/* <<--params-->> */
const int32_t aes_key = AES_KEY;
const int32_t aes_n = AES_N;
const int32_t aes_text = AES_TEXT;

#define NACC 1

struct aes_vivado_access aes_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.aes_key = AES_KEY,
		.aes_n = AES_N,
		.aes_text = AES_TEXT,
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
		.devname = "aes_vivado.0",
		.ioctl_req = AES_VIVADO_IOC_ACCESS,
		.esp_desc = &(aes_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
