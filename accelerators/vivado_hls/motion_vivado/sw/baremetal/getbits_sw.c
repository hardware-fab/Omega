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
/* getbits.c, bit level routines                                            */

/*
 * All modifications (mpeg2decode -> mpeg2play) are
 * Copyright (C) 1996, Stefan Eckart. All Rights Reserved.
 */

/* Copyright (C) 1996, MPEG Software Simulation Group. All Rights Reserved. */

/*
 * Disclaimer of Warranty
 *
 * These software programs are available to the user without any license fee or
 * royalty on an "as is" basis.  The MPEG Software Simulation Group disclaims
 * any and all warranties, whether express, implied, or statuary, including any
 * implied warranties or merchantability or of fitness for a particular
 * purpose.  In no event shall the copyright-holder be liable for any
 * incidental, punitive, or consequential damages of any kind whatsoever
 * arising from the use of these programs.
 *
 * This disclaimer of warranty extends to the user of these programs and user's
 * customers, employees, agents, transferees, successors, and assigns.
 *
 * The MPEG Software Simulation Group does not represent or warrant that the
 * programs furnished hereunder are free of infringement of any third-party
 * patents.
 *
 * Commercial implementations of MPEG-1 and MPEG-2 video, including shareware,
 * are subject to royalty fees to patent holders.  Many of these patents are
 * general enough such that they are unavoidable regardless of implementation
 * design.
 *
 */

#include "global_sw.h"

#define SEQUENCE_END_CODE 0x1B7

int System_Stream_Flag_sw;
unsigned char inRdbfr_sw[NUM];
unsigned char ld_Rdbfr_sw[2048];
unsigned int ld_Rdptr_sw, ld_Rdmax_sw;
unsigned int ld_Bfr_sw;
int ld_Incnt_sw;

/* initialize buffer, call once before first getbits or showbits */
static int read (unsigned char s1[NUM], const unsigned char s2[NUM])
{
	int i;
	for(i = 0; i < NUM; i++){
		s1[i] = s2[i];
	}

	return NUM;
}

void Fill_Buffer_sw ()
{
	int Buffer_Level;

	Buffer_Level = read(ld_Rdbfr_sw, inRdbfr_sw);
	ld_Rdptr_sw = 0;

	if (System_Stream_Flag_sw)
	ld_Rdmax_sw -= 2048;


	/* end of the bitstream file */
	if (Buffer_Level < 2048)
	{
		/* just to be safe */
		if (Buffer_Level < 0)
			Buffer_Level = 0;

		/* pad until the next to the next 32-bit word boundary */
		while (Buffer_Level & 3)
			ld_Rdbfr_sw[Buffer_Level++] = 0;

		/* pad the buffer with sequence end codes */
		while (Buffer_Level < 2048)
		{
			ld_Rdbfr_sw[Buffer_Level++] = SEQUENCE_END_CODE >> 24;
			ld_Rdbfr_sw[Buffer_Level++] = SEQUENCE_END_CODE >> 16;
			ld_Rdbfr_sw[Buffer_Level++] = SEQUENCE_END_CODE >> 8;
			ld_Rdbfr_sw[Buffer_Level++] = SEQUENCE_END_CODE & 0xff;
		}
	}
}

unsigned int Show_Bits_sw (int N)
{
	return ld_Bfr_sw >> (unsigned)(32-N)%32;
}


/* return next bit (could be made faster than Get_Bits(1)) */

unsigned int Get_Bits1_sw ()
{
	return Get_Bits_sw (1);
}


/* advance by n bits */

void Flush_Buffer_sw (int N)
{
    int Incnt;

#ifdef RAND_VAL 
	/* N is between 0 and 20 with realistic input sets, while it may become larger than the width of the integer type when using randomly generated input sets which are used in the contained input set. The following is to avoid this.  */
	ld_Bfr_sw <<= (N%20);
#else
    ld_Bfr_sw <<= N;
#endif
	
	Incnt = ld_Incnt_sw -= N;

	if (Incnt <= 24)
	{
		if (ld_Rdptr_sw < 2044)
		{
			do
			{
#ifdef RAND_VAL 
				/* N is between 0 and 20 with realistic input sets, while it may become larger than the width of the integer type when using randomly generated input sets which are used in the contained input set. The following is to avoid this.  */
	    		ld_Bfr_sw |= ld_Rdbfr_sw[ld_Rdptr_sw++] << ((24 - Incnt)%20);
#else
	    		ld_Bfr_sw |= ld_Rdbfr_sw[ld_Rdptr_sw++] << (24 - Incnt);
#endif
	    		Incnt += 8;
	   		}
	  		while (Incnt <= 24);
		}
      	else {
	  		do
	    	{
	      		if (ld_Rdptr_sw >= 2048)
					Fill_Buffer_sw ();
#ifdef RAND_VAL 
				/* N is between 0 and 20 with realistic input sets, while it may become larger than the width of the integer type when using randomly generated input sets which are used in the contained input set. The following is to avoid this.  */
	      		ld_Bfr_sw |= ld_Rdbfr_sw[ld_Rdptr_sw++] << ((24 - Incnt)%20);
#else
	      		ld_Bfr_sw |= ld_Rdbfr_sw[ld_Rdptr_sw++] << (24 - Incnt);
#endif
	      		Incnt += 8;
	    	}
	  		while (Incnt <= 24);
		}
      	ld_Incnt_sw = Incnt;
    }
}


/* return next n bits (right adjusted) */

unsigned int Get_Bits_sw (int N)
{
  unsigned int Val;

  Val = Show_Bits_sw (N);
  Flush_Buffer_sw (N);

  return Val;
}
