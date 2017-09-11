#include <stdbool.h>

int loadMachine(void*, const char*, bool);

bool unloadMachine(void*, int);

void destroyCFSM(void*);

int* getLoadedMachines(void*);

int* getUnloadedMachines(void*);

int numberOfLoadedMachines(void*);

