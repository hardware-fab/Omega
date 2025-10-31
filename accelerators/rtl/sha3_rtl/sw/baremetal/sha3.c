/* Copyright (c) 2011-2023 Columbia University, System Level Design Group */
/* SPDX-License-Identifier: Apache-2.0 */

#include <stdio.h>
#ifndef __riscv
#include <stdlib.h>
#endif

#include <esp_accelerator.h>
#include <esp_probe.h>
#include <fixed_point.h>

#include "global.h"

typedef int64_t token_t;

static unsigned DMA_WORD_PER_BEAT(unsigned _st)
{
        return (sizeof(void *) / _st);
}


#define SLD_SHA3 0x311
#define DEV_NAME "sld,sha3_rtl"

/* <<--params-->> */
const int32_t sha3_message_len = MESSAGE_PADDED_WORDS;
const int32_t sha3_n = 12;
const int32_t sha3_hash_len = HASH_WORDS;

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
#define SHA3_SHA3_MESSAGE_LEN_REG 0x48
#define SHA3_SHA3_N_REG 0x44
#define SHA3_SHA3_HASH_LEN_REG 0x40

#define BASE_ADDRESS 0x60000300
#define TIMER_LO 0xB4
#define TIMER_HI 0xB8

#define CLOCK_PERIOD 20

static double start_time, end_time, total_time_sw;
static double total_time_hw;

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
	printf("Original Value = %lu : %u s - %u ms - %u us - %u ns", value, sec, milli, micro, nano);
}

static void print_time_us(long unsigned value)
{
	uint32_t decimal = value%1000;
	uint32_t integer = (value)/1000;
	printf("%u,%03u", integer, decimal);
}

token_t data_in[MESSAGE_WORDS] = {0xce58d9e6e4b81902, 0x161c881599ff1800, 0x5ac10c53199450d0, 0xbbcfa60a82528950, 0xaa62378f1a509130, 0x6c1a4605195e0573, 0x1f12c738a6170961, 0xe6af6b6801f5b9ab, 0x57f03a7240cca2ac, 0xe6e8b1ff46b77365, 0xc93a9e6f51a7d037, 0x563ca05731590288, 0x493dfa89099d35ef, 0x85e6eecc9d613166, 0x9bcfd5ec76a624cc, 0xe2c423131d269b66, 0x6396ef6c33245bb8, 0x0a4984a8abb60e46, 0x85e433fc8a57c86c, 0x1bec7f38121a9e75, 0xb08de1e3b13c9cbb, 0x85206330d672775c, 0x56aa58e001204c1c, 0x0ccb541ee5f29396, 0x7f747930b015eb36, 0x364f660cc1dd6817, 0x87c0f788e143a4ed, 0x0ef80cf3ea9f8969, 0x140399c41885fa4e, 0xd4615b953ec3acc6, 0x84a34e65e6f352f4, 0xeb5ee7d6fe713f12, 0x74d9d68c5ed1db32, 0x3236c770f973367d, 0x1685e2fc7835f063, 0x93d739914879a3bc, 0x527a49b04b24e27d, 0x5aa9ed531c24d132, 0xa9b32e21e81e847c, 0xf5be0d3e37b1fa89, 0x2b433976671bf3c1, 0xc4e015e004e612ad, 0x9940ce825e53fe53, 0x110b9148bc8cd1e7, 0xcf0a5d372550f8e9, 0x310dc935f3dbe38d, 0x1bb10f79040dcc15, 0x185e5dd5ea2ebcb9, 0x381af05d6ae9469b, 0xf60fd1eaeab47705, 0x65867e6a934b7fab, 0xa9dd80930b3d4c44, 0x573da1c126e85d1c, 0xf72e06e2e27de747, 0x0366b196b131425a, 0x0ec2ed19ff395d56, 0x76ff189ce775b9de, 0xa3bfc0853da8cc40, 0x0e7ed7bfaf1919bd, 0xdb06d6db3f3431b6, 0x3349521abe0bf861, 0xcbb9e60861b3486f, 0x311f2ee038479d14, 0x4d73ef8ca72042da, 0x6a95f428a0ed8a6b, 0xa670730723bc7654, 0xdba43414ebd12838, 0x4517c4ec3707c7a1, 0x9cbbca3ca854a84e, 0xc41b55e8d7cb3cb3, 0x6f71c75a42ef9287, 0x0657743d5e3bdffa, 0xf6a9369ffddeedc1, 0xfa43a9d10ee6847e, 0x574bd8993a6b2140, 0xc2957e20d05d1ac6, 0x065065032f53c429, 0x966efaa4547f22ab, 0xcafb440566654528, 0xfac348ca20629126, 0xb2f629e149ee0adf, 0x5c0584b084a65b4e, 0xa19f530705992fff, 0x5c77ca7dd95ba38c, 0x51cd6d9bbb787a17, 0x7dfec701a5224f46, 0xc1a34ec63c7dc698, 0xf59015ceebb95a3c, 0x86c8d741405258bd, 0x501fbef5410d3c02, 0xb08ac9ec078f85fc, 0x1f9acb0a532546d9, 0xed1e1a2d7072eac0, 0x91a8b6d2b6f2d566, 0x7c9e53832dd8804c, 0x724b56c6709c9f5e, 0xbaba8b2a2c76ebbe, 0x1ea190d493653b0f, 0x038e923066127cd8, 0x5dd29ece6f3e2c29, 0xf8b754242d3fe24c, 0xe0732073d85b82dc, 0xe9140c4f27892884, 0x5bc652ca047ef4fc, 0x364821638703af67, 0x76d0da4f2b5c2b15, 0x70376497c08c1c1c, 0x536ee657edda5423, 0x227586a9783610ef, 0x06ea3e31466946b7, 0xa0ab4e61376a7d8a, 0xd963e2c63e36e960, 0xab6f0a23a51a12ab, 0x0550dd4bb923025a, 0xce51bb06bb389094, 0x9b725ad9a8433a53, 0xb34477585e890463, 0xdae1af9304b1edd3, 0x02a8d9bee069527c, 0xdcad5584f08fd8a3, 0xd34ffc32d80095b2, 0xe14446e5f633b8f8, 0xdc91b6bcfb0938d7, 0xb68e5ba61d334af1, 0x8246235b46b80d27, 0xfd530cf387c5eb63, 0x56a21f51ab582861, 0xe6840703b751f43a, 0x00971795ddd0a204};

