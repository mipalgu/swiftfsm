#include "cfsm_number_of_machines.h"

// The number of CLMachines in the finite_state_machines array
static int number_of_clmachines = 0;

/**
 * Sets the number of machines in the finite_state_machines array
 *
 * @param n the new number of machines
 */
void set_number_of_machines(int n)
{   
    number_of_clmachines = n;
}

/**
 * Gets the number of machines in the finite_state_machines array
 *
 * @return the number of machines
 */
int FSM::number_of_machines(void)
{
    return number_of_clmachines;
}

