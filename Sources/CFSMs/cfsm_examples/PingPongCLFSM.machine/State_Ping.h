//
// State_Ping.h
//
// Automatically created through MiCASE -- do not change manually!
//
#ifndef clfsm_PingPongCLFSM_State_Ping_h
#define clfsm_PingPongCLFSM_State_Ping_h

#include "CLState.h"
#include "CLAction.h"
#include "CLTransition.h"

namespace FSM
{
    namespace CLM
    {
      namespace FSMPingPongCLFSM
      {
        namespace State
        {
            class Ping: public CLState
            {
                class OnEntry: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class OnExit: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class Internal: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class Transition_0: public CLTransition
                {
                public:
                    Transition_0(int toState = 1): CLTransition(toState) {}

                    virtual bool check(CLMachine *, CLState *) const;
                };

                CLTransition *_transitions[1];

                public:
                    Ping(const char *name = "Ping");
                    virtual ~Ping();

                    virtual CLTransition * const *transitions() const { return _transitions; }
                    virtual int numberOfTransitions() const { return 1; }

#                   include "State_Ping_Variables.h"
            };
        }
      }
    }
}

#endif
