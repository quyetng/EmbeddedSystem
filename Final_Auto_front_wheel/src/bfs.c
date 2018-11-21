#include <stdlib.h>
#include <bfs.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <print.h>
#include <math.h>


struct list_element_t_struct;
struct list_element_t_struct
{

    int rank;
    struct list_element_t_struct* next;
    // Added for A star algorithm
    //struct list_element_t_struct* parent;
    //int parentX;
    //int parentY;

};

typedef struct list_element_t_struct list_element_t;

typedef struct
{
    list_element_t *head;
    list_element_t *tail;
} list_t;


list_t init_list()
{
    // create a new empty list
    // both head & tail are null
    list_t lst;
    lst.head = NULL;
    lst.tail = NULL;
    return lst;
}



void push_back_item(list_t* list, list_element_t* item)
{
    // create a new element
    list_element_t *tmp = (list_element_t*)malloc(sizeof(list_element_t));
    assert(tmp != NULL);

    tmp->rank = item->rank;
    tmp->next = NULL;



    // update
    // if a list is empty
    if(!list->head)
    {

        list->head = tmp;
        list->tail = tmp;
        //list->head = item;
        //list->tail = item;
    }
    else
    {

        // set the next reference of the tail to
        // point to new element
        //list->tail->next = item;
        // assign the tail reference itself to new element
        list->tail->next = tmp;
        list->tail = tmp;
    }
    //free(tmp);

}


void free_list(list_t *list)
{
    list_element_t *element;

    while(list->head != NULL)
    {
        element = list->head;
        // head point to the next element
        list->head = list->head->next;
        free(element);
    }
    //list_t newlist = init_list();
    *list = init_list();
    //list = &newlist;
    //list->head = &newlist.head;
    //list->tail = newList->tail;
}

/*
void fill_neighbors(int neighbors[], int rank)
{
    int col0 = COL(rank);
    int row0 = ROW(rank);
    printf("row0 = %d, col0 = %d\n", row0, col0);
    int row, col;
    // set rank of 4 neighbors of (row, col) to 0 - 3
    // neighbor 1; north
    // same col, different row
    row = row0 -1;
    col = col0;
    //list_element_t *tmp = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp ->rank = RANK(col, row);
    neighbors[0] = RANK(col, row);
    // neighbor 2; east
    // same row, different column
    row = row0;
    col = col0 + 1;
    //list_element_t *tmp2 = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp2 ->rank = RANK(col, row);;
    neighbors[1] = RANK(col, row);
    // neighbor 3, south
    // same column, different row
    col = col0;
    row = row0 + 1;
    //list_element_t *tmp3 = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp3 ->rank = RANK(col, row);;
    neighbors[2] = RANK(col, row);

    // neighbor 4, west
    // same row, different column
    row = row0;
    col = col0 - 1;
    //list_element_t *tmp4 = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp4 ->rank = RANK(col, row);;
    printf("neighbors[3] row = %d, col = %d\n", row, col);
    neighbors[3] = RANK(col, row);



}
*/
void fill_neighbors_A_star(int neighbors[], int rank)
{

    //printf("rank = %d\n", rank);
    int row0 = ROW(rank);
    int col0 = COL(rank);
    //printf("row0 = %d, col0 = %d\n", row0, col0);
    int row, col;

    // set rank of 8 neighbors of (row, col) to 0 - 7
    // 0
    // north
    // same col, different row
    row = row0 - 1;
    col = col0;

    // 0
   // printf("north row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[0] = -1;

    }
    else
    {
        neighbors[0] = RANK(row, col);
    }
    //printf("neighbors[0] = %d\n", neighbors[0]);
    // north east neigbor
    // 1
    col = col + 1;
    //printf("north east row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[1] = -1;

    }
    else
    {
        neighbors[1] = RANK(row, col);
    }
    //printf("neighbors[1] = %d\n", neighbors[1]);
    // 2
    //  east
    // same row, different column
    row = row0;
    col = col0 + 1;
   // printf("east row = %d, col = %d\n", row, col);

    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[2] = -1;

    }
    else
    {
        neighbors[2] = RANK(row, col);
    }
    //printf("neighbors[2] = %d\n", neighbors[2]);
    // 3
    // south east
    row = row + 1;
   // printf("south east row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[3] = -1;

    }
    else
    {
        neighbors[3] = RANK(row, col);
    }
    //printf("neighbors[3] = %d\n", neighbors[3]);
    // 4
    //  south
    // same column, different row
    col = col0;
    row = row0 + 1;
    //printf("south row = %d, col = %d\n", row, col);

    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[4] = -1;

    }
    else
    {
        neighbors[4] = RANK(row, col);
    }
    //printf("neighbors[4] = %d\n", neighbors[4]);
    // 5
    // south west
    col = col - 1;
    //printf("south west row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[5] = -1;

    }
    else
    {
        neighbors[5] = RANK(row, col);
    }
    //printf("neighbors[5] = %d\n", neighbors[5]);
    // 6
    //west
    // same row, different column
    row = row0;
    col = col0 - 1;
    //printf(" west row = %d, col = %d\n", row, col);

    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[6] = -1;

    }
    else
    {
        neighbors[6]= RANK(row, col);
    }
    //printf("neighbors[6] = %d\n", neighbors[6]);
    // 7
    // north west
    row = row - 1;
    //printf("north west row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[7] = -1;

    }
    else
    {
        neighbors[7]= RANK(row, col);
    }
    //printf("neighbors[7] = %d\n", neighbors[7]);

}




