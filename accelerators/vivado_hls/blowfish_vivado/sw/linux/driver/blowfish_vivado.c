// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "blowfish_vivado.h"

#define DRV_NAME	"blowfish_vivado"

/* <<--regs-->> */
#define BLOWFISH_BLOWFISH_N_REG 0x48
#define BLOWFISH_BLOWFISH_N_REG 0x44
#define BLOWFISH_BLOWFISH_SIZE_REG 0x40

struct blowfish_vivado_device {
	struct esp_device esp;
};

static struct esp_driver blowfish_driver;

static struct of_device_id blowfish_device_ids[] = {
	{
		.name = "SLD_BLOWFISH_VIVADO",
	},
	{
		.name = "eb_302",
	},
	{
		.compatible = "sld,blowfish_vivado",
	},
	{ },
};

static int blowfish_devs;

static inline struct blowfish_vivado_device *to_blowfish(struct esp_device *esp)
{
	return container_of(esp, struct blowfish_vivado_device, esp);
}

static void blowfish_prep_xfer(struct esp_device *esp, void *arg)
{
	struct blowfish_vivado_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->blowfish_N, esp->iomem + BLOWFISH_BLOWFISH_N_REG);
	iowrite32be(a->blowfish_n, esp->iomem + BLOWFISH_BLOWFISH_N_REG);
	iowrite32be(a->blowfish_size, esp->iomem + BLOWFISH_BLOWFISH_SIZE_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool blowfish_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct blowfish_vivado_device *blowfish = to_blowfish(esp); */
	/* struct blowfish_vivado_access *a = arg; */

	return true;
}

static int blowfish_probe(struct platform_device *pdev)
{
	struct blowfish_vivado_device *blowfish;
	struct esp_device *esp;
	int rc;

	blowfish = kzalloc(sizeof(*blowfish), GFP_KERNEL);
	if (blowfish == NULL)
		return -ENOMEM;
	esp = &blowfish->esp;
	esp->module = THIS_MODULE;
	esp->number = blowfish_devs;
	esp->driver = &blowfish_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	blowfish_devs++;
	return 0;
 err:
	kfree(blowfish);
	return rc;
}

static int __exit blowfish_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct blowfish_vivado_device *blowfish = to_blowfish(esp);

	esp_device_unregister(esp);
	kfree(blowfish);
	return 0;
}

static struct esp_driver blowfish_driver = {
	.plat = {
		.probe		= blowfish_probe,
		.remove		= blowfish_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = blowfish_device_ids,
		},
	},
	.xfer_input_ok	= blowfish_xfer_input_ok,
	.prep_xfer	= blowfish_prep_xfer,
	.ioctl_cm	= BLOWFISH_VIVADO_IOC_ACCESS,
	.arg_size	= sizeof(struct blowfish_vivado_access),
};

static int __init blowfish_init(void)
{
	return esp_driver_register(&blowfish_driver);
}

static void __exit blowfish_exit(void)
{
	esp_driver_unregister(&blowfish_driver);
}

module_init(blowfish_init)
module_exit(blowfish_exit)

MODULE_DEVICE_TABLE(of, blowfish_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("blowfish_vivado driver");
