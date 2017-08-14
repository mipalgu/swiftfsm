#include <CLReflectAPI.h>    

void* createMachine(void*);

void* createMetaMachine(void*, void*);

void registerMetaMachine(void* metaMachine, unsigned int machineID);

void incrementNumberOfMachines(void*);
