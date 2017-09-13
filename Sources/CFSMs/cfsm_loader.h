#include "CLMacros.h"
#include <vector>

// Header guard.
#ifndef _CFSM_LOADER_INCLUDED_
#define _CFSM_LOADER_INCLUDED_


extern std::vector<FSM::CLMachine*> finite_state_machines;

extern "C"
{
int C_numberOfDynamicallyLoadedMachines();

int C_numberOfDynamicallyUnloadedMachines();
    
int* C_getDynamicallyLoadedMachineIDs();

int* C_getDynamicallyUnloadedMachineIDs();

int C_loadAndAddMachine(const char *machine, bool initiallySuspended);

bool C_unloadMachineAtIndex(int index);

void C_emptyDynamicallyUnloadedMachineVector();

void C_emptyDynamicallyLoadedMachineVector();
}



FSM::Machine* createMachineContext(FSM::CLMachine *machine);

const char* getMachineNameFromPath(const char* path);

namespace fsm
{
    int loadAndAddMachine(const char *machine, bool initiallySuspended);

    bool unloadMachineAtIndex(int index);
}

#endif // Header guard.
