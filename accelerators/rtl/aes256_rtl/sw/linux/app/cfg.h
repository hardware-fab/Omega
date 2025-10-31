// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "aes256_rtl.h"

typedef int64_t token_t;

/* <<--params-def-->> */
#define AES256_N 100
#define AES256_KEYWORDS 4
#define AES256_BLOCKWORDS 2
#define AES256_KEYREG0 0
#define AES256_KEYREG1 0
#define AES256_KEYREG2 0
#define AES256_KEYREG3 0
#define AES256_KEYREG4 0
#define AES256_KEYREG5 0
#define AES256_KEYREG6 0
#define AES256_KEYREG7 0

/* <<--params-->> */
const int32_t aes256_n = AES256_N;
const int32_t aes256_keyWords = AES256_KEYWORDS;
const int32_t aes256_blockWords = AES256_BLOCKWORDS;
const int32_t aes256_keyReg0 = AES256_KEYREG0;
const int32_t aes256_keyReg1 = AES256_KEYREG1;
const int32_t aes256_keyReg2 = AES256_KEYREG2;
const int32_t aes256_keyReg3 = AES256_KEYREG3;
const int32_t aes256_keyReg4 = AES256_KEYREG4;
const int32_t aes256_keyReg5 = AES256_KEYREG5;
const int32_t aes256_keyReg6 = AES256_KEYREG6;
const int32_t aes256_keyReg7 = AES256_KEYREG7;

#define NACC 1

struct aes256_rtl_access aes256_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.aes256_n = AES256_N,
		.aes256_keyWords = AES256_KEYWORDS,
		.aes256_blockWords = AES256_BLOCKWORDS,
		.aes256_keyReg0 = AES256_KEYREG0,
		.aes256_keyReg1 = AES256_KEYREG1,
		.aes256_keyReg2 = AES256_KEYREG2,
		.aes256_keyReg3 = AES256_KEYREG3,
		.aes256_keyReg4 = AES256_KEYREG4,
		.aes256_keyReg5 = AES256_KEYREG5,
		.aes256_keyReg6 = AES256_KEYREG6,
		.aes256_keyReg7 = AES256_KEYREG7,
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
		.devname = "aes256_rtl.0",
		.ioctl_req = AES256_RTL_IOC_ACCESS,
		.esp_desc = &(aes256_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
