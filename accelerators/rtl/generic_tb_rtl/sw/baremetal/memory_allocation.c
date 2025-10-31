#include "esp_accelerator.h"
#include "esp_probe.h"
#include "monitors.h"
#include "soc_locs.h"
#include "soc_defs.h"

#include "stdio.h"
//Memory tile allocation functions


// A basic memory allocation strategy for minimal fairness: allocate the same number of accelerators for each memory tile,
// in a round-robin fashion counting accelerators in alphabetical and positional order
void BasicAllocation(uint8_t * mem_allocation)
{
  //Allocation does not depend on position. This is the easiest method.
  for (int ndev = 0; ndev < SOC_NACC; ndev++)
  {
    mem_allocation[ndev] = ndev%SOC_NMEM;
  }

}


// A more advanced heuristic for memory allocation: each memory chooses in turn the nearest tile and claims it for itself,
// until all the tiles are taken. This must be combined with an accelerator placement that follows the same rule.
void GreedyAllocation(uint8_t * mem_allocation)
{

  // For each memory, loop through all the tiles and compute the distance of all the free tiles.
  // The nearest one will be filled with the first accelerator from the queue.
  uint16_t tile_count = 0;
  uint8_t stop = 0;
  uint8_t free_acc[SOC_NACC] = {0};
  uint8_t tile_dist[SOC_NACC] = {0}; // Just for printing

  // In this algorithm, each memory in turn chooses the nearest free tile, repeating until there are no more free tiles
  while (1)
  {
    // For each memory, explore all the accelerator tiles and get the one with the minimum distance among the free ones
    for (uint8_t i=0; i<SOC_NMEM; i++)
    {
      // Order of memories: top-right corner, bottom-left corner, bottom-right corner, top-left corner.
      // In this way, the memories near CPU and IO are left last, so that they receive less accelerators.
      uint8_t mem_i = (i+1)%SOC_NMEM;

      printf("\n\n\n###################  MEM%u [%u, %u] #########################\n\n", mem_i, mem_locs[mem_i].row, mem_locs[mem_i].col);

      uint8_t min_distance = 255;
      uint8_t best_tile = 255;

      for (uint8_t tile_i=0; tile_i<SOC_NACC; tile_i++)
      {
        if (free_acc[tile_i] == 0)
        {
          printf("EVALUATING TILE %u [%u, %u]\n", tile_i, acc_locs[tile_i].row, acc_locs[tile_i].col);

          int8_t this_distance_y = mem_locs[mem_i].row - acc_locs[tile_i].row;
          if (this_distance_y<0)
            this_distance_y = -this_distance_y;

          int8_t this_distance_x = mem_locs[mem_i].col - acc_locs[tile_i].col;
          if (this_distance_x<0)
            this_distance_x = -this_distance_x;

          uint8_t this_distance = this_distance_x + this_distance_y;
          printf("Distance=%u\n", this_distance);
          if (this_distance < min_distance)
          {
            printf("This is the minimum distance so far\n");
            best_tile = tile_i;
            min_distance = this_distance;
            tile_dist[tile_i] = this_distance;
          }
        }
      }

      if (min_distance == 255)
      {
        stop = 1;
        break;
      }

      mem_allocation[best_tile] = mem_i;
      free_acc[best_tile] = 1;
    }

    if (stop)
      break;
  }
  // Print the distance of each tile
  printf("\nDATE2026-DIST: ");
  for (uint8_t tile_i=0; tile_i<SOC_NACC; tile_i++)
    printf("%d ", tile_dist[tile_i]);
  printf("\n");
}






  ////Step 1 - Find the hamming distance with all the memory tiles
  //uint8_t hamming_dist[N_ACC_TILES][SOC_NMEM] = {0};
  //for (int ndev = 0; ndev < N_ACC_TILES; ndev++)
  //{
  //  uint8_t acc_y = acc_locs[ndev].row;
  //  uint8_t acc_x = acc_locs[ndev].col;
  //  for (int nmem = 0; nmem < SOC_NMEM; nmem++)
  //  {
  //    uint8_t mem_y = mem_locs[nmem].row;
  //    uint8_t mem_x = mem_locs[nmem].col;
  //
  //    int dist_x = acc_x - mem_x;
  //    if(dist_x < 0)
  //      dist_x = -dist_x;
  //
  //    int dist_y = acc_y - mem_y;
  //    if(dist_y < 0)
  //      dist_y = -dist_y;
  //
  //    hamming_dist[ndev][nmem] = dist_x + dist_y;
  //    printf("The Hamming distance of Acc%d from Mem%d is: %d\n", ndev, nmem, hamming_dist[ndev][nmem]);
  //  }
  //}
  //
  ////Step 2 - For each accelerator, assign the memory tiles with less allocations among the ones with the lowest hamming distance
  //for (int ndev = 0; ndev < N_ACC_TILES; ndev++)
  //{
  //  uint8_t min_hamming_dist = 100;
  //  uint8_t min_allocations = 100;
  //  uint8_t temp_alloc = 100;
  //  for (int nmem = 0; nmem < SOC_NMEM; nmem++)
  //  {
  //    if(hamming_dist[ndev][nmem] < min_hamming_dist)
  //    {
  //      temp_alloc = nmem;
  //      min_hamming_dist = hamming_dist[ndev][nmem];
  //    }
  //    else if(hamming_dist[ndev][nmem] == min_hamming_dist)
  //    {
  //      uint8_t n_alloc_old = 0, n_alloc_current = 0;
  //      for(int ndev2 = 0; ndev2 < ndev; ndev2++)
  //      {
  //        if(mem_allocation[ndev2] == temp_alloc)
  //          n_alloc_old++;
  //        else if(mem_allocation[ndev2] == nmem)
  //          n_alloc_current++;
  //      }
  //      if(n_alloc_current < n_alloc_old)
  //        temp_alloc = nmem;
  //    }
  //  }
  //  mem_allocation[ndev] = temp_alloc;
  //  printf("Allocated Mem%d to Acc%d\n", temp_alloc, ndev);
  //}

