//
// PingPong.h
//
// Automatically created through MiPalCASE -- do not change manually!
//
#ifndef clfsm_machine_PingPong_
#define clfsm_machine_PingPong_

#include "CLMachine.h"

namespace FSM
{
    class CLState;

    namespace CLM
    {
        class PingPong: public CLMachine
        {
            CLState *_states[4];
        public:
            PingPong(int mid  = 0, const char *name = "PingPong");
            virtual ~PingPong();
            virtual CLState * const * states() const { return _states; }
            virtual int numberOfStates() const { return 4; }
#           include "PingPong_Variables.h"
#           include "PingPong_Methods.h"
        };
    }
}

extern "C"
{
    FSM::CLM::PingPong *CLM_Create_PingPong(int mid, const char *name);
}

#endif // defined(clfsm_machine_PingPong_)
