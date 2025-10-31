/* Copyright (c) 2011-2023 Columbia University, System Level Design Group */
/* SPDX-License-Identifier: Apache-2.0 */

#include <stdio.h>
#ifndef __riscv
#include <stdlib.h>
#endif

#include <esp_accelerator.h>
#include <esp_probe.h>
#include <fixed_point.h>

#include "../global.h"

#define BASE_ADDRESS 0x60000300
#define TIMER_LO 0xB4
#define TIMER_HI 0xB8

#define CLOCK_PERIOD 20

static double start_time, end_time, total_time_sw;
static double total_time_hw[6];

static long unsigned custom_gettime_nano()
{
	volatile unsigned long timer_reg_lo, timer_reg_hi;
	volatile uint32_t * timer_lo_ptr = (volatile uint32_t *)(BASE_ADDRESS + TIMER_LO);
	volatile uint32_t * timer_hi_ptr = (volatile uint32_t *)(BASE_ADDRESS + TIMER_HI);
	timer_reg_lo = *timer_lo_ptr;
	timer_reg_hi = *timer_hi_ptr;
	return (long unsigned) ((*timer_lo_ptr | (long unsigned)(*timer_hi_ptr)<<32)*CLOCK_PERIOD);
}

static void print_time(long unsigned value)
{
	uint32_t nano = value%1000;
	uint32_t micro = (value%1000000)/1000;
	uint32_t milli = (value%1000000000)/1000000;
	uint32_t sec = (value%1000000000000)/1000000000;
	printf("original value=%lu : %u s - %u ms - %u us - %u ns", value, sec, milli, micro, nano);
}

static void print_time_us(long unsigned value)
{
	uint32_t decimal = value%1000;
	uint32_t integer = (value)/1000;
	printf("%u,%03u", integer, decimal);
}

#define Num 2048