int insideList(list_t* list, int rank)
{
    list_element_t * tmp = (list_element_t*)malloc(sizeof(list_element_t));
    tmp = list->head;
    int flag = 0;

    while(list->head != NULL)
    {
        if(list->head->rank == rank)
        {
            flag = 1;
            break;
        }
        list->head = list->head->next;
    }
    list->head = tmp;
    return flag;
}


int remove_item(list_t* list, list_element_t* item)
{
    list_element_t *element;
    list_element_t *pre = list->head;
    list_element_t *cur = list->head->next;
    if(!list->head)
    {
        return -1;
    }
    else if(list->head == list->tail) // the last element is removed
    {
        printf("remove last item\n");
        element = list->head;
        free(element);
        //list->head = NULL;
        //list->tail = NULL;
        list_t newlist = init_list();
        list = &newlist;
        assert(list->tail == list->head & list->head == NULL);
        return 1;
    }
    else
    {

        // remove front
        if(list->head->rank == item->rank)
        {
            element = list->head;
            list->head = list->head->next;
            //delete element;
            free(element);

            return 1;
        }

        else
        {
            while(pre != NULL && cur->next != NULL)
            {
                printf("pre->rank = %d\n", pre->rank);
                printf("cur->rank = %d\n", cur->rank);
                /*if(cur->next->rank == item->rank)
                {
                    printf("remove middle \n");
                    pre->next = cur->next->next;
                    element = cur->next;
                    free(element);
                    return 1;
                    //break;
                }
                */
                if(cur->rank == item->rank)
                {
                    printf("remove middle \n");
                    pre->next = cur->next;
                    element = cur;
                    free(element);
                    return 1;
                    //break;
                }
                cur = cur->next;
                pre = pre->next;

            }
            printf("after while\n");
            //cur = cur->next;
            //pre = pre->next;
            printf("pre->rank = %d\n", pre->rank);
            printf("cur->rank = %d\n", cur->rank);

            // remove tail node here
            element = cur;
            pre->next = NULL;
            list->tail = pre;
            free(element);

            return 1;
        }



    }

    return 1;
}

int manhattanDistance(int xa, int ya, int xb, int yb)
{
    return abs(xa - xb) + abs(ya - yb);
}
/*
int euclideanDistance(int xa, int ya, int xb, int yb)
{
    return sqrt(pow((xa - xb), 2) + pow((ya - yb), 2));
}

*/


