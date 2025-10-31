// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include "../inc/espacc_config.h"
#include "../inc/espacc.h"
#include "../../src_import/global.h"
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

const int A[8] = { 22, 5, -9, 3, -17, 38, 0, 11 };
const int outData[8] = { -17, -9, 0, 3, 5, 11, 22, 38 };

int main(int argc, char **argv) {

    printf("****start*****\n");

    /* <<--params-->> */
	 const unsigned mips_in = 8;
	 const unsigned mips_n = 100;
	 const unsigned mips_out = 8;

    uint32_t in_words_adj;
    uint32_t out_words_adj;
    uint32_t in_size;
    uint32_t out_size;
    uint32_t dma_in_size;
    uint32_t dma_out_size;
    uint32_t dma_size;


    in_words_adj = round_up(mips_in, VALUES_PER_WORD);
    out_words_adj = round_up(mips_out, VALUES_PER_WORD);
    in_size = in_words_adj * (mips_n);
    out_size = out_words_adj * (mips_n);

    dma_in_size = in_size / VALUES_PER_WORD;
    dma_out_size = out_size / VALUES_PER_WORD;
    dma_size = dma_in_size + dma_out_size;

    dma_word_t *mem=(dma_word_t*) malloc(dma_size * sizeof(dma_word_t));
    word_t *inbuff=(word_t*) malloc(in_size * sizeof(word_t));
    word_t *outbuff=(word_t*) malloc(out_size * sizeof(word_t));
    word_t *outbuff_gold= (word_t*) malloc(out_size * sizeof(word_t));
    dma_info_t load;
    dma_info_t store;

    // Prepare input data
    for(unsigned i = 0; i < mips_n; i++)
        for(unsigned j = 0; j < mips_in; j++)
        {
            inbuff[i * in_words_adj + j] = (word_t) A[j];
            printf("iter:%d    -    %d: in=%d\n", i, j, (int) inbuff[i * in_words_adj + j] );
        }

    for(unsigned i = 0; i < dma_in_size; i++)
	for(unsigned k = 0; k < VALUES_PER_WORD; k++)
	    mem[i].word[k] = inbuff[i * VALUES_PER_WORD + k];

    // Set golden output
    for (unsigned i = 0; i < mips_n; i++)
        mips_main_sw((int *)&inbuff[i*in_words_adj], (int *)&outbuff_gold[i*out_words_adj]);


    // Call the TOP function
    top(mem, mem,
        /* <<--args-->> */
	 	 mips_in,
	 	 mips_n,
	 	 mips_out,
        load, store);

    // Validate
    uint32_t out_offset = dma_in_size;
    for(unsigned i = 0; i < dma_out_size; i++)
	for(unsigned k = 0; k < VALUES_PER_WORD; k++)
	    outbuff[i * VALUES_PER_WORD + k] = mem[out_offset + i].word[k];

    int errors = 0;
    for(unsigned i = 0; i < mips_n; i++)
        for(unsigned j = 0; j < mips_out; j++)
	    {
            if (outbuff[i * out_words_adj + j] != outbuff_gold[i * out_words_adj + j])
		        errors++;
            printf("iter:%d    -    %d: dut=%d gold=%d \n", i, j, (int) outbuff[i * out_words_adj + j], (int) outbuff_gold[i * out_words_adj + j]);
        }
    if (errors)
	std::cout << "Test FAILED with " << errors << " errors." << std::endl;
    else
	std::cout << "Test PASSED." << std::endl;

    // Free memory

    free(mem);
    free(inbuff);
    free(outbuff);
    free(outbuff_gold);

    return 0;
}