const unsigned char inRdbfr[Num] = {
    0, 104, 120, 48, 72, 32, 160, 192, 192, 64, 56, 248, 248, 88, 136, 224, 200,
    208, 176, 72, 96, 40, 184, 160, 32, 32, 120, 168, 64, 32, 72, 184,
    216, 240, 0, 216, 192, 64, 112, 48, 160, 152, 40, 176, 32, 32, 248, 200,
    104, 24, 216, 240, 128, 176, 72, 232, 240, 184, 48, 120, 48, 192, 64, 168,
    160, 128, 160, 160, 232, 208, 104, 120, 232, 120, 8, 184, 120, 200, 64, 160,
    200, 224, 64, 168, 40, 120, 80, 104, 16, 0, 8, 120, 144, 136, 80, 144,
    72, 24, 128, 216, 216, 24, 80, 16, 64, 32, 200, 112, 128, 144, 88, 24, 112,
    120, 32, 104, 72, 176, 24, 16, 184, 56, 24, 200, 152, 152, 48, 48,
    136, 80, 240, 8, 216, 200, 240, 32, 168, 112, 48, 56, 40, 192, 232, 32, 48,
    232, 232, 32, 0, 88, 208, 24, 240, 72, 120, 96, 248, 136, 224, 208,
    8, 184, 192, 144, 88, 48, 144, 136, 112, 192, 96, 240, 200, 160, 184, 160,
    24, 48, 208, 152, 128, 184, 184, 144, 144, 168, 240, 144, 160, 168, 48,
    48,
    24, 200, 144, 120, 208, 56, 96, 72, 48, 88, 80, 200, 248, 208, 248, 40, 136,
    112, 32, 8, 8, 80, 192, 40, 32, 224, 56, 192, 200, 56, 56, 232,
    200, 80, 120, 8, 184, 216, 232, 80, 168, 128, 32, 216, 136, 104, 248, 168,
    248, 8, 192, 168, 192, 56, 240, 192, 208, 136, 120, 48, 224, 112, 168, 80,
    192, 96, 80, 120, 120, 16, 120, 48, 168, 168, 160, 224, 128, 24, 72, 24,
    248, 240, 152, 160, 208, 56, 192, 56, 88, 128, 192, 136, 128, 208, 112,
    40,
    64, 192, 32, 176, 80, 56, 168, 208, 24, 168, 168, 248, 240, 136, 96, 32, 56,
    184, 8, 136, 16, 0, 176, 40, 0, 32, 104, 160, 56, 88, 232, 56,
    0, 240, 184, 232, 88, 32, 176, 0, 216, 248, 184, 40, 16, 80, 8, 208, 64,
    224, 72, 40, 72, 72, 144, 80, 144, 120, 136, 64, 184, 160, 136, 16,
    48, 104, 232, 104, 104, 72, 208, 72, 192, 184, 40, 56, 232, 72, 160, 80,
    152, 232, 248, 32, 224, 40, 0, 168, 24, 96, 112, 160, 152, 8, 32, 160,
    104, 208, 32, 24, 248, 8, 248, 144, 120, 16, 192, 88, 152, 176, 200, 160,
    152, 160, 96, 168, 240, 16, 248, 176, 24, 216, 0, 56, 80, 248, 96, 8,
    128, 32, 192, 104, 48, 208, 240, 184, 128, 80, 56, 192, 0, 112, 176, 48, 96,
    56, 24, 56, 24, 32, 24, 96, 80, 0, 64, 112, 48, 24, 88, 56,
    152, 224, 160, 192, 184, 72, 248, 128, 8, 8, 104, 104, 200, 48, 136, 136,
    208, 144, 80, 40, 136, 96, 8, 208, 160, 104, 160, 80, 64, 96, 176, 144,
    8, 56, 88, 88, 208, 120, 48, 240, 240, 96, 248, 192, 104, 128, 248, 24, 104,
    72, 64, 120, 248, 192, 48, 192, 32, 80, 144, 16, 80, 96, 112, 184,
    56, 80, 248, 232, 0, 40, 248, 56, 192, 32, 192, 96, 248, 48, 136, 224, 80,
    0, 192, 128, 104, 120, 208, 128, 0, 176, 216, 8, 192, 96, 16, 40,
    184, 96, 32, 72, 80, 192, 104, 104, 136, 0, 16, 160, 24, 104, 48, 8, 24,
    152, 120, 128, 72, 32, 176, 112, 104, 120, 16, 32, 144, 160, 56, 240,
    0, 232, 184, 24, 16, 208, 200, 240, 200, 200, 104, 112, 24, 208, 128, 168,
    248, 64, 152, 120, 64, 224, 128, 208, 120, 216, 16, 152, 48, 144, 240, 80,
    144, 224, 48, 160, 192, 248, 0, 128, 120, 128, 160, 232, 168, 208, 112, 112,
    104, 184, 8, 192, 56, 176, 40, 96, 64, 72, 104, 216, 152, 216, 80, 152,
    184, 216, 32, 56, 32, 64, 240, 152, 240, 168, 136, 8, 232, 168, 128, 88, 72,
    128, 8, 192, 48, 120, 112, 32, 144, 208, 192, 216, 16, 176, 168, 160,
    168, 88, 136, 56, 8, 64, 0, 80, 216, 104, 64, 80, 88, 208, 64, 80, 200, 24,
    120, 160, 80, 72, 56, 216, 24, 56, 72, 40, 72, 0, 56, 136,
    56, 200, 72, 136, 88, 72, 136, 240, 0, 176, 176, 152, 192, 248, 224, 240,
    72, 8, 112, 232, 200, 120, 16, 0, 40, 48, 64, 72, 32, 136, 104, 152,
    16, 240, 184, 80, 0, 152, 32, 176, 128, 120, 0, 160, 40, 64, 112, 40, 80,
    48, 144, 96, 168, 0, 152, 72, 184, 136, 88, 152, 184, 48, 88, 152,
    96, 216, 240, 184, 200, 136, 64, 104, 112, 232, 0, 208, 176, 128, 112, 248,
    144, 248, 120, 112, 0, 120, 240, 88, 88, 88, 8, 248, 80, 8, 64, 216,
    240, 56, 56, 144, 112, 208, 144, 72, 16, 160, 136, 216, 176, 112, 56, 8,
    168, 104, 72, 40, 176, 88, 40, 120, 24, 40, 56, 104, 40, 160, 232, 160,
    24, 144, 144, 232, 120, 144, 112, 96, 136, 176, 8, 128, 112, 184, 96, 120,
    64, 112, 0, 184, 80, 72, 184, 80, 144, 72, 120, 200, 168, 32, 24, 0,
    144, 72, 24, 248, 24, 152, 72, 128, 0, 8, 224, 32, 72, 72, 48, 112, 232, 16,
    240, 24, 64, 32, 232, 120, 168, 200, 152, 112, 8, 144, 0, 120,
    112, 0, 112, 144, 72, 160, 24, 216, 112, 128, 224, 152, 104, 136, 40, 0, 16,
    144, 48, 248, 136, 48, 64, 88, 152, 208, 248, 16, 112, 224, 184, 168,
    40, 168, 64, 248, 144, 104, 200, 144, 152, 16, 168, 192, 240, 96, 72, 136,
    216, 136, 0, 32, 192, 112, 240, 160, 248, 184, 16, 48, 232, 88, 160, 16,
    104, 176, 144, 136, 24, 240, 184, 160, 8, 16, 32, 56, 176, 144, 168, 168,
    56, 88, 88, 104, 248, 184, 96, 32, 128, 88, 224, 240, 32, 120, 216, 136,
    8, 72, 80, 104, 120, 152, 32, 96, 232, 80, 232, 24, 80, 200, 208, 216, 184,
    16, 56, 40, 216, 208, 128, 120, 16, 16, 80, 200, 144, 104, 160, 72,
    24, 136, 176, 32, 192, 120, 136, 80, 16, 88, 208, 160, 16, 232, 40, 24, 144,
    208, 32, 16, 88, 192, 48, 176, 152, 24, 160, 32, 80, 24, 240, 80,
    160, 152, 160, 128, 80, 88, 40, 184, 208, 144, 48, 200, 200, 48, 112, 144,
    104, 224, 144, 224, 200, 8, 224, 240, 32, 152, 232, 16, 8, 80, 184, 40,
    184, 248, 64, 8, 232, 16, 88, 88, 8, 120, 128, 48, 240, 88, 64, 104, 104,
    248, 96, 240, 192, 152, 208, 56, 152, 240, 136, 8, 216, 24, 112, 168,
    88, 136, 80, 224, 136, 152, 40, 24, 248, 216, 152, 136, 96, 224, 64, 80, 56,
    56, 72, 8, 24, 64, 144, 24, 208, 216, 128, 120, 96, 168, 120, 152,
    112, 232, 136, 80, 72, 96, 152, 208, 72, 216, 64, 120, 120, 48, 232, 72,
    184, 176, 48, 232, 200, 184, 120, 72, 112, 128, 248, 160, 168, 216, 152,
    80,
    176, 112, 48, 152, 112, 64, 40, 200, 232, 80, 160, 56, 216, 192, 168, 72,
    40, 64, 208, 32, 224, 240, 24, 104, 232, 240, 168, 24, 248, 32, 80, 152,
    144, 160, 112, 120, 96, 240, 64, 160, 248, 248, 152, 48, 112, 88, 128, 232,
    240, 240, 232, 168, 120, 32, 152, 176, 104, 16, 80, 152, 240, 224, 128,
    16,
    48, 32, 216, 8, 104, 248, 184, 208, 216, 120, 80, 208, 128, 56, 112, 40,
    184, 16, 224, 168, 152, 248, 56, 144, 168, 224, 8, 168, 80, 136, 152, 48,
    96, 0, 184, 88, 192, 24, 16, 128, 0, 176, 152, 40, 96, 72, 192, 0, 32, 128,
    24, 240, 48, 248, 176, 120, 16, 168, 224, 72, 8, 200, 48, 176,
    112, 224, 160, 8, 152, 64, 16, 16, 240, 224, 64, 144, 128, 80, 184, 40, 232,
    200, 112, 248, 24, 112, 176, 128, 128, 56, 40, 152, 24, 184, 120, 104,
    72, 64, 200, 48, 224, 0, 56, 232, 32, 240, 184, 104, 104, 32, 192, 200, 200,
    64, 152, 72, 216, 216, 80, 0, 80, 0, 0, 160, 120, 40, 136, 240,
    32, 120, 152, 216, 56, 112, 16, 24, 8, 120, 104, 192, 144, 176, 8, 16, 96,
    104, 168, 80, 192, 232, 112, 112, 56, 88, 176, 240, 32, 176, 248, 80,
    176, 24, 224, 192, 8, 176, 168, 16, 232, 248, 16, 16, 104, 128, 232, 0, 32,
    240, 112, 32, 184, 184, 56, 232, 80, 144, 16, 72, 240, 208, 64, 176,
    240, 16, 136, 16, 80, 192, 24, 72, 216, 56, 80, 216, 32, 144, 72, 24, 64,
    248, 0, 224, 72, 32, 136, 232, 240, 72, 32, 88, 128, 104, 16, 8,
    32, 192, 224, 8, 152, 248, 224, 0, 176, 48, 16, 104, 216, 176, 24, 240, 200,
    80, 248, 208, 128, 200, 72, 8, 152, 128, 80, 120, 80, 152, 232, 200,
    168, 88, 16, 176, 232, 40, 72, 208, 232, 112, 240, 112, 80, 176, 176, 16,
    72, 120, 32, 184, 224, 80, 24, 176, 0, 208, 16, 56, 112, 16, 120, 160,
    24, 216, 128, 136, 192, 152, 248, 120, 160, 56, 192, 224, 0, 136, 112, 112,
    8, 8, 184, 168, 88, 160, 120, 160, 240, 168, 32, 40, 168, 88, 8, 16,
    24, 104, 104, 48, 248, 136, 72, 144, 128, 160, 216, 88, 240, 120, 232, 72,
    192, 200, 248, 192, 48, 240, 104, 208, 40, 104, 16, 128, 80, 224, 224, 56,
    56, 120, 40, 24, 176, 16, 184, 24, 176, 224, 168, 16, 184, 104, 136, 200,
    168, 208, 120, 200, 224, 40, 208, 16, 112, 160, 192, 224, 64, 40, 232,
    120,
    24, 232, 168, 80, 88, 144, 104, 72, 192, 112, 0, 112, 104, 224, 232, 160,
    112, 208, 176, 216, 56, 224, 224, 160, 104, 56, 176, 216, 192, 24, 208, 8,
    40, 56, 248, 8, 120, 184, 128, 40, 168, 56, 184, 192, 136, 96, 72, 216, 8,
    64, 72, 56, 16, 176, 144, 16, 128, 176, 136, 208, 120, 16, 184, 224,
    160, 216, 144, 88, 208, 200, 144, 96, 152, 200, 224, 208, 240, 120, 8, 104,
    184, 112, 168, 200, 112, 72, 0, 192, 0, 40, 120, 136, 112, 40, 152, 56,
    144, 32, 224, 240, 32, 192, 56, 200, 16, 136, 104, 192, 192, 0, 0, 0, 8,
    232, 104, 240, 88, 192, 8, 168, 216, 208, 184, 224, 240, 72, 152, 72,
    168, 184, 176, 216, 48, 144, 80, 32, 184, 208, 112, 160, 88, 88, 8, 144,
    144, 120, 152, 48, 200, 168, 112, 8, 160, 216, 240, 128, 104, 128, 144,
    248,
    64, 168, 136, 240, 160, 56, 136, 216, 80, 56, 192, 32, 64, 128, 80, 32, 32,
    96, 88, 200, 152, 72, 160, 16, 128, 200, 160, 144, 112, 16, 112, 152,
    56, 136, 56, 216, 8, 24, 192, 144, 176, 200, 48, 72, 40, 72, 240, 120, 120,
    160, 80, 152, 144, 216, 224, 152, 40, 144, 160, 88, 184, 184, 192, 128,
    0, 200, 72, 112, 208, 248, 152, 0, 152, 8, 40, 16, 168, 152, 64, 176, 88,
    24, 232, 136, 32, 152, 232, 208, 192, 240, 136, 0, 232, 200, 8, 216,
    104, 184, 64, 192, 8, 96, 184, 120, 208, 80, 16, 64, 136, 136, 72, 8, 112,
    184, 248, 120, 136, 8, 56, 232, 208, 96, 16, 64, 168, 112, 48, 32,
    184, 224, 72, 88, 128, 184, 72, 168, 224, 216, 160, 232, 64, 168, 48, 152,
    64, 152, 16, 200, 168, 56, 144, 192, 64, 120, 168, 8, 128, 216, 16, 8,
    104, 32, 128, 96, 160, 88, 136, 96, 56, 16, 128, 56, 88, 16, 208, 200, 24,
    96, 240, 32, 232, 192, 104, 168, 40, 0, 192, 40, 200, 96, 184, 8,
    72, 216, 104, 232, 112, 248, 8, 8, 248, 192, 152, 32, 0, 168, 232, 80, 248,
    64, 8, 24, 80, 32, 96, 240, 232, 48, 80, 16, 144, 200, 16, 48,
    88, 40, 112, 232, 88, 168, 56, 160, 232, 16, 128, 248, 48, 80, 200, 168,
    152, 72, 216, 224, 72, 208, 152, 192, 0, 224, 48, 136, 168, 96, 16, 152};
