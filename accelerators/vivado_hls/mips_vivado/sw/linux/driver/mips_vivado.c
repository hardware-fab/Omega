// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "mips_vivado.h"

#define DRV_NAME	"mips_vivado"

/* <<--regs-->> */
#define MIPS_MIPS_IN_REG 0x48
#define MIPS_MIPS_N_REG 0x44
#define MIPS_MIPS_OUT_REG 0x40

struct mips_vivado_device {
	struct esp_device esp;
};

static struct esp_driver mips_driver;

static struct of_device_id mips_device_ids[] = {
	{
		.name = "SLD_MIPS_VIVADO",
	},
	{
		.name = "eb_308",
	},
	{
		.compatible = "sld,mips_vivado",
	},
	{ },
};

static int mips_devs;

static inline struct mips_vivado_device *to_mips(struct esp_device *esp)
{
	return container_of(esp, struct mips_vivado_device, esp);
}

static void mips_prep_xfer(struct esp_device *esp, void *arg)
{
	struct mips_vivado_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->mips_in, esp->iomem + MIPS_MIPS_IN_REG);
	iowrite32be(a->mips_n, esp->iomem + MIPS_MIPS_N_REG);
	iowrite32be(a->mips_out, esp->iomem + MIPS_MIPS_OUT_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool mips_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct mips_vivado_device *mips = to_mips(esp); */
	/* struct mips_vivado_access *a = arg; */

	return true;
}

static int mips_probe(struct platform_device *pdev)
{
	struct mips_vivado_device *mips;
	struct esp_device *esp;
	int rc;

	mips = kzalloc(sizeof(*mips), GFP_KERNEL);
	if (mips == NULL)
		return -ENOMEM;
	esp = &mips->esp;
	esp->module = THIS_MODULE;
	esp->number = mips_devs;
	esp->driver = &mips_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	mips_devs++;
	return 0;
 err:
	kfree(mips);
	return rc;
}

static int __exit mips_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct mips_vivado_device *mips = to_mips(esp);

	esp_device_unregister(esp);
	kfree(mips);
	return 0;
}

static struct esp_driver mips_driver = {
	.plat = {
		.probe		= mips_probe,
		.remove		= mips_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = mips_device_ids,
		},
	},
	.xfer_input_ok	= mips_xfer_input_ok,
	.prep_xfer	= mips_prep_xfer,
	.ioctl_cm	= MIPS_VIVADO_IOC_ACCESS,
	.arg_size	= sizeof(struct mips_vivado_access),
};

static int __init mips_init(void)
{
	return esp_driver_register(&mips_driver);
}

static void __exit mips_exit(void)
{
	esp_driver_unregister(&mips_driver);
}

module_init(mips_init)
module_exit(mips_exit)

MODULE_DEVICE_TABLE(of, mips_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("mips_vivado driver");
