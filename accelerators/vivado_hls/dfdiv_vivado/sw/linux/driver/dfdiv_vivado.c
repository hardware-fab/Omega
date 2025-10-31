// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "dfdiv_vivado.h"

#define DRV_NAME	"dfdiv_vivado"

/* <<--regs-->> */
#define DFDIV_DFDIV_N_REG 0x48
#define DFDIV_DFDIV_IN_REG 0x44
#define DFDIV_DFDIV_OUT_REG 0x40

struct dfdiv_vivado_device {
	struct esp_device esp;
};

static struct esp_driver dfdiv_driver;

static struct of_device_id dfdiv_device_ids[] = {
	{
		.name = "SLD_DFDIV_VIVADO",
	},
	{
		.name = "eb_304",
	},
	{
		.compatible = "sld,dfdiv_vivado",
	},
	{ },
};

static int dfdiv_devs;

static inline struct dfdiv_vivado_device *to_dfdiv(struct esp_device *esp)
{
	return container_of(esp, struct dfdiv_vivado_device, esp);
}

static void dfdiv_prep_xfer(struct esp_device *esp, void *arg)
{
	struct dfdiv_vivado_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->dfdiv_n, esp->iomem + DFDIV_DFDIV_N_REG);
	iowrite32be(a->dfdiv_in, esp->iomem + DFDIV_DFDIV_IN_REG);
	iowrite32be(a->dfdiv_out, esp->iomem + DFDIV_DFDIV_OUT_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool dfdiv_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct dfdiv_vivado_device *dfdiv = to_dfdiv(esp); */
	/* struct dfdiv_vivado_access *a = arg; */

	return true;
}

static int dfdiv_probe(struct platform_device *pdev)
{
	struct dfdiv_vivado_device *dfdiv;
	struct esp_device *esp;
	int rc;

	dfdiv = kzalloc(sizeof(*dfdiv), GFP_KERNEL);
	if (dfdiv == NULL)
		return -ENOMEM;
	esp = &dfdiv->esp;
	esp->module = THIS_MODULE;
	esp->number = dfdiv_devs;
	esp->driver = &dfdiv_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	dfdiv_devs++;
	return 0;
 err:
	kfree(dfdiv);
	return rc;
}

static int __exit dfdiv_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct dfdiv_vivado_device *dfdiv = to_dfdiv(esp);

	esp_device_unregister(esp);
	kfree(dfdiv);
	return 0;
}

static struct esp_driver dfdiv_driver = {
	.plat = {
		.probe		= dfdiv_probe,
		.remove		= dfdiv_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = dfdiv_device_ids,
		},
	},
	.xfer_input_ok	= dfdiv_xfer_input_ok,
	.prep_xfer	= dfdiv_prep_xfer,
	.ioctl_cm	= DFDIV_VIVADO_IOC_ACCESS,
	.arg_size	= sizeof(struct dfdiv_vivado_access),
};

static int __init dfdiv_init(void)
{
	return esp_driver_register(&dfdiv_driver);
}

static void __exit dfdiv_exit(void)
{
	esp_driver_unregister(&dfdiv_driver);
}

module_init(dfdiv_init)
module_exit(dfdiv_exit)

MODULE_DEVICE_TABLE(of, dfdiv_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("dfdiv_vivado driver");
