//
// NewMachine.h
//
// Automatically created through MiPalCASE -- do not change manually!
//
#ifndef clfsm_machine_NewMachine_
#define clfsm_machine_NewMachine_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class NewMachine: public CLMachine
        {
            CLState *_states[4];
        public:
            NewMachine(int mid  = 0, const char *name = "NewMachine");
            virtual ~NewMachine();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 4; }
#           include "NewMachine_Variables.h"
#           include "NewMachine_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::NewMachine *CLM_Create_NewMachine(int mid, const char *name);
}

#endif // defined(clfsm_machine_NewMachine_)