list_element_t * findMin(list_t* open, int totalCost[])
{



    list_element_t *current = (list_element_t*)malloc(sizeof(list_element_t));
    current = open->head;

    if(open->head == NULL)
    {
        printf("list is empty\n");
        return NULL;
    }
    while(open->head != NULL)
    {


        if(totalCost[open->head->rank] < totalCost[current->rank])
        {
            current = open->head;
        }

        open->head = open->head->next;
    }

    return current;


}
/*
void find_shortest_path_A_star(int start_rank, int goal_rank, const int obstacles[])
{
    int predecessors[ELEMENT_COUNT];
    int totalCost[ELEMENT_COUNT];  // hold total cost for each node
    int actualCost[ELEMENT_COUNT];  // hold g cost for each node
    //int estimateCost[ELEMENT_COUNT];  // hold h cost for each node
    int neighbors[8]; // hold 8 neigbors
    int index;
    int g, h, f;

    for(int i = 0; i < ELEMENT_COUNT; i++)
    {
        RankArr[i] = -1;
        if(obstacles[i] == 1)
        {
            predecessors[i] = -2;
        }
        else
        {
            predecessors[i] = -1;
        }

    }

    list_t openList = init_list();
    list_t closeList = init_list();
    list_t path = init_list();
    assert(openList.tail == openList.head & openList.head == NULL);
    assert(closeList.tail == closeList.head & closeList.head == NULL);

    list_element_t * node = (list_element_t*)malloc(sizeof(list_element_t)); // will be added to openList
    list_element_t * startPoint = (list_element_t*)malloc(sizeof(list_element_t));
    startPoint->rank = start_rank;
    startPoint->next = NULL;
    push_back_item(&openList, startPoint);

    totalCost[start_rank] = 0;

    list_element_t * min = (list_element_t*)malloc(sizeof(list_element_t));;
    //int i = 0;
    while(openList.head != NULL)
    {


        // get item, wich has smallest total cost
        // and remove it out of openList
        min= findMin(&openList, totalCost);

        push_back_item(&path, min);

        //printf("min rank = %d\n", min->rank);

        remove_item(&openList, min);

        // Add to closeList
        push_back_item(&closeList, min);

        if(min->rank == goal_rank)
        {
            printstr("found a goal\n");
            //push_back(&path, current->rank);
            //print path here
            //RankArr[i] = min->rank;
            //i++;
            while(path.head != NULL)
            {
                printf("(%d, %d) \n", ROW(path.head->rank), COL(path.head->rank));
                path.head = path.head->next;
            }


            break;
        }
        else
        {
            // generate 8 neigbors
            fill_neighbors_A_star(neighbors, min->rank);


            for(int i = 0; i < 8; i++)
            {
                // calculate total cost for each neighbor
                index = neighbors[i]; // get index of corresponding cell on predecessors array

                // if a neighbor is accessible
                // not out of bound or obstacle
                if(neighbors[i] != -1 && predecessors[index] == -1)
                {
                    //g = manhattanDistance(ROW(start_rank), COL(start_rank), ROW(neighbors[i]), COL(neighbors[i]));
                    g = actualCost[min->rank] + manhattanDistance(ROW(min->rank), COL(min->rank), ROW(neighbors[i]), COL(neighbors[i]));
                    actualCost[index] = g;
                    // estimate cost from a node n to goal point
                    h = manhattanDistance(ROW(neighbors[i]), COL(neighbors[i]), ROW(goal_rank), COL(goal_rank));
                    //estimateCost[index] = h;
                    // total cost
                    f = g + h;

                    if(insideList(&openList, neighbors[i]) == 1)
                    {

                        if((totalCost[index]) > f)
                        {
                            // remove old occurrence from openList
                            node->rank = neighbors[i];
                            remove_item(&openList, node);

                            // add new one to openList
                            totalCost[index] = f; // new totalCost

                            //node->parent = min;
                            node->rank = neighbors[i]; // same rank
                            node->next = NULL;

                            printstr(" put item to open node \n");
                            push_back_item(&openList, node);
                        }

                    }
                    else
                    {
                        // if a node in closelist
                        // skip it
                        if(insideList(&closeList, neighbors[i]) == 1)
                        {


                        }

                        else
                        {

                            // add neighbor to open list
                            // if a node is not in a open list
                            //push_back(&open, neighbors[i]);
                            //list_element_t * node = (list_element_t*)malloc(sizeof(list_element_t));
                            totalCost[index] = f;
                            //printf("totalCost[%d] = %d\n", index, totalCost[current->rank]);
                            //actualCost[index] = g;
                            // set parent
                            //node->parentX = ROW(min->rank);
                            //node->parentY = COL(min->rank);
                            //node->parent = min;
                            node->rank = neighbors[i];
                            node->next = NULL;
                            // remove later

                            //
                            //printstr(" put item to open node \n");
                            push_back_item(&openList, node);
                            //printf("g = %d\n", g);
                            //printf("h = %d\n", h);
                            //printf("f = %d\n", f);
                            //printf("rank = %d\n", node->rank);


                        }
                    }



                }
            }


        }

        //tmp = tmp->next;
    }


    free(&openList);
    free(&closeList);
    free(predecessors);
    free(totalCost);
    free(actualCost);
    //free(estimateCost);

}
*/

