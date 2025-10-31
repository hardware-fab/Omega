// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "aes256_rtl.h"

#define DRV_NAME	"aes256_rtl"

/* <<--regs-->> */
#define AES256_AES256_N_REG 0x68
#define AES256_AES256_KEYWORDS_REG 0x64
#define AES256_AES256_BLOCKWORDS_REG 0x60
#define AES256_AES256_KEYREG0_REG 0x5c
#define AES256_AES256_KEYREG1_REG 0x58
#define AES256_AES256_KEYREG2_REG 0x54
#define AES256_AES256_KEYREG3_REG 0x50
#define AES256_AES256_KEYREG4_REG 0x4c
#define AES256_AES256_KEYREG5_REG 0x48
#define AES256_AES256_KEYREG6_REG 0x44
#define AES256_AES256_KEYREG7_REG 0x40

struct aes256_rtl_device {
	struct esp_device esp;
};

static struct esp_driver aes256_driver;

static struct of_device_id aes256_device_ids[] = {
	{
		.name = "SLD_AES256_RTL",
	},
	{
		.name = "eb_312",
	},
	{
		.compatible = "sld,aes256_rtl",
	},
	{ },
};

static int aes256_devs;

static inline struct aes256_rtl_device *to_aes256(struct esp_device *esp)
{
	return container_of(esp, struct aes256_rtl_device, esp);
}

static void aes256_prep_xfer(struct esp_device *esp, void *arg)
{
	struct aes256_rtl_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->aes256_n, esp->iomem + AES256_AES256_N_REG);
	iowrite32be(a->aes256_keyWords, esp->iomem + AES256_AES256_KEYWORDS_REG);
	iowrite32be(a->aes256_blockWords, esp->iomem + AES256_AES256_BLOCKWORDS_REG);
	iowrite32be(a->aes256_keyReg0, esp->iomem + AES256_AES256_KEYREG0_REG);
	iowrite32be(a->aes256_keyReg1, esp->iomem + AES256_AES256_KEYREG1_REG);
	iowrite32be(a->aes256_keyReg2, esp->iomem + AES256_AES256_KEYREG2_REG);
	iowrite32be(a->aes256_keyReg3, esp->iomem + AES256_AES256_KEYREG3_REG);
	iowrite32be(a->aes256_keyReg4, esp->iomem + AES256_AES256_KEYREG4_REG);
	iowrite32be(a->aes256_keyReg5, esp->iomem + AES256_AES256_KEYREG5_REG);
	iowrite32be(a->aes256_keyReg6, esp->iomem + AES256_AES256_KEYREG6_REG);
	iowrite32be(a->aes256_keyReg7, esp->iomem + AES256_AES256_KEYREG7_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool aes256_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct aes256_rtl_device *aes256 = to_aes256(esp); */
	/* struct aes256_rtl_access *a = arg; */

	return true;
}

static int aes256_probe(struct platform_device *pdev)
{
	struct aes256_rtl_device *aes256;
	struct esp_device *esp;
	int rc;

	aes256 = kzalloc(sizeof(*aes256), GFP_KERNEL);
	if (aes256 == NULL)
		return -ENOMEM;
	esp = &aes256->esp;
	esp->module = THIS_MODULE;
	esp->number = aes256_devs;
	esp->driver = &aes256_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	aes256_devs++;
	return 0;
 err:
	kfree(aes256);
	return rc;
}

static int __exit aes256_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct aes256_rtl_device *aes256 = to_aes256(esp);

	esp_device_unregister(esp);
	kfree(aes256);
	return 0;
}

static struct esp_driver aes256_driver = {
	.plat = {
		.probe		= aes256_probe,
		.remove		= aes256_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = aes256_device_ids,
		},
	},
	.xfer_input_ok	= aes256_xfer_input_ok,
	.prep_xfer	= aes256_prep_xfer,
	.ioctl_cm	= AES256_RTL_IOC_ACCESS,
	.arg_size	= sizeof(struct aes256_rtl_access),
};

static int __init aes256_init(void)
{
	return esp_driver_register(&aes256_driver);
}

static void __exit aes256_exit(void)
{
	esp_driver_unregister(&aes256_driver);
}

module_init(aes256_init)
module_exit(aes256_exit)

MODULE_DEVICE_TABLE(of, aes256_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("aes256_rtl driver");
