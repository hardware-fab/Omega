/* Copyright (c) 2011-2023 Columbia University, System Level Design Group */
/* SPDX-License-Identifier: Apache-2.0 */

#include <stdio.h>
#ifndef __riscv
#include <stdlib.h>
#endif

#include <esp_accelerator.h>
#include <esp_probe.h>
#include <fixed_point.h>

typedef int64_t token_t;

static unsigned DMA_WORD_PER_BEAT(unsigned _st)
{
        return (sizeof(void *) / _st);
}


#define SLD_AES256 0x312
#define DEV_NAME "sld,aes256_rtl"


/* <<--params-->> */
const int32_t aes256_n = 100;
const int32_t aes256_keyWords = 4;
const int32_t aes256_blockWords = 2;
const int32_t aes256_keyReg0 = 0x42de1630;
const int32_t aes256_keyReg1 = 0xda5099b9;
const int32_t aes256_keyReg2 = 0x80c94353;
const int32_t aes256_keyReg3 = 0xf217d04f;
const int32_t aes256_keyReg4 = 0x47f1db4f;
const int32_t aes256_keyReg5 = 0x6dac4d57;
const int32_t aes256_keyReg6 = 0x43a5c762;
const int32_t aes256_keyReg7 = 0xeec25e13;

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

#define BASE_ADDRESS 0x60000300
#define TIMER_LO 0xB4
#define TIMER_HI 0xB8
#define DOMAIN_0 ((16 + 0)*4 + 128)
#define DOMAIN_1 ((16 + 1)*4 + 128)
#define DOMAIN_2 ((16 + 2)*4 + 128)

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

token_t data_in[20]  = {0xb792defe83b94d76, 0xa07444e3190b4586, 0x583d7a9a1b90cbbb, 0xd01ec550e708a4c1, 0x7783d0fa3c1e700d, 0x050f9f1e1ae4a5d2, 0x3e5f3059f0fb15f5, 0x3c355d233d01e596, 0x3bc70a78e57a8521,
                        0x0ab4132598b8f70f, 0x89b47c79af916eba, 0xb0e245ede42a8322, 0x9df7ee837173a421, 0x4582dfdd3ad6ed76, 0x46d816f66985b0ae, 0x55e90f3913925c9d, 0x6fa585e1182a026e, 0x078f8b416578b702,
                        0xdbdae0445f90f266, 0x1311a727a403c4ea};
token_t data_out[20] = {0x1ce62c2358607c05, 0x9a23a49ef1da13e7, 0x11d10e65e69ce318, 0xf043761f673ac081, 0x418d3bf0acda9afa, 0xb8fb8435faba28b7, 0xf76a94b7d0ef12ed, 0xa547b71cf4eb93a2, 0x698932f9a9c1d7a7,
                        0xe9562448a7b51947, 0xda7f38534bb971ef, 0xdf65e64b3cc0c14c, 0x628c011fc883bb6a, 0xbf9cafaddc84ff25, 0x662cad45922b7b7b, 0xd8ec874755c216e1, 0xc5e93f08f6a21172, 0x07d62a4ce3664f42,
                        0xde8100a6ad51dff1, 0xd8601d4dbd159844};

static int validate_buf(token_t *out, token_t *gold)
{
  int i;
  int j;
  unsigned errors = 0;

  printf("\n----------Results:---------\n");
  for (i = 0; i < aes256_n; i++)
  {
    printf("\nBatch %d:\n", i);
    for (j = 0; j < aes256_blockWords; j++)
    {
      printf("%d    -    gold = %016llx     out = %016llx\n",j, gold[i * out_words_adj + j], out[i * out_words_adj + j]);
      if (gold[i * out_words_adj + j] != out[i * out_words_adj + j])
        errors++;
    }
  }

  printf("\n\nTotal Software Execution Time: ");
  print_time_us(total_time_sw);

  printf("\nSingle Software Execution Time: ");
  print_time_us(total_time_sw/aes256_n);

  printf("\n\nTotal Hardware Execution Time: ");
  print_time_us(total_time_hw);

  printf("\nSingle Hardware Execution Time: ");
  print_time_us(total_time_hw/aes256_n);

  printf("\n\n");

  return errors;
}


static void init_buf (token_t *in, token_t * gold)
{
  int i;
  int j;

  for (i = 0; i < aes256_n; i++)
    for (j = 0; j < aes256_blockWords; j++)
      in[i * in_words_adj + j] = (token_t) data_in[(i*aes256_blockWords+j)%20];

  for (i = 0; i < aes256_n; i++)
    for (j = 0; j < aes256_blockWords; j++)
      gold[i * out_words_adj + j] = (token_t) data_out[(i*aes256_blockWords+j)%20];
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

  volatile uint32_t * noc_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + DOMAIN_0);
  volatile uint32_t * cpu_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + DOMAIN_1);
  volatile uint32_t * acc_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + DOMAIN_2);

  *noc_freq_reg = 19;
  *cpu_freq_reg = 9;
  *acc_freq_reg = 9;

  if (DMA_WORD_PER_BEAT(sizeof(token_t)) == 0) {
    in_words_adj = aes256_blockWords;
    out_words_adj = aes256_blockWords;
  } else {
    in_words_adj = round_up(aes256_blockWords, DMA_WORD_PER_BEAT(sizeof(token_t)));
    out_words_adj = round_up(aes256_blockWords, DMA_WORD_PER_BEAT(sizeof(token_t)));
  }
  in_len = in_words_adj * (aes256_n);
  out_len = out_words_adj * (aes256_n);
  in_size = in_len * sizeof(token_t);
  out_size = out_len * sizeof(token_t);
  out_offset  = in_len;
  mem_size = (out_offset * sizeof(token_t)) + out_size;


  // Search for the device
  printf("Scanning device tree... \n");

  ndev = probe(&espdevs, VENDOR_SLD, SLD_AES256, DEV_NAME);
  if (ndev == 0) {
    printf("aes256 not found\n");
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
    iowrite32(dev, AES256_AES256_N_REG, aes256_n);
    iowrite32(dev, AES256_AES256_KEYWORDS_REG, aes256_keyWords);
    iowrite32(dev, AES256_AES256_BLOCKWORDS_REG, aes256_blockWords);
    iowrite32(dev, AES256_AES256_KEYREG0_REG, aes256_keyReg0);
    iowrite32(dev, AES256_AES256_KEYREG1_REG, aes256_keyReg1);
    iowrite32(dev, AES256_AES256_KEYREG2_REG, aes256_keyReg2);
    iowrite32(dev, AES256_AES256_KEYREG3_REG, aes256_keyReg3);
    iowrite32(dev, AES256_AES256_KEYREG4_REG, aes256_keyReg4);
    iowrite32(dev, AES256_AES256_KEYREG5_REG, aes256_keyReg5);
    iowrite32(dev, AES256_AES256_KEYREG6_REG, aes256_keyReg6);
    iowrite32(dev, AES256_AES256_KEYREG7_REG, aes256_keyReg7);

      // Flush (customize coherence model here)
      esp_flush(coherence);

      // Start accelerators
      printf("  Start...\n");
      int n_test = 1000;
      start_time = custom_gettime_nano();
      for (int i=0; i<n_test; i++)
      {
        iowrite32(dev, CMD_REG, CMD_MASK_START);

        // Wait for completion
        done = 0;
        while (!done) {
          done = ioread32(dev, STATUS_REG);
          done &= STATUS_MASK_DONE;
        }
        iowrite32(dev, CMD_REG, 0x0);
      }
      end_time = custom_gettime_nano();
      total_time_hw = (end_time-start_time)/n_test;

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