const int inmvfs[2][2] = {{232, 200}, {32, 240}};
const int inPMV[2][2][2] = {{{45, 207}, {70, 41}}, {{4, 180}, {120, 216}}};

/*
+--------------------------------------------------------------------------+
| * Test Vectors (added for CHStone)                                       |
|     outPMV, outmvfs : expected output data                               |
+--------------------------------------------------------------------------+
*/
const int outPMV[2][2][2] = {{{1566, 206}, {70, 41}}, {{1566, 206}, {120, 216}}};
const int outmvfs[2][2] = {{0, 200}, {0, 240}};

typedef int32_t token_t;

static unsigned DMA_WORD_PER_BEAT(unsigned _st)
{
        return (sizeof(void *) / _st);
}


#define SLD_MOTION 0x30a
#define DEV_NAME "sld,motion_vivado"

/* <<--params-->> */
const int32_t motion_mvfs = 4;
const int32_t motion_rdbfr = 512;
const int32_t motion_n = 10;
const int32_t motion_pwm = 8;

static unsigned in_words_adj;
static unsigned out_words_adj;
static unsigned in_len;
static unsigned out_len;
static unsigned in_size;
static unsigned out_size;
static unsigned out_offset;
static unsigned mem_size;

/* Size of the contiguous chunks for scatter/gather */
#define CHUNK_SHIFT 20
#define CHUNK_SIZE BIT(CHUNK_SHIFT)
#define NCHUNK(_sz) ((_sz % CHUNK_SIZE == 0) ?		\
			(_sz / CHUNK_SIZE) :		\
			(_sz / CHUNK_SIZE) + 1)

