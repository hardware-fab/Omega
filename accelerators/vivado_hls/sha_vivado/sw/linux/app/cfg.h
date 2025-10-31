// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "sha_vivado.h"

typedef int8_t token_t;

/* <<--params-def-->> */
#define SHA_VSIZE 2
#define SHA_BLOCKSIZE 8192
#define SHA_DIGEST 20
#define SHA_N 10

/* <<--params-->> */
const int32_t sha_vsize = SHA_VSIZE;
const int32_t sha_blocksize = SHA_BLOCKSIZE;
const int32_t sha_digest = SHA_DIGEST;
const int32_t sha_n = SHA_N;

#define NACC 1

struct sha_vivado_access sha_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.sha_vsize = SHA_VSIZE,
		.sha_blocksize = SHA_BLOCKSIZE,
		.sha_digest = SHA_DIGEST,
		.sha_n = SHA_N,
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
		.devname = "sha_vivado.0",
		.ioctl_req = SHA_VIVADO_IOC_ACCESS,
		.esp_desc = &(sha_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
