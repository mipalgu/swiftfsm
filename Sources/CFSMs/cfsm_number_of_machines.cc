#include "cfsm_number_of_machines.h"

int number_of_clmachines = 0;

void set_number_of_machines(int n)
{   
    number_of_clmachines = n;
}

int FSM::number_of_machines(void)
{
    return number_of_clmachines;
}

