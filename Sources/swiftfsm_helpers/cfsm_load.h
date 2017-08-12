#include <CLReflectAPI.h>    

void* testMachineFactory(void*);

void* testCreateMetaMachine(void*);

void* createScheduledMetaMachine(void*, void*);

void registerMetaMachine(void* metaMachine, unsigned int machineID);

void incrementNumberOfMachines(void*);
