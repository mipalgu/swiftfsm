#include <stdbool.h>

int loadMachine(void*, const char*, bool);

bool unloadMachine(void*, int);

void destroyCFSM(void*);

int* getLoadedMachines(void*);

int numberOfLoadedMachines(void*);

void emptyLoadedMachines(void*);

bool checkUnloadedMachines(void*, int);

