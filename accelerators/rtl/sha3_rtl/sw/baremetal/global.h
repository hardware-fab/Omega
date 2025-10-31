/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^/
<                                                                        >
<	DISCLAIMER: Politecnico di Milano                                    >
<	                                                                     >
<	Header file for SHA-3 software benchmark                             >
<                                                                        >
<	AUTHORS: Gabriele Montanaro and Davide Zoni                          >
<                                                                        >
<	E-MAIL: gabriele.montanaro@polimi.it - davide.zoni@polimi.it         >
<                                                                        >
/^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/

#include "sha3_sw.h"

#define WORDSIZE 64
#define HASH_LENGTH 256
#define MESSAGE_LENGTH 8248

#define MESSAGE_BYTES (((MESSAGE_LENGTH - 1) / 8) + 1)
#define MESSAGE_WORDS (((MESSAGE_LENGTH - 1) / WORDSIZE) + 1)
#define HASH_WORDS (((HASH_LENGTH - 1) / WORDSIZE) + 1)

#define RATE_LENGTH (1600-2*HASH_LENGTH)

#define MESSAGE_N_RATE (((MESSAGE_LENGTH - 1) / RATE_LENGTH) + 1)
#define MESSAGE_PADDED_LENGTH (MESSAGE_N_RATE*RATE_LENGTH)
#define MESSAGE_PADDED_WORDS (((MESSAGE_PADDED_LENGTH - 1) / WORDSIZE) + 1)

#if HASH_LENGTH == 256
#define    sha3_main_sw sha3_256
#elif HASH_LENGTH == 384
#define    sha3_main_sw sha3_384
#elif HASH_LENGTH == 512
#define    sha3_main_sw sha3_512
#endif


