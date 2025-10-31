/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^/
<                                                                        >
< DISCLAIMER: Politecnico di Milano                                      >
<                                                                        >
< Modified version from original CHStone sources at:                     >
<   https://github.com/A-T-Kristensen/patmos_HLS                         >
<                                                                        >
< AUTHORS: Gabriele Montanaro and Davide Zoni                            >
<                                                                        >
< E-MAIL: gabriele.montanaro@polimi.it - davide.zoni@polimi.it           >
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
/*
 * Copyright (C) 2008
 * Y. Hara, H. Tomiyama, S. Honda, H. Takada and K. Ishii
 * Nagoya University, Japan
 * All rights reserved.
 *
 * Disclaimer of Warranty
 *
 * These software programs are available to the user without any license fee or
 * royalty on an "as is" basis. The authors disclaims any and all warranties, 
 * whether express, implied, or statuary, including any implied warranties or 
 * merchantability or of fitness for a particular purpose. In no event shall the
 * copyright-holder be liable for any incidental, punitive, or consequential damages
 * of any kind whatsoever arising from the use of these programs. This disclaimer
 * of warranty extends to the user of these programs and user's customers, employees,
 * agents, transferees, successors, and assigns.
 *
 */
#include <stdio.h>
#include "mips_global.h"
/*
+--------------------------------------------------------------------------+
| * Test Vectors (added for CHStone)                                       |
|     A : input data                                                       |
|     outData : expected output data                                       |
+--------------------------------------------------------------------------+
*/
const int A[8] = { 22, 5, -9, 3, -17, 38, 0, 11 };
const int outData[8] = { -17, -9, 0, 3, 5, 11, 22, 38 };

int
main ()
{
	int main_result = 0;
	int outDut[8], outSW[8];
	int i;

	mips_main_hw (A, outDut);
	mips_main_sw (A, outSW);

	for(i = 0; i<8; i++)
	{
		main_result += (outDut[i] != outSW[i]);
		printf("%d:    expected=%d    output_hw=%d    output_sw=%d\n", i, outData[i], outDut[i], outSW[i]);
	}
	if(main_result == 0)
		printf("\nSUCCESS!!!\n");
	else
		printf("\nFAIL\n");
	return main_result;
}
