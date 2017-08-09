//
// State_Initial.mm
//
// Automatically created through MiPalCASE -- do not change manually!
//
#include "NewMachine_Includes.h"
#include "NewMachine.h"
#include "State_Initial.h"

#include "State_Initial_Includes.h"

using namespace FSM;
using namespace CLM;
using namespace FSMNewMachine;
using namespace State;

Initial::Initial(const char *name): CLState(name, *new Initial::OnEntry, *new Initial::OnExit, *new Initial::Internal)
{
	_transitions[0] = new Transition_0();
}

Initial::~Initial()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();

	delete _transitions[0];
}

void Initial::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "NewMachine_VarRefs.mm"
#	include "State_Initial_VarRefs.mm"
#	include "NewMachine_FuncRefs.mm"
#	include "State_Initial_FuncRefs.mm"
#	include "State_Initial_OnEntry.mm"
}

void Initial::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "NewMachine_VarRefs.mm"
#	include "State_Initial_VarRefs.mm"
#	include "NewMachine_FuncRefs.mm"
#	include "State_Initial_FuncRefs.mm"
#	include "State_Initial_OnExit.mm"
}

void Initial::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "NewMachine_VarRefs.mm"
#	include "State_Initial_VarRefs.mm"
#	include "NewMachine_FuncRefs.mm"
#	include "State_Initial_FuncRefs.mm"
#	include "State_Initial_Internal.mm"
}

bool Initial::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "NewMachine_VarRefs.mm"
#	include "State_Initial_VarRefs.mm"
#	include "NewMachine_FuncRefs.mm"
#	include "State_Initial_FuncRefs.mm"

	return
	(
#		include "State_Initial_Transition_0.expr"
	);
}
