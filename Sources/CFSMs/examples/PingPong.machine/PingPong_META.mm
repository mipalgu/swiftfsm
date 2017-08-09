#pragma clang diagnostic ignored "-Wunused-parameter"

#include <CLReflect/CLReflectAPI.h>
#include <sstream>
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <stdint.h>
#include <gufsm/clfsm/clfsm_machine_loader.h>
#include <gufsm/gufsm/FSMachine.h>
#include "PingPong_Includes.h"
#include "State_Initial.h"
#include "State_Initial_Includes.h"
#include "State_Suspend.h"
#include "State_Suspend_Includes.h"
#include "State_Ping.h"
#include "State_Ping_Includes.h"
#include "State_State_1.h"
#include "State_State_1_Includes.h"
#include "PingPong.h"

using namespace FSM;
using namespace CLM;
using namespace FSMPingPong;
using namespace State;

extern "C"
{
	static unsigned int machineID;
	refl_metaMachine Create_MetaMachine();
	refl_metaMachine Create_ScheduledMetaMachine();
}

// Action Declarations
void PingPong_destroy(refl_machine_t machine, refl_userData_t data);
void PingPong_executeCurrentState(refl_machine_t machine, refl_userData_t data);
void Initial_OnEntry(refl_machine_t machine, refl_userData_t data);
void Initial_Internal(refl_machine_t machine, refl_userData_t data);
void Initial_OnExit(refl_machine_t machine, refl_userData_t data);
void Suspend_OnEntry(refl_machine_t machine, refl_userData_t data);
void Suspend_Internal(refl_machine_t machine, refl_userData_t data);
void Suspend_OnExit(refl_machine_t machine, refl_userData_t data);
void Ping_OnEntry(refl_machine_t machine, refl_userData_t data);
void Ping_Internal(refl_machine_t machine, refl_userData_t data);
void Ping_OnExit(refl_machine_t machine, refl_userData_t data);
void State_1_OnEntry(refl_machine_t machine, refl_userData_t data);
void State_1_Internal(refl_machine_t machine, refl_userData_t data);
void State_1_OnExit(refl_machine_t machine, refl_userData_t data);

// Action Implementations
void PingPong_destroy(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	delete thisMachine;
}

void PingPong_executeCurrentState(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Machine* m = thisMachine->machineContext();
	m->executeOnce();
}

void Initial_OnEntry(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Initial* thisState = static_cast<Initial*>(thisMachine->states()[0]);
	thisState->performOnEntry(thisMachine);
}
void Initial_Internal(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Initial* thisState = static_cast<Initial*>(thisMachine->states()[0]);
	thisState->performInternal(thisMachine);
}
void Initial_OnExit(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Initial* thisState = static_cast<Initial*>(thisMachine->states()[0]);
	thisState->performOnExit(thisMachine);
}
void Suspend_OnEntry(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Suspend* thisState = static_cast<Suspend*>(thisMachine->states()[1]);
	thisState->performOnEntry(thisMachine);
}
void Suspend_Internal(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Suspend* thisState = static_cast<Suspend*>(thisMachine->states()[1]);
	thisState->performInternal(thisMachine);
}
void Suspend_OnExit(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Suspend* thisState = static_cast<Suspend*>(thisMachine->states()[1]);
	thisState->performOnExit(thisMachine);
}
void Ping_OnEntry(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->states()[2]);
	thisState->performOnEntry(thisMachine);
}
void Ping_Internal(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->states()[2]);
	thisState->performInternal(thisMachine);
}
void Ping_OnExit(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->states()[2]);
	thisState->performOnExit(thisMachine);
}
void State_1_OnEntry(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	State_1* thisState = static_cast<State_1*>(thisMachine->states()[3]);
	thisState->performOnEntry(thisMachine);
}
void State_1_Internal(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	State_1* thisState = static_cast<State_1*>(thisMachine->states()[3]);
	thisState->performInternal(thisMachine);
}
void State_1_OnExit(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	State_1* thisState = static_cast<State_1*>(thisMachine->states()[3]);
	thisState->performOnExit(thisMachine);
}

