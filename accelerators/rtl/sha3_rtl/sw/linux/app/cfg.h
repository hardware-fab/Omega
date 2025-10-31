// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "sha3_rtl.h"

typedef int64_t token_t;

/* <<--params-def-->> */
#define SHA3_MESSAGE_LEN 128
#define SHA3_N 12
#define SHA3_HASH_LEN 4

/* <<--params-->> */
const int32_t sha3_message_len = SHA3_MESSAGE_LEN;
const int32_t sha3_n = SHA3_N;
const int32_t sha3_hash_len = SHA3_HASH_LEN;

#define NACC 1

struct sha3_rtl_access sha3_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.sha3_message_len = SHA3_MESSAGE_LEN,
		.sha3_n = SHA3_N,
		.sha3_hash_len = SHA3_HASH_LEN,
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
		.devname = "sha3_rtl.0",
		.ioctl_req = SHA3_RTL_IOC_ACCESS,
		.esp_desc = &(sha3_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
