/* Copyright (c) 2011-2023 Columbia University, System Level Design Group */
/* SPDX-License-Identifier: Apache-2.0 */

#include <stdio.h>
#ifndef __riscv
#include <stdlib.h>
#endif

#include "esp_accelerator.h"
#include "esp_probe.h"
#include "fixed_point.h"

#include "soc_defs.h"

//-----------------USER'S DEFINES---------------------
#define N_ACC_TYPES 13    //Number of accelerator types (11 CHStone benchmarks available + AES RTL + SHA3 RTL)
#define N_TILES SOC_NTILES //(N_ACC_TILES+3)  //Number of tiles (accelerator tiles + one tile for CPU, IO and mem respectively)
#define N_ACC_TILES SOC_NACC //(N_TILES-4)    //Number of tiles containing an accelerator (SoC-specific)

#define NOC_TH 80000        //High threshold for NoC policy
#define NOC_TL 50000        //Low threshold for NoC policy
#define TIME_WINDOW 100000  //Time window for NoC policy (in us)

#define CLOCK_PERIOD 20   //Clock period of the timer (20MHz)
#define MAX_TEST_TIME 10  //Total duration of the test (in s)

//#define N_SAMPLES N_TESTS*(MAX_TEST_TIME*1000000/TIME_WINDOW) // + 1000) //Number of samples to be collected (its the number of time windows plus an offset to let the accelerators finish)

#define FREQ_MAX 19  //100MHz
#define FREQ_MIN 1   //10MHz
#define FREQ_START 9 //50MHz

#define PRINT_CHUNK 1000 //The terminal shows only 1000 lines
//----------------------------------------------------

#define ACC_BASEADDR 0x60010000       //The address at which the accelerator 0 is stored
#define ACC_DEVID_OFFSET 0xc          //The offset at which the device id of the accelerator is stored
#define ACC_ADDR_INC 0x100            //The increment between accelerators

/* Size of the contiguous chunks for scatter/gather */
#define CHUNK_SHIFT 20
#define CHUNK_SIZE BIT(CHUNK_SHIFT)
#define NCHUNK(_sz) ((_sz % CHUNK_SIZE == 0) ?		\
			(_sz / CHUNK_SIZE) :		\
			(_sz / CHUNK_SIZE) + 1)

typedef int32_t token_adpcm_t;
typedef int32_t token_aes_t;
typedef int8_t token_blowfish_t;
typedef int64_t token_dfadd_t;
typedef int64_t token_dfdiv_t;
typedef int64_t token_dfmul_t;
typedef int64_t token_dfsin_t;
typedef int16_t token_gsm_t;
typedef int32_t token_mips_t;
typedef int32_t token_motion_t;
typedef int8_t token_sha_t;

typedef int64_t token_aes256_t;
typedef int64_t token_sha3_t;

//---------------ADPCM-----------------------
#define SLD_ADPCM 0x300
#define DEV_NAME_ADPCM "sld,adpcm_vivado"

/* <<--params-->> */
extern const int32_t adpcm_n;
extern const int32_t adpcm_size;

/* User defined registers */
/* <<--regs-->> */
#define ADPCM_ADPCM_N_REG 0x44
#define ADPCM_ADPCM_SIZE_REG 0x40


//---------------AES-------------------------
#define SLD_AES 0x301
#define DEV_NAME_AES "sld,aes_vivado"

/* <<--params-->> */
extern const int32_t aes_key;
extern const int32_t aes_n;
extern const int32_t aes_text;

/* User defined registers */
/* <<--regs-->> */
#define AES_AES_KEY_REG 0x48
#define AES_AES_N_REG 0x44
#define AES_AES_TEXT_REG 0x40


//---------------BLOWFISH--------------------
#define SLD_BLOWFISH 0x302
#define DEV_NAME_BLOWFISH "sld,blowfish_vivado"

/* <<--params-->> */
extern const int32_t blowfish_n;
extern const int32_t blowfish_size;

/* User defined registers */
/* <<--regs-->> */
#define BLOWFISH_BLOWFISH_N_REG 0x44
#define BLOWFISH_BLOWFISH_SIZE_REG 0x40


//---------------DFADD-----------------------
#define SLD_DFADD 0x303
#define DEV_NAME_DFADD "sld,dfadd_vivado"