// Transition Evaluation Declarations
refl_bool Initial_Transition_0(refl_machine_t machine, refl_userData_t data);
refl_bool Ping_Transition_0(refl_machine_t machine, refl_userData_t data);
refl_bool State_1_Transition_0(refl_machine_t machine, refl_userData_t data);

// Transition Evaluation Implementations
refl_bool Initial_Transition_0(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Initial* thisState = static_cast<Initial*>(thisMachine->states()[0]);
	CLTransition* thisTrans = thisState->transition(0);
	if (thisTrans->check(thisMachine, thisState))
	{
		return refl_TRUE;
	}
	else
	{
		return refl_FALSE;
	}
}

refl_bool Ping_Transition_0(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->states()[2]);
	CLTransition* thisTrans = thisState->transition(0);
	if (thisTrans->check(thisMachine, thisState))
	{
		return refl_TRUE;
	}
	else
	{
		return refl_FALSE;
	}
}

refl_bool State_1_Transition_0(refl_machine_t machine, refl_userData_t data)
{
	PingPong* thisMachine = static_cast<PingPong*>(machine);
	State_1* thisState = static_cast<State_1*>(thisMachine->states()[3]);
	CLTransition* thisTrans = thisState->transition(0);
	if (thisTrans->check(thisMachine, thisState))
	{
		return refl_TRUE;
	}
	else
	{
		return refl_FALSE;
	}
}


// Property Access Declarations

