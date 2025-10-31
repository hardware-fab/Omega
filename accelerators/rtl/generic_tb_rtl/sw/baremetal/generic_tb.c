/* Copyright (c) 2011-2023 Columbia University, System Level Design Group */
/* SPDX-License-Identifier: Apache-2.0 */

#include <stdio.h>
#ifndef __riscv
#include <stdlib.h>
#endif

#include "esp_accelerator.h"
#include "esp_probe.h"
#include "fixed_point.h"

#include "accelerators.h"
#include <monitors.h>

//#include "soc_locs.h"
#include "memory_allocation.h"


//---------------------TEST CONFIGURATION----------------------------
#define N_TESTS 12 //2 ACC X 3 FREQ COMB X 2 TRAFFIC CONDITIONS

//---------------------Timer Definitions-----------------------------
#define BASE_ADDRESS 0x60000300
#define TIMER_LO 0xB4
#define TIMER_HI 0xB8
#define DOMAIN_0 ((16 + 0)*4 + 128)
#define DOMAIN_1 ((16 + 1)*4 + 128)
#define DOMAIN_2 ((16 + 2)*4 + 128)
#define DOMAIN_3 ((16 + 3)*4 + 128)
#define DOMAIN_4 ((16 + 4)*4 + 128)

static long unsigned custom_gettime_nano()
{
    volatile unsigned long timer_reg_lo, timer_reg_hi;
    volatile uint32_t * timer_lo_ptr = (volatile uint32_t *)(BASE_ADDRESS + TIMER_LO);
    volatile uint32_t * timer_hi_ptr = (volatile uint32_t *)(BASE_ADDRESS + TIMER_HI);
    timer_reg_lo = *timer_lo_ptr;
    timer_reg_hi = *timer_hi_ptr;
    return (long unsigned) ((*timer_lo_ptr | (long unsigned)(*timer_hi_ptr)<<32)*CLOCK_PERIOD);
}

static void print_time(long unsigned value)
{
    uint32_t nano = value%1000;
    uint32_t micro = (value%1000000)/1000;
    uint32_t milli = (value%1000000000)/1000000;
    uint32_t sec = (value%1000000000000)/1000000000;
    printf("Original Value = %lu : %u s - %u ms - %u us - %u ns", value, sec, milli, micro, nano);
}

static void print_time_us(long unsigned value)
{
    uint32_t decimal = value%1000;
    uint32_t integer = (value)/1000;
    printf("%u.%03u", integer, decimal);
}

static void wait_micro(long unsigned waiting_time)
{
    long unsigned start, end;
    start = custom_gettime_nano();
    end = 0;
    while(end < start + waiting_time*1000)
        end = custom_gettime_nano();
    return;
}

//--------------Global Variables--------------------------
//Real number of accelerators (available only after the initialization)
static uint8_t soc_acc_num;

//Accelerators size variables
static unsigned in_words_adj[N_ACC_TILES];
static unsigned out_words_adj[N_ACC_TILES];
static unsigned in_len[N_ACC_TILES];
static unsigned out_len[N_ACC_TILES];
static unsigned in_size[N_ACC_TILES];
static unsigned out_size[N_ACC_TILES];
static unsigned out_offset[N_ACC_TILES];
static unsigned mem_size[N_ACC_TILES];

//Devices info
struct esp_device *acc_ptr[N_ACC_TILES];

//Accelerators I/O
unsigned **ptable[N_ACC_TILES];
uint8_t *mem[N_ACC_TILES];
uint8_t *gold[N_ACC_TILES];
unsigned errors = 0;

//Accelerators batch sizes
unsigned acc_batch_sizes[N_ACC_TILES];

//Memory allocation
uint8_t mem_allocation[N_ACC_TILES] = {100};

//Accelerators type
uint8_t acc_type[N_ACC_TILES];

//--------------Functions Declaration------------------
int init_devs();
void config_cache();
void run_acc();
//void Memory_Allocation();