/* <<--params-->> */
extern const int32_t dfadd_out;
extern const int32_t dfadd_in;
extern const int32_t dfadd_n;

/* User defined registers */
/* <<--regs-->> */
#define DFADD_DFADD_OUT_REG 0x48
#define DFADD_DFADD_IN_REG 0x44
#define DFADD_DFADD_N_REG 0x40

//---------------DFDIV---------------------
#define SLD_DFDIV 0x304
#define DEV_NAME_DFDIV "sld,dfdiv_vivado"

/* <<--params-->> */
extern const int32_t dfdiv_n;
extern const int32_t dfdiv_in;
extern const int32_t dfdiv_out;

/* User defined registers */
/* <<--regs-->> */
#define DFDIV_DFDIV_N_REG 0x48
#define DFDIV_DFDIV_IN_REG 0x44
#define DFDIV_DFDIV_OUT_REG 0x40

//---------------DFMUL---------------------
#define SLD_DFMUL 0x305
#define DEV_NAME_DFMUL "sld,dfmul_vivado"

/* <<--params-->> */
extern const int32_t dfmul_out;
extern const int32_t dfmul_n;
extern const int32_t dfmul_in;

/* User defined registers */
/* <<--regs-->> */
#define DFMUL_DFMUL_OUT_REG 0x48
#define DFMUL_DFMUL_N_REG 0x44
#define DFMUL_DFMUL_IN_REG 0x40


//---------------DFSIN---------------------
#define SLD_DFSIN 0x306
#define DEV_NAME_DFSIN "sld,dfsin_vivado"

/* <<--params-->> */
extern const int32_t dfsin_in;
extern const int32_t dfsin_out;
extern const int32_t dfsin_n;

/* User defined registers */
/* <<--regs-->> */
#define DFSIN_DFSIN_IN_REG 0x48
#define DFSIN_DFSIN_OUT_REG 0x44
#define DFSIN_DFSIN_N_REG 0x40


//---------------GSM-----------------------
#define SLD_GSM 0x307
#define DEV_NAME_GSM "sld,gsm_vivado"

/* <<--params-->> */
extern const int32_t gsm_mlen;
extern const int32_t gsm_nlen;
extern const int32_t gsm_n;

/* User defined registers */
/* <<--regs-->> */
#define GSM_GSM_MLEN_REG 0x48
#define GSM_GSM_NLEN_REG 0x44
#define GSM_GSM_N_REG 0x40


//---------------MIPS----------------------
#define SLD_MIPS 0x308
#define DEV_NAME_MIPS "sld,mips_vivado"

/* <<--params-->> */
extern const int32_t mips_in;
extern const int32_t mips_n;
extern const int32_t mips_out;

/* User defined registers */
/* <<--regs-->> */
#define MIPS_MIPS_IN_REG 0x48
#define MIPS_MIPS_N_REG 0x44
#define MIPS_MIPS_OUT_REG 0x40


//---------------MOTION--------------------
#define SLD_MOTION 0x30a
#define DEV_NAME_MOTION "sld,motion_vivado"

/* <<--params-->> */
extern const int32_t motion_mvfs;
extern const int32_t motion_rdbfr;
extern const int32_t motion_n;
extern const int32_t motion_pwm;

/* User defined registers */
/* <<--regs-->> */
#define MOTION_MOTION_MVFS_REG 0x4c
#define MOTION_MOTION_RDBFR_REG 0x48
#define MOTION_MOTION_N_REG 0x44
#define MOTION_MOTION_PWM_REG 0x40


//---------------SHA-----------------------
#define SLD_SHA 0x309
#define DEV_NAME_SHA "sld,sha_vivado"

/* <<--params-->> */
extern const int32_t sha_vsize;
extern const int32_t sha_blocksize;
extern const int32_t sha_digest;
extern const int32_t sha_n;

/* User defined registers */
/* <<--regs-->> */
#define SHA_SHA_VSIZE_REG 0x4c
#define SHA_SHA_BLOCKSIZE_REG 0x48
#define SHA_SHA_DIGEST_REG 0x44
#define SHA_SHA_N_REG 0x40


//---------------AES256--------------------
#define SLD_AES256 0x312
#define DEV_NAME_AES256 "sld,aes256_rtl"