// Property Access Implementations
// Creation script
refl_metaMachine Create_MetaMachine()
{
	refl_metaMachine m = refl_initMetaMachine(NULL);
	refl_setMetaMachineName(m, "PingPong", NULL);
	refl_metaState states[4];

	
	//State: Initial
	refl_metaState ms_Initial = refl_initMetaState(NULL);
	refl_setMetaStateName(ms_Initial, "Initial", NULL);

	refl_metaAction ma_Initial_OnEntry = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Initial_OnEntry, Initial_OnEntry, NULL);
	refl_setOnEntry(ms_Initial, ma_Initial_OnEntry, NULL);
	refl_metaAction ma_Initial_Internal = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Initial_Internal, Initial_Internal, NULL);
	refl_setInternal(ms_Initial, ma_Initial_Internal, NULL);
	refl_metaAction ma_Initial_OnExit = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Initial_OnExit, Initial_OnExit, NULL);
	refl_setOnExit(ms_Initial, ma_Initial_OnExit, NULL);
	states[0] = ms_Initial;
	refl_metaTransition Initial_transitions[1];
	refl_metaTransition mt_Initial_T_0 = refl_initMetaTransition(NULL);
	refl_setMetaTransitionSource(mt_Initial_T_0, 0, NULL);
	refl_setMetaTransitionTarget(mt_Initial_T_0, 2, NULL);
	refl_setMetaTransitionExpression(mt_Initial_T_0, "true", NULL);
	refl_transitionEval_f mt_Initial_T_0_eval_f = Initial_Transition_0;
	refl_setMetaTransitionEvalFunction(mt_Initial_T_0, mt_Initial_T_0_eval_f, NULL, NULL);
	Initial_transitions[0] = mt_Initial_T_0;
	refl_setMetaTransitions(ms_Initial, Initial_transitions, 1, NULL);
	
	//State: Suspend
	refl_metaState ms_Suspend = refl_initMetaState(NULL);
	refl_setMetaStateName(ms_Suspend, "Suspend", NULL);

	refl_metaAction ma_Suspend_OnEntry = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Suspend_OnEntry, Suspend_OnEntry, NULL);
	refl_setOnEntry(ms_Suspend, ma_Suspend_OnEntry, NULL);
	refl_metaAction ma_Suspend_Internal = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Suspend_Internal, Suspend_Internal, NULL);
	refl_setInternal(ms_Suspend, ma_Suspend_Internal, NULL);
	refl_metaAction ma_Suspend_OnExit = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Suspend_OnExit, Suspend_OnExit, NULL);
	refl_setOnExit(ms_Suspend, ma_Suspend_OnExit, NULL);
	states[1] = ms_Suspend;
	
	//State: Ping
	refl_metaState ms_Ping = refl_initMetaState(NULL);
	refl_setMetaStateName(ms_Ping, "Ping", NULL);

	refl_metaAction ma_Ping_OnEntry = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Ping_OnEntry, Ping_OnEntry, NULL);
	refl_setOnEntry(ms_Ping, ma_Ping_OnEntry, NULL);
	refl_metaAction ma_Ping_Internal = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Ping_Internal, Ping_Internal, NULL);
	refl_setInternal(ms_Ping, ma_Ping_Internal, NULL);
	refl_metaAction ma_Ping_OnExit = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Ping_OnExit, Ping_OnExit, NULL);
	refl_setOnExit(ms_Ping, ma_Ping_OnExit, NULL);
	states[2] = ms_Ping;
	refl_metaTransition Ping_transitions[1];
	refl_metaTransition mt_Ping_T_0 = refl_initMetaTransition(NULL);
	refl_setMetaTransitionSource(mt_Ping_T_0, 2, NULL);
	refl_setMetaTransitionTarget(mt_Ping_T_0, 3, NULL);
	refl_setMetaTransitionExpression(mt_Ping_T_0, "after(1)", NULL);
	refl_transitionEval_f mt_Ping_T_0_eval_f = Ping_Transition_0;
	refl_setMetaTransitionEvalFunction(mt_Ping_T_0, mt_Ping_T_0_eval_f, NULL, NULL);
	Ping_transitions[0] = mt_Ping_T_0;
	refl_setMetaTransitions(ms_Ping, Ping_transitions, 1, NULL);
	
	//State: State_1
	refl_metaState ms_State_1 = refl_initMetaState(NULL);
	refl_setMetaStateName(ms_State_1, "State_1", NULL);

	refl_metaAction ma_State_1_OnEntry = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_State_1_OnEntry, State_1_OnEntry, NULL);
	refl_setOnEntry(ms_State_1, ma_State_1_OnEntry, NULL);
	refl_metaAction ma_State_1_Internal = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_State_1_Internal, State_1_Internal, NULL);
	refl_setInternal(ms_State_1, ma_State_1_Internal, NULL);
	refl_metaAction ma_State_1_OnExit = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_State_1_OnExit, State_1_OnExit, NULL);
	refl_setOnExit(ms_State_1, ma_State_1_OnExit, NULL);
	states[3] = ms_State_1;
	refl_metaTransition State_1_transitions[1];
	refl_metaTransition mt_State_1_T_0 = refl_initMetaTransition(NULL);
	refl_setMetaTransitionSource(mt_State_1_T_0, 3, NULL);
	refl_setMetaTransitionTarget(mt_State_1_T_0, 2, NULL);
	refl_setMetaTransitionExpression(mt_State_1_T_0, "after(1)", NULL);
	refl_transitionEval_f mt_State_1_T_0_eval_f = State_1_Transition_0;
	refl_setMetaTransitionEvalFunction(mt_State_1_T_0, mt_State_1_T_0_eval_f, NULL, NULL);
	State_1_transitions[0] = mt_State_1_T_0;
	refl_setMetaTransitions(ms_State_1, State_1_transitions, 1, NULL);
	refl_setMetaStates(m, states, 4, NULL);
	refl_setCurrentState(m, 0, NULL);
	refl_setSuspendState(m, 1, NULL);
	return m;
}
// Scheduled Creation script
refl_metaMachine Create_ScheduledMetaMachine()
{
	machineID = number_of_machines() < 0 ? 0 : static_cast<unsigned int>(number_of_machines());
	CLFSMMachineLoader::CLFSMMachineLoader* loader = CLFSMMachineLoader::getMachineLoaderSingleton();
	loader->loadAndAddMachineAtPath("/home/bren/src/MiPal/GUNao/posix/swiftfsm/swiftfsm/Sources/CFSMs/examples/PingPong.machine");
	CLMachine* machine = machine_at_index(machineID);
	refl_metaMachine metaMachine = Create_MetaMachine();
	refl_setMachine(metaMachine, machine, NULL);
	refl_setExecuteAction(metaMachine, PingPong_executeCurrentState, NULL);
	refl_setDestructorAction(metaMachine, PingPong_destroy, NULL);
	return metaMachine;
}
#pragma clang diagnostic pop
