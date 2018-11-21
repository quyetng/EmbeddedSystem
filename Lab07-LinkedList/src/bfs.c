#include <stdlib.h>
#include <bfs.h>
#include <assert.h>
#include <print.h>

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

/*void fill_neighbors(int neighbors[], int rank)
{

    int row0 = ROW(rank);
    int col0 = COL(rank);

    int row, col;
    // set rank of 4 neighbors of (row, col) to 0 - 3
    // neighbor 1; north
    // same col, different row
    row = row0 -1;
    col = col0;
    list_element_t *north = (list_element_t*)malloc(sizeof(list_element_t));
    north ->rank = RANK(row, col);
    if(row > MAZE_WIDTH || col > MAZE_WIDTH)
    {
        north ->rank = -1;

    }
    else if(row < MAZE_WIDTH || col < MAZE_WIDTH)
    {
        north ->rank = -1;
    }
    // neighbor 2; east
    // same row, different column
    row = row0;
    col = col0 + 1;
    list_element_t *east = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp2 ->rank = 1;
    east ->rank = RANK(row, col);
    if(row > MAZE_WIDTH || col > MAZE_WIDTH)
    {
        east ->rank = -1;

    }
    else if(row < MAZE_WIDTH || col < MAZE_WIDTH)
    {
        east ->rank = -1;
    }
    // neighbor 3, south
    // same column, different row
    col = col0;
    row = row0 + 1;
    list_element_t *south = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp3 ->rank = 2;
    south ->rank = RANK(row, col);
    if(row > MAZE_WIDTH || col > MAZE_WIDTH)
    {
        south ->rank = -1;

    }
    else if(row < MAZE_WIDTH || col < MAZE_WIDTH)
    {
        south ->rank = -1;
    }
    // neighbor 4, west
    // same row, different column
    row = row0;
    col = col0 -1;
    list_element_t *west = (list_element_t*)malloc(sizeof(list_element_t));
    //tmp4 ->rank = 3;
    west ->rank = RANK(row, col);
    if(row > MAZE_WIDTH || col > MAZE_WIDTH)
    {
        west ->rank = -1;

    }
    else if(row < MAZE_WIDTH || col < MAZE_WIDTH)
    {
        west ->rank = -1;
    }

    neighbors[0] = north->rank;
    neighbors[1] = east->rank;
    neighbors[2] = south->rank;
    neighbors[3] = west->rank;




}*/
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

    // test fill_neighbors
    int neighbors[4];
    fill_neighbors(neighbors, 121);

    int result[4] = {-1, -1, -1, -1};
    for(int i = 0; i < 4; i++)
    {
        if(neighbors[i] != result[i])
        {
            printstr("fail\n");
        }
    }
    //assert(result == neighbors);
    return 0;
}






