#pragma clang diagnostic ignored "-Wunused-parameter"

#include <CLReflect/CLReflectAPI.h>
#include <sstream>
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <stdint.h>
#include <gufsm/clfsm/clfsm_machine_loader.h>
#include <gufsm/gufsm/FSMachine.h>
#include "PingPongCLFSM_Includes.h"
#include "State_Ping.h"
#include "State_Ping_Includes.h"
#include "State_Pong.h"
#include "State_Pong_Includes.h"
#include "PingPongCLFSM.h"

using namespace FSM;
using namespace CLM;
using namespace FSMPingPongCLFSM;
using namespace State;

extern "C"
{
	static unsigned int machineID;
	refl_metaMachine Create_MetaMachine();
	refl_metaMachine Create_ScheduledMetaMachine();
}

// Action Declarations
void PingPongCLFSM_destroy(refl_machine_t machine, refl_userData_t data);
void PingPongCLFSM_executeCurrentState(refl_machine_t machine, refl_userData_t data);
void Ping_OnEntry(refl_machine_t machine, refl_userData_t data);
void Ping_Internal(refl_machine_t machine, refl_userData_t data);
void Ping_OnExit(refl_machine_t machine, refl_userData_t data);
void Pong_OnEntry(refl_machine_t machine, refl_userData_t data);
void Pong_Internal(refl_machine_t machine, refl_userData_t data);
void Pong_OnExit(refl_machine_t machine, refl_userData_t data);

// Action Implementations
void PingPongCLFSM_destroy(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	delete thisMachine;
}

void PingPongCLFSM_executeCurrentState(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Machine* m = thisMachine->machineContext();
	m->executeOnce();
}

void Ping_OnEntry(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->states()[0]);
	thisState->performOnEntry(thisMachine);
}
void Ping_Internal(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->states()[0]);
	thisState->performInternal(thisMachine);
}
void Ping_OnExit(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->states()[0]);
	thisState->performOnExit(thisMachine);
}
void Pong_OnEntry(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Pong* thisState = static_cast<Pong*>(thisMachine->states()[1]);
	thisState->performOnEntry(thisMachine);
}
void Pong_Internal(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Pong* thisState = static_cast<Pong*>(thisMachine->states()[1]);
	thisState->performInternal(thisMachine);
}
void Pong_OnExit(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Pong* thisState = static_cast<Pong*>(thisMachine->states()[1]);
	thisState->performOnExit(thisMachine);
}

// Transition Evaluation Declarations
refl_bool Ping_Transition_0(refl_machine_t machine, refl_userData_t data);
refl_bool Pong_Transition_0(refl_machine_t machine, refl_userData_t data);

// Transition Evaluation Implementations
refl_bool Ping_Transition_0(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->states()[0]);
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

