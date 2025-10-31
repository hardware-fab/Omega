// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "sha3_rtl.h"

#define DRV_NAME	"sha3_rtl"

/* <<--regs-->> */
#define SHA3_SHA3_MESSAGE_LEN_REG 0x48
#define SHA3_SHA3_N_REG 0x44
#define SHA3_SHA3_HASH_LEN_REG 0x40

struct sha3_rtl_device {
	struct esp_device esp;
};

static struct esp_driver sha3_driver;

static struct of_device_id sha3_device_ids[] = {
	{
		.name = "SLD_SHA3_RTL",
	},
	{
		.name = "eb_311",
	},
	{
		.compatible = "sld,sha3_rtl",
	},
	{ },
};

static int sha3_devs;

static inline struct sha3_rtl_device *to_sha3(struct esp_device *esp)
{
	return container_of(esp, struct sha3_rtl_device, esp);
}

static void sha3_prep_xfer(struct esp_device *esp, void *arg)
{
	struct sha3_rtl_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->sha3_message_len, esp->iomem + SHA3_SHA3_MESSAGE_LEN_REG);
	iowrite32be(a->sha3_n, esp->iomem + SHA3_SHA3_N_REG);
	iowrite32be(a->sha3_hash_len, esp->iomem + SHA3_SHA3_HASH_LEN_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool sha3_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct sha3_rtl_device *sha3 = to_sha3(esp); */
	/* struct sha3_rtl_access *a = arg; */

	return true;
}

static int sha3_probe(struct platform_device *pdev)
{
	struct sha3_rtl_device *sha3;
	struct esp_device *esp;
	int rc;

	sha3 = kzalloc(sizeof(*sha3), GFP_KERNEL);
	if (sha3 == NULL)
		return -ENOMEM;
	esp = &sha3->esp;
	esp->module = THIS_MODULE;
	esp->number = sha3_devs;
	esp->driver = &sha3_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	sha3_devs++;
	return 0;
 err:
	kfree(sha3);
	return rc;
}

static int __exit sha3_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct sha3_rtl_device *sha3 = to_sha3(esp);

	esp_device_unregister(esp);
	kfree(sha3);
	return 0;
}

static struct esp_driver sha3_driver = {
	.plat = {
		.probe		= sha3_probe,
		.remove		= sha3_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = sha3_device_ids,
		},
	},
	.xfer_input_ok	= sha3_xfer_input_ok,
	.prep_xfer	= sha3_prep_xfer,
	.ioctl_cm	= SHA3_RTL_IOC_ACCESS,
	.arg_size	= sizeof(struct sha3_rtl_access),
};

static int __init sha3_init(void)
{
	return esp_driver_register(&sha3_driver);
}

static void __exit sha3_exit(void)
{
	esp_driver_unregister(&sha3_driver);
}

module_init(sha3_init)
module_exit(sha3_exit)

MODULE_DEVICE_TABLE(of, sha3_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("sha3_rtl driver");
