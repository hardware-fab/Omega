// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef _SHA3_RTL_H_
#define _SHA3_RTL_H_

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

struct sha3_rtl_access {
	struct esp_access esp;
	/* <<--regs-->> */
	unsigned sha3_message_len;
	unsigned sha3_n;
	unsigned sha3_hash_len;
	unsigned src_offset;
	unsigned dst_offset;
};

#define SHA3_RTL_IOC_ACCESS	_IOW ('S', 0, struct sha3_rtl_access)

#endif /* _SHA3_RTL_H_ */