int main(int argc, char * argv[])
{
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");
  printf("------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n-----------------------------------------------------------START-----------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n--------------------------------------------------------------------------------------------------------------------------------------\n---------------------------------------------------------------------------------------------\n\n\n");

  //-----------------------------------Local variables------------------------------------
  init_uncached_pointers();
  //printf("uncached_area_ptr=%lx\n\n", get_uncached_pointer());
  //Accelerators execution
  int ready[N_ACC_TILES] = {0};
  int counter[N_ACC_TILES] = {0};
  unsigned done[N_ACC_TILES] = {0};
  unsigned ready_all = 0;

  //Time variables
  double start_time, time_elapsed = 0;
  double time_acc[N_ACC_TILES] = {0};
  double window_start, window_end;
  unsigned long window_actual_time;

  //Frequency data
  unsigned noc_freq = 1;
  volatile uint32_t * noc_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + DOMAIN_0);
  volatile uint32_t * cpu_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + DOMAIN_1);
  volatile uint32_t * acc_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + DOMAIN_2);
  //volatile uint32_t * acc1_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + DOMAIN_3);
  //volatile uint32_t * acc2_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + DOMAIN_4);

  uint8_t noc_freq_int = 0;
  uint8_t cpu_freq_int = 0;
  uint8_t acc_freq_int = 0;

  uint8_t cp = 0;

  soc_acc_num = 0;

#ifdef GREEDY_ALLOCATION
  GreedyAllocation(mem_allocation);
  printf("Greedy allocation result: ");
#else
  BasicAllocation(mem_allocation);
  printf("Basic allocation result: ");
