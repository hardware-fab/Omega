// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include "../inc/espacc_config.h"
#include "../inc/espacc.h"

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "../../src_import/global.h"

int main(int argc, char **argv) {

    printf("****start*****\n");

    /* <<--params-->> */
	 const unsigned dfdiv_n = 100;
	 const unsigned dfdiv_in = 2;
	 const unsigned dfdiv_out = 1;

    uint32_t in_words_adj;
    uint32_t out_words_adj;
    uint32_t in_size;
    uint32_t out_size;
    uint32_t dma_in_size;
    uint32_t dma_out_size;
    uint32_t dma_size;


    in_words_adj = round_up(dfdiv_in, VALUES_PER_WORD);
    out_words_adj = round_up(dfdiv_out, VALUES_PER_WORD);
    in_size = in_words_adj * (dfdiv_n);
    out_size = out_words_adj * (dfdiv_n);

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
    for(unsigned i = 0; i < dfdiv_n; i++)
        for(unsigned j = 0; j < dfdiv_in; j++)
        {    
            inbuff[i * in_words_adj + j] = (word_t) j*1.78 + i*47.99 + 71.761;
            printf("iter:%d    -    %d: in=%016llx\n", i, j, (float64) inbuff[i * in_words_adj + j] );
        }
    for(unsigned i = 0; i < dma_in_size; i++)
	for(unsigned k = 0; k < VALUES_PER_WORD; k++)
	    mem[i].word[k] = inbuff[i * VALUES_PER_WORD + k];

    // Set golden output
    for (unsigned i = 0; i < dfdiv_n; i++)
        float64_div_sw((float64 *)&inbuff[i*in_words_adj], (float64 *)&outbuff_gold[i*out_words_adj]);


    // Call the TOP function
    top(mem, mem,
        /* <<--args-->> */
	 	 dfdiv_n,
	 	 dfdiv_in,
	 	 dfdiv_out,
        load, store);

    // Validate
    uint32_t out_offset = dma_in_size;
    for(unsigned i = 0; i < dma_out_size; i++)
	for(unsigned k = 0; k < VALUES_PER_WORD; k++)
	    outbuff[i * VALUES_PER_WORD + k] = mem[out_offset + i].word[k];
    
    int errors = 0;
    for(unsigned i = 0; i < dfdiv_n; i++)
        for(unsigned j = 0; j < dfdiv_out; j++)
        {
	        if (outbuff[i * out_words_adj + j] != outbuff_gold[i * out_words_adj + j])
		        errors++;
            printf("iter:%d    -    %d: dut=%016llx gold=%016llx \n", i, j, (float64) outbuff[i * out_words_adj + j], (float64) outbuff_gold[i * out_words_adj + j]);
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