/* User defined registers */
/* <<--regs-->> */
#define MOTION_MOTION_MVFS_REG 0x4c
#define MOTION_MOTION_RDBFR_REG 0x48
#define MOTION_MOTION_N_REG 0x44
#define MOTION_MOTION_PWM_REG 0x40


static int validate_buf(token_t *out, token_t *gold)
{
	int i;
	int j;
	unsigned errors = 0;

	printf("\n----------Results:---------\n");
	for (i = 0; i < motion_n; i++)
	{
		printf("\nBatch %d:\n", i);
		for (j = 0; j < motion_mvfs+motion_pwm; j++)
		{
			printf("%d    -    gold = %d     out = %d\n", j, gold[i * out_words_adj + j], out[i * out_words_adj + j]);
			if (gold[i * out_words_adj + j] != out[i * out_words_adj + j])
				errors++;
		}
	}

	//printf("\n\nTotal Software Execution Time: ");
	//print_time_us(total_time_sw);
    //
	//printf("\nSingle Software Execution Time: ");
	//print_time_us(total_time_sw/motion_n);
    //
	//printf("\n\nTotal Hardware Execution Time: ");
	//print_time_us(total_time_hw);
    //
	//printf("\nSingle Hardware Execution Time: ");
	//print_time_us(total_time_hw/motion_n);

	printf("\n\n");

	return errors;
}