#endif
  for (int i=0; i<SOC_NACC; i++)
  {
    printf("%u   ", mem_allocation[i]);
  }
  printf("\n");


  init_devs();

  printf("The devices have been initialized\n");


  cpu_freq_int = 9;
  acc_freq_int = 19;
  noc_freq_int = 19;

  *cpu_freq_reg = cpu_freq_int;
  *acc_freq_reg = acc_freq_int;
  *noc_freq_reg = noc_freq_int;

  //*acc1_freq_reg = 19;
  //*acc2_freq_reg = 19;

  cp++;
  printf("Resetting control variables...\n", cp);

  //Reset the control variables
  ready_all = 0;

  time_elapsed = 0;

  for(int ndev=0; ndev<soc_acc_num; ndev++)
  {
    ready[ndev] = 0;
    done[ndev] = 0;
    counter[ndev] = 0;
  }

  for(int ndev=0; ndev<soc_acc_num; ndev++)
    run_acc(ndev);

  cp++;
  printf("Starting the timer...\n", cp);

  //Start the timer
  start_time = custom_gettime_nano();

  cp++;
  printf("Entering the main loop...\n", cp);


  while(!(ready_all && time_elapsed))
  {
    //-------------------ACCELERATORS EXECUTION----------------------------

    ready_all = 1;
    for(int ndev=0; ndev<soc_acc_num; ndev++)
    {
      //cp++;
      //printf("Checkpoint %d\n", cp);
      
      if(!ready[ndev])
      {
        ready_all = 0;
        //Check done
        done[ndev] = ioread32(acc_ptr[ndev], STATUS_REG);
        done[ndev] &= STATUS_MASK_DONE;
        if(done[ndev])
        {
          //printf("NOP\n");
          //Restart the accelerator
          done[ndev] = 0;
          iowrite32(acc_ptr[ndev], CMD_REG, 0x0);
          run_acc(ndev);
          //Get execution statistics
          counter[ndev]++;
          if(time_elapsed)
          {
            time_acc[ndev] = custom_gettime_nano() - start_time;
            ready[ndev] = 1;
            //printf("Dev %d has completed its execution.\n", ndev);
          }
        }
      }
    }
    if(custom_gettime_nano() - start_time > ((unsigned long)MAX_TEST_TIME*1000000000) && !time_elapsed)
    //if(custom_gettime_nano() - start_time > ((unsigned long)MAX_TEST_TIME*1000000) && !time_elapsed) //TODO: REMOVE THIS LINE AND RESTORE THE ONE ABOVE! WARNING!!!!!
      time_elapsed = 1;
  }

  printf("Execution completed.\n");
  //Compute the throughput for each accelerator
  long unsigned thr_kB[N_ACC_TILES] = {0};
  long unsigned thr_kB_tot[N_ACC_TYPES] = {0};
  for(int ndev = 0; ndev<soc_acc_num; ndev++)
  {
    thr_kB[ndev] = ((uint64_t)batch_bytes[acc_type[ndev]]*1000000)/(time_acc[ndev]/(counter[ndev]*acc_batch_sizes[ndev]));
    thr_kB_tot[acc_type[ndev]] += thr_kB[ndev];
  }

  //Find the number of applications, by checking which ones have a throughput different than zero
  uint8_t n_app = 0;
  uint8_t app_indexes[N_ACC_TYPES] = {0};
  for(int app_cnt = 0; app_cnt < N_ACC_TYPES; app_cnt++)
  {
    if(thr_kB_tot[app_cnt] != 0)
    {
      app_indexes[n_app] = app_cnt;
      n_app++;
    }
  }
  //The max number of tiles for a single application is computed considering that
  //in the SoC we need at least an IO, a CPU, and a MEM tile, and at least one tile
  //for each application.
  //(This value is needed to print the same number of values for each configuration,
  //to make the creation of excel tables easier)
  int max_tiles_for_app = N_TILES - 2 - SOC_NMEM - (n_app-1);

  printf("DATA_START\n");

  printf("EXEC_RESULTS ");

  for(int app_cnt = 0; app_cnt < n_app; app_cnt++)
  {
    int count_acc = 0;
    //Print out the execution time
    for(int ndev=0; ndev<soc_acc_num; ndev++)
    {
      if(acc_type[ndev] == app_indexes[app_cnt])
      {
        print_time_us(time_acc[ndev]/(counter[ndev]*acc_batch_sizes[ndev]));
        printf(" ");
        count_acc++;
      }
    }
    //I need to fill with zeroes, since the ML script expects a number of throughput values equal to free_tiles-1
    for(int rem=0; rem<max_tiles_for_app-count_acc; rem++)
      printf("0 ");

    //To print the throughput, I can use the same function used to print the time
    for(int ndev=0; ndev<soc_acc_num; ndev++)
    {
      if(acc_type[ndev] == app_indexes[app_cnt])
      {
        print_time_us(thr_kB[ndev]);
        printf(" ");
      }
    }
    //I need to fill with zeroes, since the ML script expects a number of throughput values equal to free_tiles-1
    for(int rem=0; rem<max_tiles_for_app-count_acc; rem++)
      printf("0 ");

    //Print out the total throughput of the application
    print_time_us(thr_kB_tot[app_indexes[app_cnt]]);
    printf(" ");

  }
  printf("\n");


  // Below, the printing for the DATE 2026 paper
  int counter_ordered[SOC_NACC] = {0};
  int thr_ordered[SOC_NACC] = {0};
  for(int acc_i=0; acc_i<soc_acc_num; acc_i++) {
    counter_ordered[get_index_from_address(acc_ptr[acc_i]->addr)] = counter[acc_i];
    thr_ordered[get_index_from_address(acc_ptr[acc_i]->addr)] = thr_kB[acc_i]; 
  }
  // Print the number of executions
  printf("\nDATE2026-N_EXEC: ");
  for(int acc_i=0; acc_i<SOC_NACC; acc_i++)
    printf("%d ", counter_ordered[acc_i]);
  // Print the throughput for each tile
  printf("\nDATE2026-THR: ");
  for(int acc_i=0; acc_i<SOC_NACC; acc_i++)
  {
    print_time_us(thr_ordered[acc_i]);
    printf(" ");
  }
  printf("\n");
  
  printf("DATA_END\n");


  printf("Execution Completed\n");

  //Total throughput again
  printf("\nTotal throughput: ");
  for(int app_cnt = 0; app_cnt < n_app; app_cnt++)
  {
    //Print out the total throughput of the application
    print_time_us(thr_kB_tot[app_indexes[app_cnt]]);
    printf(" ");
  }
  printf("\n\n");

  for(int ndev=0; ndev = N_ACC_TILES; ndev++)
  {
    aligned_free(ptable[ndev]);
    aligned_free(mem[ndev]);
    aligned_free(gold[ndev]);
  }
  return 0;
}


