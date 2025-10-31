/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^/
<                                                                        >
<	DISCLAIMER: Politecnico di Milano                                    >
<	                                                                     >
<	Modified version from original CHStone sources at:                   >
<   https://github.com/A-T-Kristensen/patmos_HLS                         >
<                                                                        >
<	AUTHORS: Gabriele Montanaro and Davide Zoni                          >
<                                                                        >
<	E-MAIL: gabriele.montanaro@polimi.it - davide.zoni@polimi.it         >
<                                                                        >
/^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
/*
+--------------------------------------------------------------------------+
| CHStone : a suite of benchmark programs for C-based High-Level Synthesis |
| ======================================================================== |
|                                                                          |
| * Collected and Modified : Y. Hara, H. Tomiyama, S. Honda,               |
|                            H. Takada and K. Ishii                        |
|                            Nagoya University, Japan                      |
|                                                                          |
| * Remark :                                                               |
|    1. This source code is modified to unify the formats of the benchmark |
|       programs in CHStone.                                               |
|    2. Test vectors are added for CHStone.                                |
|    3. If "main_result" is 0 at the end of the program, the program is    |
|       correctly executed.                                                |
|    4. Please follow the copyright of each benchmark program.             |
+--------------------------------------------------------------------------+
*/
/* aes.c */
/*
 * Copyright (C) 2005
 * Akira Iwata & Masayuki Sato
 * Akira Iwata Laboratory,
 * Nagoya Institute of Technology in Japan.
 *
 * All rights reserved.
 *
 * This software is written by Masayuki Sato.
 * And if you want to contact us, send an email to Kimitake Wakayama
 * (wakayama@elcom.nitech.ac.jp)
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. All advertising materials mentioning features or use of this software must
 *    display the following acknowledgment:
 *    "This product includes software developed by Akira Iwata Laboratory,
 *    Nagoya Institute of Technology in Japan (http://mars.elcom.nitech.ac.jp/)."
 *
 * 4. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by Akira Iwata Laboratory,
 *     Nagoya Institute of Technology in Japan (http://mars.elcom.nitech.ac.jp/)."
 *
 *   THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.
 *   AKIRA IWATA LABORATORY DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
 *   SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS,
 *   IN NO EVENT SHALL AKIRA IWATA LABORATORY BE LIABLE FOR ANY SPECIAL,
 *   INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING
 *   FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 *   NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN CONNECTION
 *   WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
#include "aes_global.h"
#include <stdio.h>

const int out_dec_statemt[16] =
    { 0x32, 0x43, 0xf6, 0xa8, 0x88, 0x5a, 0x30, 0x8d, 0x31, 0x31, 0x98, 0xa2,
    0xe0, 0x37, 0x7, 0x34
  };

int main ()
{
	int i=0;
	int statemt_hw[32], statemt_out_hw[32];
	int key_hw[32];
	int statemt_sw[32], statemt_out_sw[32];
	int key_sw[32];
	int statemt[32];
	int key[32];
	int main_result;

	/*statemt[0] = 50;
	statemt[1] = 67;
	statemt[2] = 246;
	statemt[3] = 168;
	statemt[4] = 136;
	statemt[5] = 90;
	statemt[6] = 48;
	statemt[7] = 141;
	statemt[8] = 49;
	statemt[9] = 49;
	statemt[10] = 152;
	statemt[11] = 162;
	statemt[12] = 224;
	statemt[13] = 55;
	statemt[14] = 7;
	statemt[15] = 52;

	key[0] = 43;
	key[1] = 126;
	key[2] = 21;
	key[3] = 22;
	key[4] = 40;
	key[5] = 174;
	key[6] = 210;
	key[7] = 166;
	key[8] = 171;
	key[9] = 247;
	key[10] = 21;
	key[11] = 136;
	key[12] = 9;
	key[13] = 207;
	key[14] = 79;
	key[15] = 60;*/

	for(i=0; i<32; i++)
	{
		key[i] = (i*47 + 78)%255;
		statemt[i] = (i*89 + 77)%255;
	}

	int type = 256256;

	main_result = 0;

	for(i=0; i<32; i++)
    {
	  statemt_sw[i] = statemt[i];
	  key_sw[i] = key[i];
	  statemt_hw[i] = statemt[i];
	  key_hw[i] = key[i];
    }

	aes_main_hw (statemt_hw, key_hw, type);
	aes_main_sw (statemt_sw, key_sw, type);

	for(i=0; i<32; i++)
	{
		printf("%d:    SW=%d    HW=%d\n", i, statemt_sw[i], statemt_hw[i]);
		if(statemt_hw[i] != statemt_sw[i])
		{
			printf("Error at line %d\n", i);
			main_result = 1;
		}
	}

	if(main_result == 0)
		printf ("\nSUCCESS!!!\n");
	else
		printf ("\nFAIL\n");
	return main_result;
}
