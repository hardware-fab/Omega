// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef _AES256_RTL_H_
#define _AES256_RTL_H_

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

struct aes256_rtl_access {
	struct esp_access esp;
	/* <<--regs-->> */
	unsigned aes256_n;
	unsigned aes256_keyWords;
	unsigned aes256_blockWords;
	unsigned aes256_keyReg0;
	unsigned aes256_keyReg1;
	unsigned aes256_keyReg2;
	unsigned aes256_keyReg3;
	unsigned aes256_keyReg4;
	unsigned aes256_keyReg5;
	unsigned aes256_keyReg6;
	unsigned aes256_keyReg7;
	unsigned src_offset;
	unsigned dst_offset;
};

#define AES256_RTL_IOC_ACCESS	_IOW ('S', 0, struct aes256_rtl_access)

#endif /* _AES256_RTL_H_ */