extern const int32_t aes256_n;
extern const int32_t aes256_keyWords;
extern const int32_t aes256_blockWords;
extern const int32_t aes256_keyReg0;
extern const int32_t aes256_keyReg1;
extern const int32_t aes256_keyReg2;
extern const int32_t aes256_keyReg3;
extern const int32_t aes256_keyReg4;
extern const int32_t aes256_keyReg5;
extern const int32_t aes256_keyReg6;
extern const int32_t aes256_keyReg7;


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


//----------SHA3-------------------
#define SLD_SHA3 0x311
#define DEV_NAME_SHA3 "sld,sha3_rtl"

/* <<--params-->> */
extern const int32_t sha3_message_len;
extern const int32_t sha3_n;
extern const int32_t sha3_hash_len;

/* User defined registers */
/* <<--regs-->> */
#define SHA3_SHA3_MESSAGE_LEN_REG 0x48
#define SHA3_SHA3_N_REG 0x44
#define SHA3_SHA3_HASH_LEN_REG 0x40


extern const int32_t sizeof_token[N_ACC_TYPES];
extern const int32_t batch_bytes[N_ACC_TYPES];

int search_dev(struct esp_device ** espdevs, int acc_type);
void init_buf_all(uint8_t *in, uint8_t *out, unsigned in_words_adj, unsigned acc_type);
void init_size_all(unsigned *in_words_adj, unsigned * out_words_adj, unsigned * in_len, unsigned * out_len, unsigned * in_size, unsigned * out_size, unsigned * out_offset, unsigned * mem_size, int acc_type);
void config_acc_param(struct esp_device *dev, int acc_type);
void get_batch_size(unsigned *acc_batch_size, int acc_type);
uint8_t get_index_from_address(uint32_t address);
int print_results(int acc_type, uint8_t *gold_in, uint8_t *out_in, unsigned out_words_adj, uint8_t *input_in);




#define N_DFMUL 20
typedef unsigned int float32;
typedef unsigned long long float64;

extern const float64 a_input[N_DFMUL];

extern const float64 b_input[N_DFMUL];

extern const float64 z_output[N_DFMUL];




#define N_DFSIN 36
extern const float64 test_in[N_DFSIN];				/* 35PI/18 */

extern const float64 test_out[N_DFSIN];				/* -0.173649 */

#define N_GSM 160
extern const short inData_gsm[N_GSM];



extern const int A[8];
extern const int outData[8];





#define N_MOTION 2048

extern const unsigned char inRdbfr[N_MOTION];
extern const int inmvfs[2][2];
extern const int inPMV[2][2][2];


extern const int outPMV[2][2][2];
extern const int outmvfs[2][2];




#define SHA_BLOCKSIZE		64

#define BLOCK_SIZE 8192
#define VSIZE 2
#define DIGEST_SIZE 5

typedef unsigned char BYTE;
typedef unsigned int INT32;

extern BYTE indata[VSIZE*BLOCK_SIZE];
extern int in_i[VSIZE];

extern const INT32 outData_SHA[5];



extern const token_aes256_t aes256_data_in[20];
extern const token_aes256_t aes256_data_out[20];



#define SHA3_WORDSIZE 64
#define SHA3_HASH_LENGTH 256
#define SHA3_MESSAGE_LENGTH 8248

#define SHA3_MESSAGE_BYTES (((SHA3_MESSAGE_LENGTH - 1) / 8) + 1)
#define SHA3_MESSAGE_WORDS (((SHA3_MESSAGE_LENGTH - 1) / SHA3_WORDSIZE) + 1)
#define SHA3_HASH_WORDS (((SHA3_HASH_LENGTH - 1) / SHA3_WORDSIZE) + 1)

#define SHA3_RATE_LENGTH (1600-2*SHA3_HASH_LENGTH)

#define SHA3_MESSAGE_N_RATE (((SHA3_MESSAGE_LENGTH - 1) / SHA3_RATE_LENGTH) + 1)
#define SHA3_MESSAGE_PADDED_LENGTH (SHA3_MESSAGE_N_RATE*SHA3_RATE_LENGTH)
#define SHA3_MESSAGE_PADDED_WORDS (((SHA3_MESSAGE_PADDED_LENGTH - 1) / SHA3_WORDSIZE) + 1)

extern token_sha3_t sha3_data_in[SHA3_MESSAGE_WORDS];

extern token_sha3_t data_out[SHA3_HASH_WORDS];