//---------------Initialization of the devices----------------
int init_devs()
{
  int ndev = 0;
  struct esp_device *espdevs;
  // Search for the device
  printf("Scanning device tree... \n");
  for(int i = 0; i<N_ACC_TYPES; i++)
  //for(int i = N_ACC_TYPES - 1; i>= 0; i--)
  {
    //For every loop, search for a different accelerator type
    int ndev_local = 0;
    if (i==0)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_ADPCM, DEV_NAME_ADPCM);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("adpcm not found\n");
    }
    else if(i == 1)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_AES, DEV_NAME_AES);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("aes not found\n");
    }
    else if(i == 2)
    {
      //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_AES256, DEV_NAME_AES256);
      ndev_local = search_dev(&espdevs, i);
      if (ndev_local == 0)
        printf("aes256 not found\n");
    }
    else if(i == 3)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_BLOWFISH, DEV_NAME_BLOWFISH);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("blowfish not found\n");
    }
    else if(i == 4)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_DFADD, DEV_NAME_DFADD);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("dfadd not found\n");
    }
    else if(i == 5)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_DFDIV, DEV_NAME_DFDIV);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("dfdiv not found\n");
    }
    else if(i == 6)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_DFMUL, DEV_NAME_DFMUL);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("dfmul not found\n");
    }
    else if(i == 7)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_DFSIN, DEV_NAME_DFSIN);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("dfsin not found\n");
    }
    else if(i == 8)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_GSM, DEV_NAME_GSM);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("gsm not found\n");
    }
    else if(i == 9)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_MIPS, DEV_NAME_MIPS);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("mips not found\n");
    }
    else if(i == 10)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_MOTION, DEV_NAME_MOTION);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("motion not found\n");
    }
    else if(i == 11)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_SHA, DEV_NAME_SHA);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("sha not found\n");
    }
    else if(i == 12)
    {
        //ndev_local = probe(&espdevs, VENDOR_SLD, SLD_SHA3, DEV_NAME_SHA3);
        ndev_local = search_dev(&espdevs, i);
        if (ndev_local == 0)
            printf("sha3 not found\n");
    }
    for (int n = 0; n < ndev_local; n++) {
      //For each accelerator of a given type, initialize all the variables
      //printf("**************** %s.%d ****************\n", espdevs[n].name, n);

      acc_ptr[ndev] = &espdevs[n];

      printf("\n");
      printf("\n#################################################\n");
      printf("\n");
      printf("\nDEVICE INFO\n\n");
      printf("Vendor: %x\n", acc_ptr[ndev]->vendor);
      printf("ID: %x\n", acc_ptr[ndev]->id);
      printf("Number: %x\n", acc_ptr[ndev]->number);
      printf("IRQ: %x\n", acc_ptr[ndev]->irq);
      printf("Address: %llx\n", acc_ptr[ndev]->addr);
      printf("Compat: %u\n", acc_ptr[ndev]->compat);
      printf("Name: %s\n", acc_ptr[ndev]->name);

      printf("\nacc_ptr addr = %lx\n", (uint64_t) acc_ptr[ndev]);
      printf("Accelerator position: %u\n", get_index_from_address(acc_ptr[ndev]->addr));
      //printf("PT NCHUNK MAX REG: %d\n", ioread32(acc_ptr[ndev], PT_NCHUNK_MAX_REG));

      //Collect the sizes of its IO
      init_size_all(&in_words_adj[ndev], &out_words_adj[ndev], &in_len[ndev], &out_len[ndev], &in_size[ndev], &out_size[ndev], &out_offset[ndev], &mem_size[ndev], i);
      get_batch_size(&acc_batch_sizes[ndev], i);
      acc_type[ndev] = i;

      // Check DMA capabilities
      if (ioread32(acc_ptr[ndev], PT_NCHUNK_MAX_REG) == 0)
      {
          printf("  -> scatter-gather DMA is disabled. Abort.\n");
          //continue;
      }


      if (ioread32(acc_ptr[ndev], PT_NCHUNK_MAX_REG) < NCHUNK(mem_size[ndev])) {
          printf("  -> Not enough TLB entries available. Abort.\n");
          //continue;
      }

      // Allocate memory
#ifdef GREEDY_ALLOCATION
      printf("Greedy allocation of the accelerator...\n");
      gold[ndev] = aligned_malloc_bank(out_size[ndev], mem_allocation[get_index_from_address(acc_ptr[ndev]->addr)]);
      mem[ndev] = aligned_malloc_bank(mem_size[ndev], mem_allocation[get_index_from_address(acc_ptr[ndev]->addr)]);
#else
      gold[ndev] = aligned_malloc_bank(out_size[ndev], mem_allocation[ndev]);
      mem[ndev] = aligned_malloc_bank(mem_size[ndev], mem_allocation[ndev]);
#endif


      //gold[ndev] = aligned_malloc(out_size[ndev]);
      //mem[ndev] = aligned_malloc(mem_size[ndev]);

      printf("out_size = %d, mem_size=%d\n", out_size[ndev], mem_size[ndev]);
      printf("  memory buffer base-address = %p\n", mem[ndev]);

      // Alocate and populate page table

      ptable[ndev] = aligned_malloc(NCHUNK(mem_size[ndev]) * sizeof(unsigned *));
      for (int j = 0; j < NCHUNK(mem_size[ndev]); j++)
          ptable[ndev][j] = (unsigned *) &mem[ndev][j * (CHUNK_SIZE / sizeof_token[i])];

      //printf("  ptable = %p\n", ptable[ndev]);
      //printf("  nchunk = %lu\n", NCHUNK(mem_size[ndev]));

      config_cache(ndev, i);
      ndev += 1;
      soc_acc_num ++;

    }
  }
}



