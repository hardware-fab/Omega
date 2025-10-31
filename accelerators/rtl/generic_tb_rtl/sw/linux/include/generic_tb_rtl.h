// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef _GENERIC_TB_RTL_H_
#define _GENERIC_TB_RTL_H_

#ifdef __KERNEL__
#include <linux/ioctl.h>
#include <linux/types.h>
#else
#include <sys/ioctl.h>
#include <stdint.h>
#ifndef __user
#define __user
#endif
#endif /* __KERNEL__ */

#include <esp.h>
#include <esp_accelerator.h>

struct generic_tb_rtl_access {
	struct esp_access esp;
	/* <<--regs-->> */
	unsigned reg0;
	unsigned generic_tb_n;
	unsigned reg2;
	unsigned src_offset;
	unsigned dst_offset;
};

#define GENERIC_TB_RTL_IOC_ACCESS	_IOW ('S', 0, struct generic_tb_rtl_access)

#endif /* _GENERIC_TB_RTL_H_ */
