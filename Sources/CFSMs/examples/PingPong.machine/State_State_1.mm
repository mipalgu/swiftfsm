//
// State_State_1.mm
//
// Automatically created through MiPalCASE -- do not change manually!
//
#include "PingPong_Includes.h"
#include "PingPong.h"
#include "State_State_1.h"

#include "State_State_1_Includes.h"

using namespace FSM;
using namespace CLM;
using namespace FSMPingPong;
using namespace State;

State_1::State_1(const char *name): CLState(name, *new State_1::OnEntry, *new State_1::OnExit, *new State_1::Internal)
{
	_transitions[0] = new Transition_0();
}

State_1::~State_1()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();

	delete _transitions[0];
}

void State_1::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "PingPong_VarRefs.mm"
#	include "State_State_1_VarRefs.mm"
#	include "PingPong_FuncRefs.mm"
#	include "State_State_1_FuncRefs.mm"
#	include "State_State_1_OnEntry.mm"
}

void State_1::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "PingPong_VarRefs.mm"
#	include "State_State_1_VarRefs.mm"
#	include "PingPong_FuncRefs.mm"
#	include "State_State_1_FuncRefs.mm"
#	include "State_State_1_OnExit.mm"
}

void State_1::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "PingPong_VarRefs.mm"
#	include "State_State_1_VarRefs.mm"
#	include "PingPong_FuncRefs.mm"
#	include "State_State_1_FuncRefs.mm"
#	include "State_State_1_Internal.mm"
}

bool State_1::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "PingPong_VarRefs.mm"
#	include "State_State_1_VarRefs.mm"
#	include "PingPong_FuncRefs.mm"
#	include "State_State_1_FuncRefs.mm"

	return
	(
#		include "State_State_1_Transition_0.expr"
	);
}
