#include "cfsm_number_of_machines.h"

extern int number_of_clmachines;
int number_of_clmachines = 0;

extern "C" {
    void set_number_of_machines(int n)
    {   
        number_of_clmachines++;
    }
}

int FSM::number_of_machines(void)
{
    return number_of_clmachines;
}

