#include <CLReflectAPI.h>    

void* createMachine(void*);

void* createMetaMachine(void*, void*);

void registerMetaMachine(void*, unsigned int);

void incrementNumberOfMachines(void*);

void initCLReflectAPI();

void invokeOnEntry(void*, unsigned int);