token_t data_out[HASH_WORDS] = {0xef7a77336049498f, 0x7b89dd370f713e1e, 0xca85a00003cb2e92, 0x243842db6b0a4d7c};


static int validate_buf(token_t *out, token_t *gold)
{
	int i;
	int j;
	unsigned errors = 0;

	printf("\n----------Results:---------\n");
	for (i = 0; i < sha3_n; i++)
		//if(i==0)
		{
			printf("\nBatch %d:\n", i);
			for (j = 0; j < sha3_hash_len; j++)
			{
				printf("%d    -    gold = %016llx     out = %016llx\n",j, gold[i * out_words_adj + j], out[i * out_words_adj + j]);
				if (gold[i * out_words_adj + j] != out[i * out_words_adj + j])
					errors++;
			}
		}
		//else
		//	for (j = 0; j < sha3_hash_len; j++)
		//		if (gold[i * out_words_adj + j] != out[i * out_words_adj + j])
		//			errors++;

	printf("\n\nTotal Software Execution Time: ");
	print_time_us(total_time_sw);

	printf("\nSingle Software Execution Time: ");
	print_time_us(total_time_sw/sha3_n);

	printf("\n\nTotal Hardware Execution Time: ");
	print_time_us(total_time_hw);

	printf("\nSingle Hardware Execution Time: ");
	print_time_us(total_time_hw/sha3_n);

	printf("\n\n");

	return errors;
}


static void init_buf (token_t *in, token_t * gold)
{
	int i;
	int j;

	//printf("MESSAGE_WORDS = %d, MESSAGE_PADDED_WORDS = %d\n", MESSAGE_WORDS, MESSAGE_PADDED_WORDS);
	for (i = 0; i < sha3_n; i++)
		for (j = 0; j < sha3_message_len; j++)
			if(j<MESSAGE_WORDS-1)
				in[i * in_words_adj + j] = data_in[j];
			else if(j==MESSAGE_WORDS-1)
				in[i * in_words_adj + j] = data_in[j] | (token_t) ((token_t)0x6<<(8*(MESSAGE_BYTES%8)));
			else if(j<MESSAGE_PADDED_WORDS-1)
				in[i * in_words_adj + j] = (token_t) 0x0;
			else if(j==MESSAGE_PADDED_WORDS-1)
				in[i * in_words_adj + j] = (token_t) 0x8000000000000000;

	//printf("----------------------INITIAL MESSAGE-----------------------\n");
	//for (i = 0; i<MESSAGE_PADDED_WORDS; i++)
	//{
	//	printf("%d : %016llx\n", i, in[i]);
	//}
	//printf("\n");

	//Time measurement for software execution
	start_time = custom_gettime_nano();

	//for (i = 0; i < sha3_n; i++)
	//	sha3_main_sw((unsigned char *)&in[i*in_words_adj], MESSAGE_PADDED_LENGTH/8, (unsigned char *)&gold[i*out_words_adj]);

	for (i = 0; i < sha3_n; i++)
		for (j = 0; j < sha3_hash_len; j++)
			gold[i * out_words_adj + j] = (token_t) data_out[j];

	end_time = custom_gettime_nano();
	total_time_sw = end_time-start_time;
}


int main(int argc, char * argv[])
{
	printf("Starting main \n");
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
		in_words_adj = sha3_message_len;
		out_words_adj = sha3_hash_len;
	} else {
		in_words_adj = round_up(sha3_message_len, DMA_WORD_PER_BEAT(sizeof(token_t)));
		out_words_adj = round_up(sha3_hash_len, DMA_WORD_PER_BEAT(sizeof(token_t)));
	}
	in_len = in_words_adj * (sha3_n);
	out_len = out_words_adj * (sha3_n);
	in_size = in_len * sizeof(token_t);
	out_size = out_len * sizeof(token_t);
	out_offset  = in_len;
	mem_size = (out_offset * sizeof(token_t)) + out_size;


	// Search for the device
	printf("Scanning device tree... \n");

	ndev = probe(&espdevs, VENDOR_SLD, SLD_SHA3, DEV_NAME);
	if (ndev == 0) {
		printf("sha3 not found\n");
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
		iowrite32(dev, SHA3_SHA3_MESSAGE_LEN_REG, sha3_message_len);
		iowrite32(dev, SHA3_SHA3_N_REG, sha3_n);
		iowrite32(dev, SHA3_SHA3_HASH_LEN_REG, sha3_hash_len);

			// Flush (customize coherence model here)
			esp_flush(coherence);

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
			total_time_hw = end_time-start_time;

			printf("  Done\n");
			printf("  validating...\n");

			/* Validation */
			errors = validate_buf(&mem[out_offset], gold);
			if (errors)
				printf("  ... FAIL\n");
			else
				printf("  ... PASS\n");
		}
		aligned_free(ptable);
		aligned_free(mem);
		aligned_free(gold);
	}

	return 0;
}
