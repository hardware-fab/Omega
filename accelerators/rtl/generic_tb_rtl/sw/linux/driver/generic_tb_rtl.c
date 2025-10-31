// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "generic_tb_rtl.h"

#define DRV_NAME	"generic_tb_rtl"

/* <<--regs-->> */
#define GENERIC_TB_REG0_REG 0x48
#define GENERIC_TB_REG1_REG 0x44
#define GENERIC_TB_REG2_REG 0x40

struct generic_tb_rtl_device {
	struct esp_device esp;
};

static struct esp_driver generic_tb_driver;

static struct of_device_id generic_tb_device_ids[] = {
	{
		.name = "SLD_GENERIC_TB_RTL",
	},
	{
		.name = "eb_200",
	},
	{
		.compatible = "sld,generic_tb_rtl",
	},
	{ },
};

static int generic_tb_devs;

static inline struct generic_tb_rtl_device *to_generic_tb(struct esp_device *esp)
{
	return container_of(esp, struct generic_tb_rtl_device, esp);
}

static void generic_tb_prep_xfer(struct esp_device *esp, void *arg)
{
	struct generic_tb_rtl_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->reg0, esp->iomem + GENERIC_TB_REG0_REG);
	iowrite32be(a->generic_tb_n, esp->iomem + GENERIC_TB_REG1_REG);
	iowrite32be(a->reg2, esp->iomem + GENERIC_TB_REG2_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool generic_tb_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct generic_tb_rtl_device *generic_tb = to_generic_tb(esp); */
	/* struct generic_tb_rtl_access *a = arg; */

	return true;
}

static int generic_tb_probe(struct platform_device *pdev)
{
	struct generic_tb_rtl_device *generic_tb;
	struct esp_device *esp;
	int rc;

	generic_tb = kzalloc(sizeof(*generic_tb), GFP_KERNEL);
	if (generic_tb == NULL)
		return -ENOMEM;
	esp = &generic_tb->esp;
	esp->module = THIS_MODULE;
	esp->number = generic_tb_devs;
	esp->driver = &generic_tb_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	generic_tb_devs++;
	return 0;
 err:
	kfree(generic_tb);
	return rc;
}

static int __exit generic_tb_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct generic_tb_rtl_device *generic_tb = to_generic_tb(esp);

	esp_device_unregister(esp);
	kfree(generic_tb);
	return 0;
}

static struct esp_driver generic_tb_driver = {
	.plat = {
		.probe		= generic_tb_probe,
		.remove		= generic_tb_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = generic_tb_device_ids,
		},
	},
	.xfer_input_ok	= generic_tb_xfer_input_ok,
	.prep_xfer	= generic_tb_prep_xfer,
	.ioctl_cm	= GENERIC_TB_RTL_IOC_ACCESS,
	.arg_size	= sizeof(struct generic_tb_rtl_access),
};

static int __init generic_tb_init(void)
{
	return esp_driver_register(&generic_tb_driver);
}

static void __exit generic_tb_exit(void)
{
	esp_driver_unregister(&generic_tb_driver);
}

module_init(generic_tb_init)
module_exit(generic_tb_exit)

MODULE_DEVICE_TABLE(of, generic_tb_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("generic_tb_rtl driver");