void find_shortest_path_A_star(int start_rank, int goal_rank, const int obstacles[], int rankArr[])
{
    int predecessors[ELEMENT_COUNT];
    //int RankArr[ELEMENT_COUNT];
    int totalCost[ELEMENT_COUNT];  // hold total cost for each node
    int actualCost[ELEMENT_COUNT];  // hold g cost for each node
    //int estimateCost[ELEMENT_COUNT];  // hold h cost for each node
    int neighbors[8]; // hold 8 neigbors
    int index;
    int g, h, f;

    for(int i = 0; i < ELEMENT_COUNT; i++)
    {
        rankArr[i] = -1;
        if(obstacles[i] == 1)
        {
            predecessors[i] = -2;
        }
        else
        {
            predecessors[i] = -1;
        }

    }

    list_t openList = init_list();
    list_t closeList = init_list();
    list_t path = init_list();
    assert(openList.tail == openList.head & openList.head == NULL);
    assert(closeList.tail == closeList.head & closeList.head == NULL);

    list_element_t * node = (list_element_t*)malloc(sizeof(list_element_t)); // will be added to openList
    list_element_t * startPoint = (list_element_t*)malloc(sizeof(list_element_t));
    startPoint->rank = start_rank;
    startPoint->next = NULL;
    push_back_item(&openList, startPoint);

    totalCost[start_rank] = 0;

    list_element_t * min = (list_element_t*)malloc(sizeof(list_element_t));;
    int i = 0;
    while(openList.head != NULL)
    {


        // get item, wich has smallest total cost
        // and remove it out of openList
        min= findMin(&openList, totalCost);

        push_back_item(&path, min);

        //printf("min rank = %d\n", min->rank);

        remove_item(&openList, min);
        rankArr[i] = min->rank;
        i++;
        // Add to closeList
        push_back_item(&closeList, min);

        if(min->rank == goal_rank)
        {
            printstr("found a goal\n");
            //push_back(&path, current->rank);
            //print path here
            /*
            while(path.head != NULL)
            {
                printf("(%d, %d) \n", ROW(path.head->rank), COL(path.head->rank));
                path.head = path.head->next;
            }

            */
            break;
        }
        else
        {
            // generate 8 neigbors
            fill_neighbors_A_star(neighbors, min->rank);


            for(int i = 0; i < 8; i++)
            {
                // calculate total cost for each neighbor
                index = neighbors[i]; // get index of corresponding cell on predecessors array

                // if a neighbor is accessible
                // not out of bound or obstacle
                if(neighbors[i] != -1 && predecessors[index] == -1)
                {
                    //g = manhattanDistance(ROW(start_rank), COL(start_rank), ROW(neighbors[i]), COL(neighbors[i]));
                    g = actualCost[min->rank] + manhattanDistance(ROW(min->rank), COL(min->rank), ROW(neighbors[i]), COL(neighbors[i]));
                    actualCost[index] = g;
                    // estimate cost from a node n to goal point
                    h = manhattanDistance(ROW(neighbors[i]), COL(neighbors[i]), ROW(goal_rank), COL(goal_rank));
                    //estimateCost[index] = h;
                    // total cost
                    f = g + h;

                    if(insideList(&openList, neighbors[i]) == 1)
                    {

                        if((totalCost[index]) > f)
                        {
                            // remove old occurrence from openList
                            node->rank = neighbors[i];
                            remove_item(&openList, node);

                            // add new one to openList
                            totalCost[index] = f; // new totalCost

                            //node->parent = min;
                            node->rank = neighbors[i]; // same rank
                            node->next = NULL;

                            printstr(" put item to open node \n");
                            push_back_item(&openList, node);
                        }

                    }
                    else
                    {
                        // if a node in closelist
                        // skip it
                        if(insideList(&closeList, neighbors[i]) == 1)
                        {


                        }

                        else
                        {

                            // add neighbor to open list
                            // if a node is not in a open list
                            //push_back(&open, neighbors[i]);
                            //list_element_t * node = (list_element_t*)malloc(sizeof(list_element_t));
                            totalCost[index] = f;
                            //printf("totalCost[%d] = %d\n", index, totalCost[current->rank]);
                            //actualCost[index] = g;
                            // set parent
                            //node->parentX = ROW(min->rank);
                            //node->parentY = COL(min->rank);
                            //node->parent = min;
                            node->rank = neighbors[i];
                            node->next = NULL;
                            // remove later
                            /*
                            if(node->rank == goal_rank)
                            {
                                while(node->parent != startPoint)
                                {
                                    printf("(%d, %d) \n", ROW(node->rank), COL(node->rank));
                                    printf("(%d, %d) \n", ROW(node->parent->rank), COL(node->parent->rank));
                                    node = node->parent;
                                }

                            }
                            */
                            //
                            //printstr(" put item to open node \n");
                            push_back_item(&openList, node);
                            //printf("g = %d\n", g);
                            //printf("h = %d\n", h);
                            //printf("f = %d\n", f);
                            //printf("rank = %d\n", node->rank);


                        }
                    }



                }
            }


        }

        //tmp = tmp->next;
    }


    free(&openList);
    free(&closeList);
    free(predecessors);
    free(totalCost);
    free(actualCost);
    //free(estimateCost);

}
/*
void find_shortest_path(int start_rank, int goal_rank, const int obstacles[], int flag)
{

    if(flag == 0)
    {
        find_shortest_path_bfs(start_rank, goal_rank, obstacles);
    }

    if(flag == 1)
    {
        //find_shortest_path_A_star(start_rank, goal_rank, obstacles);
        find_shortest_path_A_star(start_rank, goal_rank, obstacles);
    }

}

*/
void generatePath(int rankArr[])
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
    find_shortest_path_A_star(start_rank, goal_rank, obstacles, rankArr);
    //free(obstacles);
}
void generateCommand(int rankArr[], char command[])
{
    printstr("generateCommand\n");

    int c1, c2, c3;
    int i, j = 0;

    for(i = 0; i < ELEMENT_COUNT; i+=2)
    {
        if(rankArr[i] != -1)
        {
            c1 = rankArr[i];
            c2 = rankArr[i+1];
            //c3 = rankArr[2];
            c3 = rankArr[i+1+1];
            //printf("i+2 = %d\n", c3);
            //c3 = rankArr[2];

            /*printf("(%d, %d)\n", ROW(c1), COL(c1));
            printf("(%d, %d)\n", ROW(c2), COL(c2));
            printf("(%d, %d)\n", ROW(c3), COL(c3));*/
            if(c1 != -1 && c2 != -1 && c3 != -1)
            {
                // 8 cases
                // 3 cells c1, c2, c3 have the same column
                if(COL(c1) == COL(c2) && COL(c1) == COL(c3))
                {
                    // issue 2 commands move forward


                    command[j] = 'f';
                    command[j+1] = 'f';

                    /*printf("%c\n", command[j]);
                    printf("%c\n", command[j+1]);*/
                    j = j + 2;

                }
                // same row
                else if(ROW(c1) == ROW(c2) && ROW(c1) == ROW(c3))
                {
                    // issue 2 commands move forward
                    command[j] = 'f';
                    command[j+1] = 'f';
                    /*printf("%c\n", command[j]);
                    printf("%c\n", command[j+1]);*/
                    j = j + 2;
                }
                else if(ROW(c1) == ROW(c2) && COL(c2) == COL(c3) && ROW(c1) < ROW(c3)
                        && COL(c1) < COL(c3)) //
                {
                    command[j] = 'f';
                    command[j+1] = '.'; // turn right
                    command[j+2] = 'f';
                    /*printf("%c\n", command[j]);
                    printf("%c\n", command[j+1]);
                    printf("%c\n", command[j+2]);*/
                    j = j + 3;
                }
                else if(ROW(c1) == ROW(c2) && COL(c2) == COL(c3) && ROW(c1) > ROW(c3)
                        && COL(c1) < COL(c3)) //
                {
                    command[j] = 'f';
                    command[j+1] = ','; // turn left
                    command[j+1+1] = 'f';
                    /*printf("%c\n", command[j]);

                    printf("%c\n", command[j+1]);
                    printf("%c\n", command[j+2]);*/
                    j = j + 3;
                }
                else if(COL(c1) == COL(c2) && ROW(c2) == ROW(c3) && COL(c1) > COL(c3)
                        && ROW(c1) > ROW(c3)) //
                {
                    command[j] = 'f';
                    command[j+1] = ','; // turn left
                    command[j+1+1] = 'f';
                    /*printf("%c\n", command[j]);
                    printf("%c\n", command[j+1]);
                    printf("%c\n", command[j+2]);*/
                    j = j + 3;
                }
                else if(COL(c1) == COL(c2) && ROW(c2) == ROW(c3) && COL(c1) < COL(c3)
                        && ROW(c1) > ROW(c3)) //
                {
                    command[j] = 'f';
                    command[j+1] = '.'; // turn right
                    command[j+1+1] = 'f';
                    /*
                    printf("%c\n", command[j]);
                    printf("%c\n", command[j+1]);
                    printf("%c\n", command[j+2]);*/
                    j = j + 3;
                }
                else if(ROW(c1) == ROW(c2) && COL(c2) == COL(c3) && ROW(c1) < ROW(c3)
                        && COL(c1) > COL(c3)) //
                {
                    command[j] = 'f';
                    command[j+1] = ','; // turn left
                    command[j+1+1] = 'f';
                    /*printf("%c\n", command[j]);
                    printf("%c\n", command[j+1]);
                    printf("%c\n", command[j+2]);*/
                    j = j + 3;
                }
                else if(ROW(c1) == ROW(c2) && COL(c2) == COL(c3) && ROW(c1) > ROW(c3)
                        && COL(c1) > COL(c3)) //
                {
                    command[j] = 'f';
                    command[j+1] = '.'; // turn right
                    command[j+1+1] = 'f';
                    /*
                    printf("%c\n", command[j]);
                    printf("%c\n", command[j+1]);
                    printf("%c\n", command[j+2]);*/
                    j = j + 3;
                }

            }
            else if(c1 == -1)
            {
                // end of the path
                // stop
                command[j] = 'x';
                command[j+1] ='n';
                /*printf("%c\n", command[j]);
                printf("%c\n", command[j+1]);*/

                j = j + 2;
            }
            else if(c1 != -1  && c2 != -1 && c3 == -1)
            {
                // 1 more cell to the end of the path
                // move forward
                // then stop
                command[j] = 'f';
                command[j+1] = 'x';
                command[j+2] ='n';
                /*printf("%c\n", command[j]);
                printf("%c\n", command[j+1]);
                printf("%c\n", command[j+2]);*/
                j = j + 3;
            }

        }

    }


}

