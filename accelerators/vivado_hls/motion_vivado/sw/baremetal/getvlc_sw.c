
#include "global_sw.h"

#define ERROR (-1)

/* Table B-10, motion_code, codes 0001 ... 01xx */
static const char MVtab0[8][2] = {
  {ERROR, 0}, {3, 3}, {2, 2}, {2, 2},
  {1, 1}, {1, 1}, {1, 1}, {1, 1}
};

/* Table B-10, motion_code, codes 0000011 ... 000011x */
static const char MVtab1[8][2] = {
  {ERROR, 0}, {ERROR, 0}, {ERROR, 0}, {7, 6},
  {6, 6}, {5, 6}, {4, 5}, {4, 5}
};

/* Table B-10, motion_code, codes 0000001100 ... 000001011x */
static const char MVtab2[12][2] = {
  {16, 9}, {15, 9}, {14, 9}, {13, 9}, {12, 9}, {11, 9},
  {10, 8}, {10, 8}, {9, 8}, {9, 8}, {8, 8}, {8, 8}
};

int Get_motion_code_sw ()
{
  int code;

  if (Get_Bits1_sw ())
    {
      return 0;
    }

  if ((code = Show_Bits_sw (9)) >= 64)
    {
      code >>= 6;
      Flush_Buffer_sw (MVtab0[code][1]);

      return Get_Bits1_sw ()? -MVtab0[code][0] : MVtab0[code][0];
    }

  if (code >= 24)
    {
      code >>= 3;
      Flush_Buffer_sw (MVtab1[code][1]);

      return Get_Bits1_sw ()? -MVtab1[code][0] : MVtab1[code][0];
    }

  if ((code -= 12) < 0)
    return 0;

  Flush_Buffer_sw (MVtab2[code][1]);
  return Get_Bits1_sw ()? -MVtab2[code][0] : MVtab2[code][0];
}

/* get differential motion vector (for dual prime prediction) */
int Get_dmvector_sw ()
{
  if (Get_Bits_sw (1))
    {
      return Get_Bits_sw (1) ? -1 : 1;
    }
  else
    {
      return 0;
    }
}
