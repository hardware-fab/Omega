#include "global_sw.h"
#include "../global.h"

void Initialize_Buffer_sw(unsigned char inRdbfr_sw[NUM])
{
  ld_Incnt_sw = 0;
  ld_Rdptr_sw = 2048;
  ld_Rdmax_sw = 2048;
  ld_Bfr_sw = 68157440;
  Flush_Buffer_sw(0); /* fills valid data into bfr */
}

//Order of the inputs: inrdbrf, mvfs, pwm
//Order of the outputs: mvfs, pwm
void motion_main_sw(int input_data[NUM/4 + 2*2 + 2*2*2], int output_data[2*2 + 2*2*2])
{
    int i, j, k;
    int main_result;
    int PMV[2][2][2];
    int dmvector[2];
    int motion_vertical_field_select[2][2];
    int s, motion_vector_count, mv_format, h_r_size, v_r_size, dmv, mvscale;

    System_Stream_Flag_sw = 0;
    s = 0;
    motion_vector_count = 1;
    mv_format = 0;
    h_r_size = 200;
    v_r_size = 200;
    dmv = 0;
    mvscale = 1;

    for (i = 0; i < NUM/4; i++){
        inRdbfr_sw[4*i + 0] = input_data[i] >> 0;
        inRdbfr_sw[4*i + 1] = input_data[i] >> 8;
        inRdbfr_sw[4*i + 2] = input_data[i] >> 16;
        inRdbfr_sw[4*i + 3] = input_data[i] >> 24;
    }

    for (i = 0; i < 2; i++)
    {
        dmvector[NUM/4 + i] = 0;
        for (j = 0; j < 2; j++)
        {
            motion_vertical_field_select[i][j] = input_data[NUM/4 + i*2 + j];
            for (k = 0; k < 2; k++)
                PMV[i][j][k] = input_data[NUM/4 + 2*2 + i*2*2 + j*2 + k];
        }
    }

    Initialize_Buffer_sw(inRdbfr_sw);

    motion_vectors_sw(PMV, dmvector, motion_vertical_field_select, s, motion_vector_count, mv_format, h_r_size, v_r_size, dmv, mvscale);

    for (i = 0; i < 2; i++)
    {
        for (j = 0; j < 2; j++)
        {
            output_data[i*2 + j] = motion_vertical_field_select[i][j];
            for (k = 0; k < 2; k++)
                output_data[2*2 + i*2*2 + j*2 + k] = PMV[i][j][k];
        }
    }
}
