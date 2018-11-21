#define MAZE_WIDTH (10)
#define ELEMENT_COUNT (MAZE_WIDTH*MAZE_WIDTH)

#define RANK(row, col) ((row)*MAZE_WIDTH + (col))
#define ROW(rank) ((rank)/MAZE_WIDTH)
#define COL(rank) ((rank)%MAZE_WIDTH)

//int RankArr[ELEMENT_COUNT];
int test_main();
//void free_list(list_t *list);
void find_shortest_path(int start_rank, int goal_rank, const int obstacles[], int flag);
//void find_shortest_path_A_star(int start_rank, int goal_rank, const int obstacles[]);
void fill_neighbors_A_star(int [], int);
void find_shortest_path_A_star(int start_rank, int goal_rank, const int obstacles[], int rankArr[]);
// Path
void generatePath(int rankArr[]);
// Command
void generateCommand(int ranArr[], char command[]);