//---------------Cache configuration functions----------------
void config_cache(int ndev, int acc_type)
{
  unsigned coherence;
  /* TODO: Restore full test once ESP caches are integrated */
  coherence = ACC_COH_NONE;
  printf("  --------------------\n");
  printf("  Generate input for acc %d of type %d...\n", ndev, acc_type);
  init_buf_all(mem[ndev], gold[ndev], in_words_adj[ndev], acc_type);
  // Pass common configuration parameters
  iowrite32(acc_ptr[ndev], SELECT_REG, ioread32(acc_ptr[ndev], DEVID_REG));
  iowrite32(acc_ptr[ndev], COHERENCE_REG, coherence);
#ifndef __sparc
  iowrite32(acc_ptr[ndev], PT_ADDRESS_REG, (unsigned long long) ptable[ndev]);
#else
  iowrite32(acc_ptr[ndev], PT_ADDRESS_REG, (unsigned) ptable[ndev]);
#endif
  iowrite32(acc_ptr[ndev], PT_NCHUNK_REG, NCHUNK(mem_size[ndev]));
  iowrite32(acc_ptr[ndev], PT_SHIFT_REG, CHUNK_SHIFT);
  // Use the following if input and output data are not allocated at the default offsets
  iowrite32(acc_ptr[ndev], SRC_OFFSET_REG, 0x0);
  iowrite32(acc_ptr[ndev], DST_OFFSET_REG, 0x0);
  // Pass accelerator-specific configuration parameters
  /* <<--regs-config-->> */
  config_acc_param(acc_ptr[ndev], acc_type);
  // Flush (customize coherence model here)
  esp_flush(coherence);
}

//------------------Starting Functions
void run_acc(int ndev)
{
  // Start accelerators
  //printf("  Start...\n");
  iowrite32(acc_ptr[ndev], CMD_REG, CMD_MASK_START);
}


