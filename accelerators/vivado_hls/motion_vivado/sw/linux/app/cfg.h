// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "motion_vivado.h"

typedef int32_t token_t;

/* <<--params-def-->> */
#define MOTION_MVFS 4
#define MOTION_RDBFR 1
#define MOTION_N 10
#define MOTION_PWM 8

/* <<--params-->> */
const int32_t motion_mvfs = MOTION_MVFS;
const int32_t motion_rdbfr = MOTION_RDBFR;
const int32_t motion_n = MOTION_N;
const int32_t motion_pwm = MOTION_PWM;

#define NACC 1

struct motion_vivado_access motion_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.motion_mvfs = MOTION_MVFS,
		.motion_rdbfr = MOTION_RDBFR,
		.motion_n = MOTION_N,
		.motion_pwm = MOTION_PWM,
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
		.devname = "motion_vivado.0",
		.ioctl_req = MOTION_VIVADO_IOC_ACCESS,
		.esp_desc = &(motion_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
