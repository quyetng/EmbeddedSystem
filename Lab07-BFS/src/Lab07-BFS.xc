/*
 * Lab07-BFS.xc
 *
 *  Created on: Nov 6, 2018
 *      Author: quyetnguyen
 */
#include <bfs.h>
#include <stdlib.h>
#include <stdio.h>

int main()
{

    const int obstacles [ELEMENT_COUNT] = {
    0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
    0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
    0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
    0 , 0 , 0 , 1 , 1 , 1 , 1 , 0 , 0 , 0 ,
    0 , 0 , 0 , 1 , 1 , 1 , 1 , 0 , 0 , 0 ,
    0 , 0 , 0 , 1 , 1 , 1 , 1 , 0 , 0 , 0 ,
    0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
    0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
    0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
    0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
    } ;
   int start_rank = RANK(9, 6);
   int goal_rank = RANK(0, 2);
   int bfs = 0;
   int aStar = 1;

   // use bfs
   find_shortest_path(start_rank, goal_rank, obstacles, bfs);
   //printf("\n");
   // use A star
   //find_shortest_path(start_rank, goal_rank, obstacles, aStar);

   return 1;
}
