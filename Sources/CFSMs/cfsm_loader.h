#include "CLMacros.h"
#include <vector>
//#include "CLMachine.h"

// Header guard.
#ifndef _CFSM_LOADER_INCLUDED_
#define _CFSM_LOADER_INCLUDED_


extern std::vector<FSM::CLMachine*> finite_state_machines;

extern "C"
{
int C_loadAndAddMachine(const char *machine, bool initiallySuspended);

bool C_unloadMachineAtIndex(int index);

void _C_destroyCFSM();
}

FSM::Machine* createMachineContext(FSM::CLMachine *machine);

const char* getMachineNameFromPath(const char* path);

int smallestUnusedIndex;

namespace fsm
{
    int loadAndAddMachine(const char *machine, bool initiallySuspended);

    bool unloadMachineAtIndex(int index);
}

#endif // Header guard.
