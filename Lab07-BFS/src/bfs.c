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

void push_front(list_t* list, int rank)
{
    // create a new element
    list_element_t *tmp = (list_element_t*)malloc(sizeof(list_element_t));
    assert(tmp != NULL);
    tmp->rank = rank;
    tmp->next = NULL;

    // update
    // if a list is empty
    if(!list->head)
    {

        list->head = tmp;
        list->tail = tmp;
    }
    else
    {

        tmp->next = list->head;
        list->head = tmp;
    }
}
void push_back(list_t* list, int rank)
{
    // create a new element
    list_element_t *tmp = (list_element_t*)malloc(sizeof(list_element_t));
    assert(tmp != NULL);
    tmp->rank = rank;
    tmp->next = NULL;


    // update
    // if a list is empty
    if(!list->head)
    {

        list->head = tmp;
        list->tail = tmp;
    }
    else
    {

        // set the next reference of the tail to
        // point to new element
        list->tail->next = tmp;
        // assign the tail reference itself to new element
        list->tail = tmp;
    }


}
/*
void free_list(list_t *list)
{
    list_element_t *cursor;
    cursor = list->head;
    while(cursor != NULL)
    {
        free(cursor);
        cursor = cursor->next;
    }
    list_t newlist = init_list();
    list = &newlist;
}*/
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

    int row0 = ROW(rank);
    int col0 = COL(rank);
    printf("row0 = %d, col0 = %d\n", row0, col0);
    int row, col;

    // set rank of 8 neighbors of (row, col) to 0 - 7
    // 0
    // north
    // same col, different row
    row = row0 - 1;
    col = col0;

    // 0
    printf("north row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[0] = -1;

    }
    else
    {
        neighbors[0] = RANK(row, col);
    }

    // north east neigbor
    // 1
    col = col + 1;
    printf("north east row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[1] = -1;

    }
    else
    {
        neighbors[1] = RANK(row, col);
    }

    // 2
    //  east
    // same row, different column
    row = row0;
    col = col0 + 1;
    printf("east row = %d, col = %d\n", row, col);

    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[2] = -1;

    }
    else
    {
        neighbors[2] = RANK(row, col);
    }

    // 3
    // south east
    row = row + 1;
    printf("south east row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[3] = -1;

    }
    else
    {
        neighbors[3] = RANK(row, col);
    }
    // 4
    //  south
    // same column, different row
    col = col0;
    row = row0 + 1;
    printf("south row = %d, col = %d\n", row, col);

    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[4] = -1;

    }
    else
    {
        neighbors[4] = RANK(row, col);
    }

    // 5
    // south west
    col = col - 1;
    printf("south west row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[5] = -1;

    }
    else
    {
        neighbors[5] = RANK(row, col);
    }

    // 6
    //west
    // same row, different column
    row = row0;
    col = col0 - 1;
    printf(" west row = %d, col = %d\n", row, col);

    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[6] = -1;

    }
    else
    {
        neighbors[6]= RANK(row, col);
    }

    // 7
    // north west
    row = row - 1;
    printf("north west row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        neighbors[7] = -1;

    }
    else
    {
        neighbors[7]= RANK(row, col);
    }


}
void fill_neighbors(int neighbors[], int rank)
{

    int row0 = ROW(rank);
    int col0 = COL(rank);
    //printf("row0 = %d, col0 = %d\n", row0, col0);
    int row, col;
    // set rank of 4 neighbors of (row, col) to 0 - 3
    // neighbor 1; north
    // same col, different row
    row = row0 - 1;
    col = col0;
    list_element_t *north = (list_element_t*)malloc(sizeof(list_element_t));
    //printf("row = %d, col = %d\n", row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        north ->rank = -1;

    }
    else
    {
        north ->rank = RANK(row, col);
    }
    // neighbor 2; east
    // same row, different column
    row = row0;
    col = col0 + 1;
    //printf("row = %d, col = %d\n", row, col);
    list_element_t *east = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp2 ->rank = 1;
    //east ->rank = RANK(row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        east ->rank = -1;

    }
    else
    {
        east ->rank = RANK(row, col);
    }
    // neighbor 3, south
    // same column, different row
    col = col0;
    row = row0 + 1;
    //printf("row = %d, col = %d\n", row, col);
    list_element_t *south = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp3 ->rank = 2;
    //south ->rank = RANK(row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        south ->rank = -1;

    }
    else
    {
        south ->rank = RANK(row, col);
    }
    // neighbor 4, west
    // same row, different column
    row = row0;
    col = col0 - 1;
    //printf("row = %d, col = %d\n", row, col);
    list_element_t *west = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp4 ->rank = 3;
    //west ->rank = RANK(row, col);
    if(row > MAZE_WIDTH || row < 0 || col > MAZE_WIDTH || col < 0)
    {
        west ->rank = -1;

    }
    else
    {
        west ->rank = RANK(row, col);
    }

    neighbors[0] = north->rank;
    neighbors[1] = east->rank;
    neighbors[2] = south->rank;
    neighbors[3] = west->rank;


}
int remove_front(list_t* list)
{
    list_element_t *element;

    if(!list->head)
    {
        return -1;
    }
    else if(list->head == list->tail) // the last element is removed
    {
        element = list->head;
        free(element);
        list_t newlist = init_list();
        list = &newlist;
    }
    else
    {
        element = list->head;
        list->head = list->head->next;
        //delete element;
        free(element);

    }
    return 1;
}

