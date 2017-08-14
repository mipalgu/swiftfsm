#include <CLReflectAPI.h>    

void* createMachine(void*);

void* createMetaMachine(void*, void*);

void registerMetaMachine(refl_metaMachine, unsigned int);

void incrementNumberOfMachines(void*);

void initCLReflectAPI();

void invokeOnEntry(void*, unsigned int);

void loadMachine(void*, void*, unsigned int);