static void init_buf (token_t *in, token_t * gold)
{
	int i;
	int j;

	for (i = 0; i < motion_n; i++)
		for (j = 0; j < motion_rdbfr+motion_pwm+motion_mvfs; j++)
		{
			if(j<motion_rdbfr)
				in[i * in_words_adj + j] = (token_t) inRdbfr[4*j] | (token_t) inRdbfr[4*j + 1]<<8 | (token_t) inRdbfr[4*j + 2]<<16 | (token_t) inRdbfr[4*j + 3]<<24;
			else if (j<motion_rdbfr + motion_mvfs)
				in[i * in_words_adj + j] = (token_t) inmvfs[(j-motion_rdbfr)/2][(j-motion_rdbfr)%2];
			else
				in[i * in_words_adj + j] = (token_t) inPMV[(j-motion_rdbfr-motion_mvfs)/(2*2)][((j-motion_rdbfr-motion_mvfs)%(2*2))/2][((j-motion_rdbfr-motion_mvfs)%(2))];
		if(i==0)
			printf("iter:%d    -    %d: in=%08x\n", i, j, (int) in[i * in_words_adj + j] );
		}

    //Time measurement for software execution
	start_time = custom_gettime_nano();

	for (i = 0; i < motion_n; i++)
        motion_main_sw((int *)&in[i*in_words_adj], (int *)&gold[i*out_words_adj]);

	end_time = custom_gettime_nano();
	total_time_sw = end_time-start_time;

}


