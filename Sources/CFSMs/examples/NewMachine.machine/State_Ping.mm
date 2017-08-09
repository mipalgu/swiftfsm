//
// State_Ping.mm
//
// Automatically created through MiPalCASE -- do not change manually!
//
#include "NewMachine_Includes.h"
#include "NewMachine.h"
#include "State_Ping.h"

#include "State_Ping_Includes.h"

using namespace FSM;
using namespace CLM;
using namespace FSMNewMachine;
using namespace State;

Ping::Ping(const char *name): CLState(name, *new Ping::OnEntry, *new Ping::OnExit, *new Ping::Internal)
{
	_transitions[0] = new Transition_0();
}

Ping::~Ping()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();

	delete _transitions[0];
}

void Ping::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "NewMachine_VarRefs.mm"
#	include "State_Ping_VarRefs.mm"
#	include "NewMachine_FuncRefs.mm"
#	include "State_Ping_FuncRefs.mm"
#	include "State_Ping_OnEntry.mm"
}

void Ping::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "NewMachine_VarRefs.mm"
#	include "State_Ping_VarRefs.mm"
#	include "NewMachine_FuncRefs.mm"
#	include "State_Ping_FuncRefs.mm"
#	include "State_Ping_OnExit.mm"
}

void Ping::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "NewMachine_VarRefs.mm"
#	include "State_Ping_VarRefs.mm"
#	include "NewMachine_FuncRefs.mm"
#	include "State_Ping_FuncRefs.mm"
#	include "State_Ping_Internal.mm"
}

bool Ping::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "NewMachine_VarRefs.mm"
#	include "State_Ping_VarRefs.mm"
#	include "NewMachine_FuncRefs.mm"
#	include "State_Ping_FuncRefs.mm"

	return
	(
#		include "State_Ping_Transition_0.expr"
	);
}
