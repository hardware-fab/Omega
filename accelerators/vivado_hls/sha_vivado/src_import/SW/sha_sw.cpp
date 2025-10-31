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

#include "../sha.h"
#include "../global.h"

/* SHA f()-functions */

#define f1(x,y,z)	((x & y) | (~x & z))
#define f2(x,y,z)	(x ^ y ^ z)
#define f3(x,y,z)	((x & y) | (x & z) | (y & z))
#define f4(x,y,z)	(x ^ y ^ z)

/* SHA constants */

#define CONST1		0x5a827999L
#define CONST2		0x6ed9eba1L
#define CONST3		0x8f1bbcdcL
#define CONST4		0xca62c1d6L

/* 32-bit rotate */

#define ROT32(x,n)	((x << n) | (x >> (32 - n)))

#define FUNC(n,i)						\
    temp = ROT32(A,5) + f##n(B,C,D) + E + W[i] + CONST##n;	\
    E = D; D = C; C = ROT32(B,30); B = A; A = temp


INT32 sha_info_count_lo_sw, sha_info_count_hi_sw;	/* 64-bit bit count */
INT32 sha_info_data_sw[16];

static void
local_memset (INT32 * s, int c, int n, int e)
{
  INT32 uc;
  INT32 *p;
  int m;

  m = n / 4;
  uc = c;
  p = (INT32 *) s;
  while (e-- > 0)
    {
      p++;
    }
  while (m-- > 0)
    {
      *p++ = uc;
    }
}

static void
local_memcpy (INT32 * s1, const BYTE * s2, int n)
{
  INT32 *p1;
  BYTE *p2;
  INT32 tmp;
  int m;
  m = n / 4;
  p1 = (INT32 *) s1;
  p2 = (BYTE *) s2;

  while (m-- > 0)
    {
      tmp = 0;
      tmp |= 0xFF & *p2++;
      tmp |= (0xFF & *p2++) << 8;
      tmp |= (0xFF & *p2++) << 16;
      tmp |= (0xFF & *p2++) << 24;
      *p1 = tmp;
      p1++;
    }
}

/* do SHA transformation */

static void
sha_transform (INT32 sha_info_digest[5])
{
  int i;
  INT32 temp, A, B, C, D, E, W[80];

  for (i = 0; i < 16; ++i)
    {
      W[i] = sha_info_data_sw[i];
    }
  for (i = 16; i < 80; ++i)
    {
      W[i] = W[i - 3] ^ W[i - 8] ^ W[i - 14] ^ W[i - 16];
    }
  A = sha_info_digest[0];
  B = sha_info_digest[1];
  C = sha_info_digest[2];
  D = sha_info_digest[3];
  E = sha_info_digest[4];

  for (i = 0; i < 20; ++i)
    {
      FUNC (1, i);
    }
  for (i = 20; i < 40; ++i)
    {
      FUNC (2, i);
    }
  for (i = 40; i < 60; ++i)
    {
      FUNC (3, i);
    }
  for (i = 60; i < 80; ++i)
    {
      FUNC (4, i);
    }

  sha_info_digest[0] += A;
  sha_info_digest[1] += B;
  sha_info_digest[2] += C;
  sha_info_digest[3] += D;
  sha_info_digest[4] += E;
}

/* initialize the SHA digest */

static void
sha_init (INT32 sha_info_digest[5])
{
  sha_info_digest[0] = 0x67452301L;
  sha_info_digest[1] = 0xefcdab89L;
  sha_info_digest[2] = 0x98badcfeL;
  sha_info_digest[3] = 0x10325476L;
  sha_info_digest[4] = 0xc3d2e1f0L;
  sha_info_count_lo_sw = 0L;
  sha_info_count_hi_sw = 0L;
}

/* update the SHA digest */

static void
sha_update (const BYTE * buffer, int count, INT32 sha_info_digest[5])
{
  if ((sha_info_count_lo_sw + ((INT32) count << 3)) < sha_info_count_lo_sw)
    {
      ++sha_info_count_hi_sw;
    }
  sha_info_count_lo_sw += (INT32) count << 3;
  sha_info_count_hi_sw += (INT32) count >> 29;
  while (count >= SHA_BLOCKSIZE)
    {
      local_memcpy (sha_info_data_sw, buffer, SHA_BLOCKSIZE);
      sha_transform (sha_info_digest);
      buffer += SHA_BLOCKSIZE;
      count -= SHA_BLOCKSIZE;
    }
  local_memcpy (sha_info_data_sw, buffer, count);
}

/* finish computing the SHA digest */

static void
sha_final (INT32 sha_info_digest[5])
{
  int count;
  INT32 lo_bit_count;
  INT32 hi_bit_count;

  lo_bit_count = sha_info_count_lo_sw;
  hi_bit_count = sha_info_count_hi_sw;
  count = (int) ((lo_bit_count >> 3) & 0x3f);
  sha_info_data_sw[count++] = 0x80;
  if (count > 56)
    {
      local_memset (sha_info_data_sw, 0, 64 - count, count);
      sha_transform (sha_info_digest);
      local_memset (sha_info_data_sw, 0, 56, 0);
    }
  else
    {
      local_memset (sha_info_data_sw, 0, 56 - count, count);
    }
  sha_info_data_sw[14] = hi_bit_count;
  sha_info_data_sw[15] = lo_bit_count;
  sha_transform (sha_info_digest);
}

/* compute the SHA digest of a FILE stream */
void sha_main_sw (BYTE indata[VSIZE*BLOCK_SIZE], BYTE digest_out[20])
{
  int i, j;
  const BYTE *p;
  INT32 sha_info_digest[5];

  sha_init (sha_info_digest);
  for (j = 0; j < VSIZE; j++)
    {
      i = BLOCK_SIZE;
      p = &indata[j*BLOCK_SIZE+0];
      sha_update (p, i, sha_info_digest);
    }
  sha_final (sha_info_digest);
  for(i=0; i<5; i++)
  {
    digest_out[4*i] = (BYTE) (sha_info_digest[i]>>0);
    digest_out[4*i+1] = (BYTE) (sha_info_digest[i]>>8);
    digest_out[4*i+2] = (BYTE) (sha_info_digest[i]>>16);
    digest_out[4*i+3] = (BYTE) (sha_info_digest[i]>>24);
  }
}

