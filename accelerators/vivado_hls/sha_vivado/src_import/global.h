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
/* NIST Secure Hash Algorithm */
/* heavily modified by Uwe Hollerbach uh@alumni.caltech edu */
/* from Peter C. Gutmann's implementation as found in */
/* Applied Cryptography by Bruce Schneier */

/* NIST's proposed modification to SHA of 7/11/94 may be */
/* activated by defining USE_MODIFIED_SHA */

#include "sha.h"

void sha_main_hw (BYTE indata[VSIZE*BLOCK_SIZE], BYTE digest_out[20]);

void sha_main_sw (BYTE indata[VSIZE*BLOCK_SIZE], BYTE digest_out[20]);