int remove_item(list_t* list, list_element_t* previous_element)
{
    list_element_t *element;
    if(!list->head)
    {
        return -1;
    }
    else if(list->head == list->tail) // the last element is removed
    {
        element = list->head;
        free(element);
        list_t newlist = init_list();
        list = &newlist;
    }
    else
    {
        element = previous_element->next;
        previous_element->next = element->next;

        free(element);
    }

    return 1;
}

int insideList(list_t* list, int rank)
{
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
    return flag;
}

/*
int remove_item(list_t* list, list_element_t* item)
{
    list_element_t *element;
    if(!list->head)
    {
        return -1;
    }
    else if(list->head == list->tail) // the last element is removed
    {
        element = list->head;
        free(element);
        list_t newlist = init_list();
        list = &newlist;
    }
    else
    {
        element = item;
        item->next = element->next;

        free(element);
    }

    return 1;
}
*/
int manhattanDistance(int xa, int ya, int xb, int yb)
{
    return abs(xa - xb) + abs(ya - yb);
}

int euclideanDistance(int xa, int ya, int xb, int yb)
{
    return sqrt(pow((xa - xb), 2) + pow((ya - yb), 2));
}

int findMin(int a[], int n)
{
    int guard = a[0];
    for(int i  = 1; i < n; i++ )
    {
        if(a[i] < guard)
        {
            guard = a[i];
        }
    }
    return guard;
}
void find_shortest_path_A_star(int start_rank, int goal_rank, const int obstacles[])
{
    int predecessors[ELEMENT_COUNT];
    int totalCost[ELEMENT_COUNT];  // hold total cost for each node
    int actualCost[ELEMENT_COUNT];  // hold g cost for each node
    int estimateCost[ELEMENT_COUNT];  // hold h cost for each node

    for(int i = 0; i < ELEMENT_COUNT; i++)
    {
        if(obstacles[i] == 1)
        {
            predecessors[i] = -2;
        }
        else
        {
            predecessors[i] = -1;
        }

    }

    predecessors[start_rank] = start_rank;

    for(int i = 0; i < ELEMENT_COUNT; i++)
    {
        actualCost[i] = -1;
        totalCost[i] = -1;
        estimateCost[i] = -1;
    }

    int neighbors[8];
    int neighbors_cost[8]; // hold actual cost for each neigbors
    int g, h, f;
    int index;
    list_t open = init_list();
    list_t close = init_list();

    list_t list = init_list();

    list_t path = init_list(); // store the path
    push_back(&list, start_rank);
    //push_back(&path, start_rank);

    // Add start node to open list
    push_back(&open, start_rank);

    // loop through open list
    while(open.head != NULL)
    {
        // get a node n off open list with the lowest f(n)
        // get smallest total cost in open list

        list_element_t *current = open.head;
        while(open.head != NULL)
        {
            if(totalCost[open.head->rank] < totalCost[current->rank])
            {
                current = open.head;
            }
            open.head = open.head -> next;
        }
        // Have a node, which has smallest total cost
        // remove it from open list
        //remove_front(&open);
        list_element_t * previous = (list_element_t*)malloc(sizeof(list_element_t));;
        previous->next = current;
        remove_item(&open, previous);
        // Add a node n to close list
        //push_back(&close, open.head->rank); // node is checked
        push_back(&close, current->rank);
        //if(list.head->rank == goal_rank)
        if(current->rank == goal_rank)
        {
            // found a goal
            push_back(&path, current->rank);
            break;
        }
        else
        {
            // generate neighbors of a node n
            fill_neighbors(neighbors, list.head->rank);
            for(int i = 0; i < 8; i++)
            {
                index = neighbors[i]; // get index of corresponding cell on predecessors array

                // if a neighbor is accessible
                // not out of bound or obstacle
                if(neighbors[i] != -1 && predecessors[index] == -1)
                {
                    // calculate g(n), h(n), f(n) for a neighbor
                    // actual cost from start point to a node n
                    g = manhattanDistance(ROW(start_rank), COL(start_rank), ROW(neighbors[i]), COL(neighbors[i]));
                    actualCost[index] = g;
                    // estimate cost from a node n to goal point
                    h = manhattanDistance(ROW(neighbors[i]), COL(neighbors[i]), ROW(goal_rank), COL(goal_rank));
                    estimateCost[index] = h;
                    // total cost
                    f = g + h;
                    neighbors_cost[i] = f;
                    totalCost[index] = f;

                    // if a node in close list
                    // skip it
                    if(insideList(&open, neighbors[i]) == 1)
                    {
                        // skip
                    }

                    // if a node in open list
                    // skip it
                    else if(insideList(&close, neighbors[i]) == 1)
                    {
                        // skip
                    }
                    else
                    {
                        // add neighbor to open list
                        // if a node is not in a open list
                        push_back(&open, neighbors[i]);
                        push_back(&path, neighbors[i]);
                    }

                }
                else
                {
                    neighbors_cost[i] = -1;
                    i++; // skip a neighbor
                }

            }

        }
        list.head = list.head->next;

    }


    //int index;
    //printstr("process path\n");
    /*
    while(list.head != NULL)
    {
        //printstr("fill_neighbors\n");
        fill_neighbors(neighbors, list.head->rank);
        //
        printf("rank = %d\n", list.head->rank);
        for(int k = 0; k < 4; k++)
        {
            printf("neighbors[%d] = %d\n", k, neighbors[k]);
        }

        //
        for(int i = 0; i < 4; i++)
        {

            index = neighbors[i]; // get index of corresponding cell on predecessors array

            if(neighbors[i] != -1 && predecessors[index] == -1)
            {
                //printf("index = %d\n", index);
                //printstr("push_back\n");
                push_back(&list, neighbors[i]);
                predecessors[index] = neighbors[i]; // have a rank being considered
                //printf("predecessors[%d] = %d\n", index, neighbors[i]);
                //index = neighbors[i];
                //obstacles[index] = -1; // not sure here
            }
        }

        // store path
        //push_front(path, list->head->rank);


        remove_front(&list);
        if(list.head->rank == goal_rank)
        {
            break;
        }
        list.head = list.head->next;

    }
    */
    //printstr("recover path\n");
    // recover & print the path
    //printf("goal_rank = %d\n", goal_rank);
    //printf("start_rank = %d\n", start_rank);
    //for(int i = goal_rank; i < ELEMENT_COUNT; i++)
    /*
    for(int i = goal_rank; i <= start_rank; i++)
    {

        if(predecessors[i] > -1 )
        {
            //printf("predecessors[i] = %d\n", predecessors[i]);
            push_front(&path, predecessors[i]);
        }
    }
    */
    //int r, c;
    int rank;
    printstr("create path\n");

    int col, row;
    while(path.head != NULL)
    {

        rank = path.head->rank;
        //printf("rank = %d \n", rank);
        row = ROW(rank);
        col = COL(rank);
        printf("(%d, %d) \n", row, col);
        path.head = path.head->next;
    }
    free_list(&list);
    free_list(&path);
    free_list(&open);
    free_list(&close);

}
void find_shortest_path_bfs(int start_rank, int goal_rank, const int obstacles[])
{
    int predecessors[ELEMENT_COUNT];

    for(int i = 0; i < ELEMENT_COUNT; i++)
    {
        if(obstacles[i] == 1)
        {
            predecessors[i] = -2;
        }
        else
        {
            predecessors[i] = -1;
        }

    }

    predecessors[start_rank] = start_rank;

    //list_t newlist = init_list();
    list_t list = init_list();
    //list_t newlist2 = init_list();
    list_t path = init_list(); // store the path
    push_back(&list, start_rank);

    int neighbors[4];

    int index;
    //printstr("process path\n");
    while(list.head != NULL)
    {
        //printstr("fill_neighbors\n");
        fill_neighbors(neighbors, list.head->rank);
        //
        /*printf("rank = %d\n", list.head->rank);
        for(int k = 0; k < 4; k++)
        {
            printf("neighbors[%d] = %d\n", k, neighbors[k]);
        }
        */
        //
        for(int i = 0; i < 4; i++)
        {

            index = neighbors[i]; // get index of corresponding cell on predecessors array

            if(neighbors[i] != -1 && predecessors[index] == -1)
            {
                //printf("index = %d\n", index);
                //printstr("push_back\n");
                push_back(&list, neighbors[i]);
                predecessors[index] = neighbors[i]; // have a rank being considered
                //printf("predecessors[%d] = %d\n", index, neighbors[i]);
                //index = neighbors[i];
                //obstacles[index] = -1; // not sure here
            }
        }

        // store path
        //push_front(path, list->head->rank);


        remove_front(&list);
        if(list.head->rank == goal_rank)
        {
            break;
        }
        list.head = list.head->next;

    }

    printstr("recover path\n");
    // recover & print the path
    //printf("goal_rank = %d\n", goal_rank);
    //printf("start_rank = %d\n", start_rank);
    //for(int i = goal_rank; i < ELEMENT_COUNT; i++)
    for(int i = goal_rank; i <= start_rank; i++)
    {

        if(predecessors[i] > -1 )
        {
            //printf("predecessors[i] = %d\n", predecessors[i]);
            push_front(&path, predecessors[i]);
        }
    }

    //int r, c;
    int rank;
    printstr("create path\n");

    int col, row;
    //rank = 98;
    //row = ROW(rank);
    //col = COL(rank);
    //printf("(%d, %d) \n", row, col);
    //rank = 75;
    //row = ROW(rank);
    //col = COL(rank);
    //printf("(%d, %d) \n", row, col);
    while(path.head != NULL)
    {

        rank = path.head->rank;
        //printf("rank = %d \n", rank);
        row = ROW(rank);
        col = COL(rank);
        printf("(%d, %d) \n", row, col);
        path.head = path.head->next;
    }
    free_list(&list);
    free_list(&path);


}