int main(int argc, char * argv[])
{
	int i;
	int n;
	int ndev;
	struct esp_device *espdevs;
	struct esp_device *dev;
	unsigned done;
	unsigned **ptable;
	token_t *mem;
	token_t *gold;
	unsigned errors = 0;
	unsigned coherence;

	if (DMA_WORD_PER_BEAT(sizeof(token_t)) == 0) {
		in_words_adj = motion_rdbfr+motion_pwm+motion_mvfs;
		out_words_adj = motion_pwm+motion_mvfs;
	} else {
		in_words_adj = round_up(motion_rdbfr+motion_pwm+motion_mvfs, DMA_WORD_PER_BEAT(sizeof(token_t)));
		out_words_adj = round_up(motion_pwm+motion_mvfs, DMA_WORD_PER_BEAT(sizeof(token_t)));
	}
	in_len = in_words_adj * (motion_n);
	out_len = out_words_adj * (motion_n);
	in_size = in_len * sizeof(token_t);
	out_size = out_len * sizeof(token_t);
	out_offset  = in_len;
	mem_size = (out_offset * sizeof(token_t)) + out_size;


	// Search for the device
	printf("Scanning device tree... \n");

	ndev = probe(&espdevs, VENDOR_SLD, SLD_MOTION, DEV_NAME);
	if (ndev == 0) {
		printf("motion not found\n");
		return 0;
	}

	for (n = 0; n < ndev; n++) {

		printf("**************** %s.%d ****************\n", DEV_NAME, n);

		dev = &espdevs[n];

		// Check DMA capabilities
		if (ioread32(dev, PT_NCHUNK_MAX_REG) == 0) {
			printf("  -> scatter-gather DMA is disabled. Abort.\n");
			return 0;
		}

		if (ioread32(dev, PT_NCHUNK_MAX_REG) < NCHUNK(mem_size)) {
			printf("  -> Not enough TLB entries available. Abort.\n");
			return 0;
		}

		// Allocate memory
		gold = aligned_malloc(out_size);
		mem = aligned_malloc(mem_size);
		printf("  memory buffer base-address = %p\n", mem);

		// Alocate and populate page table
		ptable = aligned_malloc(NCHUNK(mem_size) * sizeof(unsigned *));
		for (i = 0; i < NCHUNK(mem_size); i++)
			ptable[i] = (unsigned *) &mem[i * (CHUNK_SIZE / sizeof(token_t))];

		printf("  ptable = %p\n", ptable);
		printf("  nchunk = %lu\n", NCHUNK(mem_size));

#ifndef __riscv
		for (coherence = ACC_COH_NONE; coherence <= ACC_COH_RECALL; coherence++) {
#else
		{
			/* TODO: Restore full test once ESP caches are integrated */
			coherence = ACC_COH_NONE;
#endif
			printf("  --------------------\n");
			printf("  Generate input...\n");
			init_buf(mem, gold);

			// Pass common configuration parameters

			iowrite32(dev, SELECT_REG, ioread32(dev, DEVID_REG));
			iowrite32(dev, COHERENCE_REG, coherence);

#ifndef __sparc
			iowrite32(dev, PT_ADDRESS_REG, (unsigned long long) ptable);
#else
			iowrite32(dev, PT_ADDRESS_REG, (unsigned) ptable);
#endif
			iowrite32(dev, PT_NCHUNK_REG, NCHUNK(mem_size));
			iowrite32(dev, PT_SHIFT_REG, CHUNK_SHIFT);

			// Use the following if input and output data are not allocated at the default offsets
			iowrite32(dev, SRC_OFFSET_REG, 0x0);
			iowrite32(dev, DST_OFFSET_REG, 0x0);

			// Pass accelerator-specific configuration parameters
			/* <<--regs-config-->> */
		iowrite32(dev, MOTION_MOTION_MVFS_REG, motion_mvfs);
		iowrite32(dev, MOTION_MOTION_RDBFR_REG, motion_rdbfr);
		iowrite32(dev, MOTION_MOTION_N_REG, motion_n);
		iowrite32(dev, MOTION_MOTION_PWM_REG, motion_pwm);

			// Flush (customize coherence model here)
			esp_flush(coherence);

			//Three measurements for each bench
			for(int m = 0; m<3; m++)
			{
				volatile uint32_t * noc_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 0)*4 + 128);
				volatile uint32_t * acc_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 1)*4 + 128);
				volatile uint32_t * cpu_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);

				if (m==0)
				{
					*noc_freq = 19;
					*acc_freq = 1;
					*cpu_freq = 9;
				}
				else if (m==1)
				{
					*noc_freq = 19;
					*acc_freq = 9;
					*cpu_freq = 9;
				}
				else if (m==2)
				{
					*noc_freq = 1;
					*acc_freq = 9;
					*cpu_freq = 9;
				}
				// Start accelerators
				printf("  Start...\n");

				//Time measurement for software execution
				start_time = custom_gettime_nano();

				iowrite32(dev, CMD_REG, CMD_MASK_START);

				// Wait for completion
				done = 0;
				while (!done) {
					done = ioread32(dev, STATUS_REG);
					done &= STATUS_MASK_DONE;
				}
				iowrite32(dev, CMD_REG, 0x0);

				end_time = custom_gettime_nano();
				total_time_hw[n*3+m] = end_time-start_time;
			}
			printf("  Done\n");
			printf("  validating...\n");

			/* Validation */
			errors = validate_buf(&mem[out_offset], gold);
			if (errors)
				printf("  ... FAIL\n");
			else
				printf("  ... PASS\n");
		}
		for(int cnt = 0; cnt < 6; cnt++)
		{
			print_time_us(total_time_hw[cnt]/(motion_n));
			printf("\n");
		}
		aligned_free(ptable);
		aligned_free(mem);
		aligned_free(gold);
	}

	return 0;
}