refl_bool Pong_Transition_0(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Pong* thisState = static_cast<Pong*>(thisMachine->states()[1]);
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
void* mp_machine_currentState_getAsVoid(refl_machine_t machine, refl_userData_t data);
void mp_machine_currentState_setAsVoid(refl_machine_t machine, refl_userData_t data, void* value, size_t size);
char* mp_machine_currentState_getAsString(refl_machine_t machine, refl_userData_t data, char * buffer, unsigned int bufferLen);
void mp_machine_currentState_setAsString(refl_machine_t machine, refl_userData_t data, char * const value);
void* mp_Ping_stateName_getAsVoid(refl_machine_t machine, refl_userData_t data);
void mp_Ping_stateName_setAsVoid(refl_machine_t machine, refl_userData_t data, void* value, size_t size);
char* mp_Ping_stateName_getAsString(refl_machine_t machine, refl_userData_t data, char * buffer, unsigned int bufferLen);
void mp_Ping_stateName_setAsString(refl_machine_t machine, refl_userData_t data, char * const value);
void* mp_Pong_stateName_getAsVoid(refl_machine_t machine, refl_userData_t data);
void mp_Pong_stateName_setAsVoid(refl_machine_t machine, refl_userData_t data, void* value, size_t size);
char* mp_Pong_stateName_getAsString(refl_machine_t machine, refl_userData_t data, char * buffer, unsigned int bufferLen);
void mp_Pong_stateName_setAsString(refl_machine_t machine, refl_userData_t data, char * const value);

// Property Access Implementations
void* mp_machine_currentState_getAsVoid(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	return static_cast<void *>(&thisMachine->currentState);
}
void mp_machine_currentState_setAsVoid(refl_machine_t machine, refl_userData_t data, void* value, size_t size)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	memcpy(&thisMachine->currentState, value, size);
}
char* mp_machine_currentState_getAsString(refl_machine_t machine, refl_userData_t data, char * buffer, unsigned int bufferLen)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	snprintf(buffer, bufferLen, "%d", thisMachine->currentState);
	return buffer;
}
void mp_machine_currentState_setAsString(refl_machine_t machine, refl_userData_t data, char * const value)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	std::string stringVar(value);
	if (stringVar.length() != 0)
	{
		try
		{
			int testVar = static_cast<int>(stoi(stringVar));
			thisMachine->currentState = testVar;
		}
		catch (std::exception &e)
		{
			std::cerr << "Exception: " << e.what() << std::endl;
		}
	}
	else 
	{
		std::cout << "string length 0" << std::endl;
	}
}
void* mp_Ping_stateName_getAsVoid(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->state(0));
	return static_cast<void *>(&thisState->stateName);
}
void mp_Ping_stateName_setAsVoid(refl_machine_t machine, refl_userData_t data, void* value, size_t size)
{
}
char* mp_Ping_stateName_getAsString(refl_machine_t machine, refl_userData_t data, char * buffer, unsigned int bufferLen)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->state(0));
	snprintf(buffer, bufferLen, "%s", thisState->stateName);
	return buffer;
}
void mp_Ping_stateName_setAsString(refl_machine_t machine, refl_userData_t data, char * const value)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Ping* thisState = static_cast<Ping*>(thisMachine->state(0));
	std::string stringVar(value);
	if (stringVar.length() != 0)
	{
		try
		{
			memcpy(&thisState->stateName, &value, sizeof(char *));
		}
		catch (std::exception &e)
		{
			std::cerr << "Exception: " << e.what() << std::endl;
		}
	}
	else 
	{
		std::cout << "string length 0" << std::endl;
	}
}
void* mp_Pong_stateName_getAsVoid(refl_machine_t machine, refl_userData_t data)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Pong* thisState = static_cast<Pong*>(thisMachine->state(1));
	return static_cast<void *>(&thisState->stateName);
}
void mp_Pong_stateName_setAsVoid(refl_machine_t machine, refl_userData_t data, void* value, size_t size)
{
}
char* mp_Pong_stateName_getAsString(refl_machine_t machine, refl_userData_t data, char * buffer, unsigned int bufferLen)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Pong* thisState = static_cast<Pong*>(thisMachine->state(1));
	snprintf(buffer, bufferLen, "%s", thisState->stateName);
	return buffer;
}
void mp_Pong_stateName_setAsString(refl_machine_t machine, refl_userData_t data, char * const value)
{
	PingPongCLFSM* thisMachine = static_cast<PingPongCLFSM*>(machine);
	Pong* thisState = static_cast<Pong*>(thisMachine->state(1));
	std::string stringVar(value);
	if (stringVar.length() != 0)
	{
		try
		{
			memcpy(&thisState->stateName, &value, sizeof(char *));
		}
		catch (std::exception &e)
		{
			std::cerr << "Exception: " << e.what() << std::endl;
		}
	}
	else 
	{
		std::cout << "string length 0" << std::endl;
	}
}
// Creation script
refl_metaMachine Create_MetaMachine()
{
	refl_metaMachine m = refl_initMetaMachine(NULL);
	refl_setMetaMachineName(m, "PingPongCLFSM", NULL);
	refl_metaProperty machineProperties[1];
	refl_metaProperty mp_machine_currentState = refl_initMetaProperty(NULL);
	refl_setMetaPropertyName(mp_machine_currentState, "currentState", NULL);
	refl_setMetaPropertyTypeString(mp_machine_currentState, "int", NULL);
	refl_setIsMetaPropertyUnsigned(mp_machine_currentState, refl_FALSE, NULL);
	refl_setMetaPropertyIndirection(mp_machine_currentState, 0, NULL);
	refl_setMetaPropertyType(mp_machine_currentState, REFL_INT , NULL);
	refl_setMetaPropertyVoidFunctions(mp_machine_currentState, mp_machine_currentState_getAsVoid, mp_machine_currentState_setAsVoid, NULL);
	refl_setMetaPropertyStringFunctions(mp_machine_currentState, mp_machine_currentState_getAsString, mp_machine_currentState_setAsString, NULL);
	machineProperties[0] = mp_machine_currentState;
	refl_setMachineMetaProperties(m, machineProperties, 1, NULL);
	refl_metaState states[2];

	
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
	refl_metaProperty Ping_properties[1];
	refl_metaProperty mp_Ping_stateName = refl_initMetaProperty(NULL);
	refl_setMetaPropertyName(mp_Ping_stateName, "stateName", NULL);
	refl_setMetaPropertyTypeString(mp_Ping_stateName, "const char *", NULL);
	refl_setIsMetaPropertyUnsigned(mp_Ping_stateName, refl_FALSE, NULL);
	refl_setMetaPropertyIndirection(mp_Ping_stateName, 1, NULL);
	refl_setMetaPropertyType(mp_Ping_stateName, REFL_CHAR, NULL);
	refl_setMetaPropertyVoidFunctions(mp_Ping_stateName, mp_Ping_stateName_getAsVoid, mp_Ping_stateName_setAsVoid, NULL);
	refl_setMetaPropertyStringFunctions(mp_Ping_stateName, mp_Ping_stateName_getAsString, mp_Ping_stateName_setAsString, NULL);
	Ping_properties[0] = mp_Ping_stateName;
	refl_setStateMetaProperties(ms_Ping, Ping_properties, 1, NULL);
	states[0] = ms_Ping;
	refl_metaTransition Ping_transitions[1];
	refl_metaTransition mt_Ping_T_0 = refl_initMetaTransition(NULL);
	refl_setMetaTransitionSource(mt_Ping_T_0, 0, NULL);
	refl_setMetaTransitionTarget(mt_Ping_T_0, 1, NULL);
	refl_setMetaTransitionExpression(mt_Ping_T_0, "after(1)", NULL);
	refl_transitionEval_f mt_Ping_T_0_eval_f = Ping_Transition_0;
	refl_setMetaTransitionEvalFunction(mt_Ping_T_0, mt_Ping_T_0_eval_f, NULL, NULL);
	Ping_transitions[0] = mt_Ping_T_0;
	refl_setMetaTransitions(ms_Ping, Ping_transitions, 1, NULL);
	
	//State: Pong
	refl_metaState ms_Pong = refl_initMetaState(NULL);
	refl_setMetaStateName(ms_Pong, "Pong", NULL);

	refl_metaAction ma_Pong_OnEntry = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Pong_OnEntry, Pong_OnEntry, NULL);
	refl_setOnEntry(ms_Pong, ma_Pong_OnEntry, NULL);
	refl_metaAction ma_Pong_Internal = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Pong_Internal, Pong_Internal, NULL);
	refl_setInternal(ms_Pong, ma_Pong_Internal, NULL);
	refl_metaAction ma_Pong_OnExit = refl_initMetaAction(NULL);
	refl_setMetaActionMethod(ma_Pong_OnExit, Pong_OnExit, NULL);
	refl_setOnExit(ms_Pong, ma_Pong_OnExit, NULL);
	refl_metaProperty Pong_properties[1];
	refl_metaProperty mp_Pong_stateName = refl_initMetaProperty(NULL);
	refl_setMetaPropertyName(mp_Pong_stateName, "stateName", NULL);
	refl_setMetaPropertyTypeString(mp_Pong_stateName, "const char *", NULL);
	refl_setIsMetaPropertyUnsigned(mp_Pong_stateName, refl_FALSE, NULL);
	refl_setMetaPropertyIndirection(mp_Pong_stateName, 1, NULL);
	refl_setMetaPropertyType(mp_Pong_stateName, REFL_CHAR, NULL);
	refl_setMetaPropertyVoidFunctions(mp_Pong_stateName, mp_Pong_stateName_getAsVoid, mp_Pong_stateName_setAsVoid, NULL);
	refl_setMetaPropertyStringFunctions(mp_Pong_stateName, mp_Pong_stateName_getAsString, mp_Pong_stateName_setAsString, NULL);
	Pong_properties[0] = mp_Pong_stateName;
	refl_setStateMetaProperties(ms_Pong, Pong_properties, 1, NULL);
	states[1] = ms_Pong;
	refl_metaTransition Pong_transitions[1];
	refl_metaTransition mt_Pong_T_0 = refl_initMetaTransition(NULL);
	refl_setMetaTransitionSource(mt_Pong_T_0, 1, NULL);
	refl_setMetaTransitionTarget(mt_Pong_T_0, 0, NULL);
	refl_setMetaTransitionExpression(mt_Pong_T_0, "after_ms(500)", NULL);
	refl_transitionEval_f mt_Pong_T_0_eval_f = Pong_Transition_0;
	refl_setMetaTransitionEvalFunction(mt_Pong_T_0, mt_Pong_T_0_eval_f, NULL, NULL);
	Pong_transitions[0] = mt_Pong_T_0;
	refl_setMetaTransitions(ms_Pong, Pong_transitions, 1, NULL);
	refl_setMetaStates(m, states, 2, NULL);
	refl_setCurrentState(m, 0, NULL);
	return m;
}
// Scheduled Creation script
refl_metaMachine Create_ScheduledMetaMachine()
{
	machineID = number_of_machines() < 0 ? 0 : static_cast<unsigned int>(number_of_machines());
	CLFSMMachineLoader::CLFSMMachineLoader* loader = CLFSMMachineLoader::getMachineLoaderSingleton();
	loader->loadAndAddMachineAtPath("/home/bren/src/MiPal/GUNao/posix/swiftfsm/swiftfsm/Sources/CFSMs/cfsm_examples/PingPongCLFSM.machine");
	CLMachine* machine = machine_at_index(machineID);
	refl_metaMachine metaMachine = Create_MetaMachine();
	refl_setMachine(metaMachine, machine, NULL);
	refl_setExecuteAction(metaMachine, PingPongCLFSM_executeCurrentState, NULL);
	refl_setDestructorAction(metaMachine, PingPongCLFSM_destroy, NULL);
	return metaMachine;
}
#pragma clang diagnostic pop