void find_shortest_path(int start_rank, int goal_rank, const int obstacles[], int flag)
{
    if(flag == 0)
    {
        find_shortest_path_bfs(start_rank, goal_rank, obstacles);
    }
    if(flag == 1)
    {
        find_shortest_path_A_star(start_rank, goal_rank, obstacles);
    }
}
int test_main()
{
    // test init_list()
    list_t l1;
    l1 = init_list();
    assert(l1.head == l1.tail && l1.head == NULL);
    // test push_back
    push_back(&l1, 10);
    assert(l1.head != NULL);
    assert(l1.tail == l1.head);
    assert(l1.head->rank == 10);
    assert(l1.head->next == NULL);

    push_back(&l1, 20);
    assert(l1.head != l1.tail);
    assert(l1.head->rank == 10);
    assert(l1.head->next == l1.tail);
    assert(l1.tail->rank == 20);
    assert(l1.tail->next == NULL);

    // test free_list
    free_list(&l1);
    assert(l1.head == l1.tail && l1.head == NULL);

    // remove_front
    list_t l2;
    l2 = init_list();
    push_back(&l2, 10);
    push_back(&l2, 20);
    remove_front(&l2);
    assert(l2.head != NULL);
    assert(l2.tail == l2.head);
    assert(l2.head->rank == 20);
    assert(l2.head->next == NULL);

    // test remove the last element on the list
    list_t l3;
    l3 = init_list();
    remove_front(&l3);
    assert(l3.tail == l3.head & l3.head == NULL);
    // test remove_front if a list is empty
    assert(remove_front(&l3) == -1);

    // test for push_front
    list_t l4 = init_list();
    assert(l4.tail == l4.head & l4.head == NULL);
    push_front(&l4, 10);
    assert(l4.head != NULL);
    assert(l4.tail == l4.head);
    assert(l4.head->rank == 10);
    assert(l4.head->next == NULL);

    push_front(&l4, 20);
    assert(l4.head != NULL);
    assert(l4.head->rank == 20);
    assert(l4.head->next->rank == 10);
    return 0;
}






