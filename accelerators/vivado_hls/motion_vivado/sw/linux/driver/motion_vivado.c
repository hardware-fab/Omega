// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "motion_vivado.h"

#define DRV_NAME	"motion_vivado"

/* <<--regs-->> */
#define MOTION_MOTION_MVFS_REG 0x4c
#define MOTION_MOTION_RDBFR_REG 0x48
#define MOTION_MOTION_N_REG 0x44
#define MOTION_MOTION_PWM_REG 0x40

struct motion_vivado_device {
	struct esp_device esp;
};

static struct esp_driver motion_driver;

static struct of_device_id motion_device_ids[] = {
	{
		.name = "SLD_MOTION_VIVADO",
	},
	{
		.name = "eb_30a",
	},
	{
		.compatible = "sld,motion_vivado",
	},
	{ },
};

static int motion_devs;

static inline struct motion_vivado_device *to_motion(struct esp_device *esp)
{
	return container_of(esp, struct motion_vivado_device, esp);
}

static void motion_prep_xfer(struct esp_device *esp, void *arg)
{
	struct motion_vivado_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->motion_mvfs, esp->iomem + MOTION_MOTION_MVFS_REG);
	iowrite32be(a->motion_rdbfr, esp->iomem + MOTION_MOTION_RDBFR_REG);
	iowrite32be(a->motion_n, esp->iomem + MOTION_MOTION_N_REG);
	iowrite32be(a->motion_pwm, esp->iomem + MOTION_MOTION_PWM_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool motion_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct motion_vivado_device *motion = to_motion(esp); */
	/* struct motion_vivado_access *a = arg; */

	return true;
}

static int motion_probe(struct platform_device *pdev)
{
	struct motion_vivado_device *motion;
	struct esp_device *esp;
	int rc;

	motion = kzalloc(sizeof(*motion), GFP_KERNEL);
	if (motion == NULL)
		return -ENOMEM;
	esp = &motion->esp;
	esp->module = THIS_MODULE;
	esp->number = motion_devs;
	esp->driver = &motion_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	motion_devs++;
	return 0;
 err:
	kfree(motion);
	return rc;
}

static int __exit motion_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct motion_vivado_device *motion = to_motion(esp);

	esp_device_unregister(esp);
	kfree(motion);
	return 0;
}

static struct esp_driver motion_driver = {
	.plat = {
		.probe		= motion_probe,
		.remove		= motion_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = motion_device_ids,
		},
	},
	.xfer_input_ok	= motion_xfer_input_ok,
	.prep_xfer	= motion_prep_xfer,
	.ioctl_cm	= MOTION_VIVADO_IOC_ACCESS,
	.arg_size	= sizeof(struct motion_vivado_access),
};

static int __init motion_init(void)
{
	return esp_driver_register(&motion_driver);
}

static void __exit motion_exit(void)
{
	esp_driver_unregister(&motion_driver);
}

module_init(motion_init)
module_exit(motion_exit)

MODULE_DEVICE_TABLE(of, motion_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("motion_vivado driver");
