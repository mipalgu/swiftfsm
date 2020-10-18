/*
 *  cfsm_loader.cc
 *  CFSM
 *
 *  Created by Bren Moushall on 08/08/2017.
 *  Copyright (c) 2017 Rene Hexel. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgement:
 *
 *        This product includes software developed by Rene Hexel.
 *
 * 4. Neither the name of the author nor the names of contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * -----------------------------------------------------------------------
 * This program is free software; you can redistribute it and/or
 * modify it under the above terms or under the terms of the GNU
 * General Public License as published by the Free Software Foundation;
 * either version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see http://www.gnu.org/licenses/
 * or write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */
#include "cfsm_loader.h"
#include "cfsm_number_of_machines.h"
#include "cfsm_control.h"
#include "cfsm_index.h"
#include "CLMachine.h"
#include <dlfcn.h>
#include <CLReflect/CLReflect.h>
#include <stdlib.h>
#include <string>
#include <algorithm>
#include <string.h>
#include <unistd.h>

using namespace FSM;

/// The vector of loaded machines.
std::vector<CLMachine*> finite_state_machines = std::vector<CLMachine*>();

/// The vector of machine library handles.
static std::vector<void*> machine_lib_handles = std::vector<void*>();

/// The vector of dynamically loaded machine IDs.
static std::vector<int> loaded_machineIDs = std::vector<int>();

/// The vector of dynamically unloaded machine IDs.
static std::vector<int> unloaded_machineIDs = std::vector<int>();

/// Whether machines are being loaded/unloaded by another machine.
static bool dynamic = true;

/// The last machine ID assigned.
static int last_unique_id = -1;

extern "C"
{
    /**
     * Returns the number of dynamically loaded machines.
     *
     * @return loaded_machineIDs vector size
     */
    int C_numberOfDynamicallyLoadedMachines()
    {
        return loaded_machineIDs.size();
    }

    /**
     * Empties the dynamically loaded machine ID vector,
     */
    void C_emptyDynamicallyLoadedMachineVector()
    {
        loaded_machineIDs.clear();
    }

    /**
     * Returns the dynamically loaded machine ID vector.
     *
     * @return loaded_machineIDs vector
     */
    int* C_getDynamicallyLoadedMachineIDs()
    {
        return &loaded_machineIDs[0];
    }

    /**
     * Checks if given ID corresponds to a dynamically unloaded machine.
     * If so, removes it from dynamically unloaded machine ID vector.
     *
     * @param id the ID of the machine to check
     * @return true if ID corresponds to unloaded machine, false otherwise
     */
    bool C_checkDynamicallyUnloadedMachine(int id)
    {
        std::vector<int>::iterator index = std::find(unloaded_machineIDs.begin(), unloaded_machineIDs.end(), id);
        if (index == unloaded_machineIDs.end())
        {
            return false;
        }
        else 
        {
            unloaded_machineIDs.erase(index);
            return true;
        }
    }

    /**
     * Wrapper around CLMacros loadAndAddMachine that returns the machine ID
     * and turns off the "dynamically_loaded" flag
     *
     * @param machine path to the CL machine .so
     * @param initiallySuspended whether this machine starts suspended
     * @return the ID of the machine (-1 if an error occurred)
     */
    int C_loadAndAddMachine(const char *machine, bool initiallySuspended)
    {
        dynamic = false;
        int index = FSM::loadAndAddMachine(machine, initiallySuspended);
        if (index == CLError) return -1;
        CLMachine *m = machine_at_index(index);
        return m->machineID();
    }

    /**
     * Wrapper around CLMacros unloadMachineAtIndex that takes an ID of machine to unload
     *
     * @param id ID of the machine to unload
     * @return whether the machine successfully unloaded
    */
    bool C_unloadMachineWithID(int id)
    {
        dynamic = false;
        int index = index_of_machine_with_id(id);
        return FSM::unloadMachineAtIndex(index);
    }

}

/**
 * Creates the internal Machine context of a CL Machine
 *
 * @param machine the CL Machine to create the context for
 * @return the internal machine context
 */
Machine *createMachineContext(CLMachine *machine)
{
    CLState *initial_state = machine->initialState();
    CLState *suspend_state = machine->suspendState();
    return new Machine(initial_state, suspend_state, false);
}

/**
 * Gets the machine name from the supplied path
 *
 * @param path the path of the CLMachine .so
 * @return the machine name
 */
const char* getMachineNameFromPath(const char* path)
{
    std::string tmp = std::string(path);
    std::size_t start = tmp.find_last_of("/");
    std::size_t end = tmp.find_last_of(".so");
    int offset = 3; // Length of ".so"

    // If the .so path hasn't been provided, check if the .machine path was provided
    if (end == std::string::npos) 
    {
        std::size_t end = tmp.find_last_of(".machine");
        if (end == std::string::npos) return NULL; //.so or .machine path wasn't provided
        offset = 8; //Length of ".machine"
    }
    
    std::string n = tmp.substr(start + 1, (end - start - offset) );

    // Need to allocate memory for c-string as it only lives as long as the C++ string.
    char* name = (char*) calloc(strlen(n.c_str()) + 1, sizeof(char));
    strcpy(name, n.c_str());
    return name;
}

/**
 * Load a CLMachine and associated Meta Machine
 *
 * @param machine the path to the CLMachine .so
 * @param initiallySuspended whether this machine starts suspended
 * @return the index of the loaded machine, -1 if an error occurred (CLError)
 */
int FSM::loadAndAddMachine(const char *machine, bool initiallySuspended)
{
    // Get handle for machine library
    void* machine_lib_handle = dlopen(machine, RTLD_NOW);
    if (!machine_lib_handle) // Check if ".machine" path was provided rather than ".so" 
    {
        fprintf(stderr, "cfsm_loader(): Error opening machine library: dlerror(): %s\n", dlerror());
        return CLError; 
    }

    // Get pointer to machine lib's create CL machine function
    const char* name = getMachineNameFromPath(machine);
    const char cl_create_function_name[] = "CLM_Create_";
    char create_machine_symbol[strlen(cl_create_function_name) + strlen(name) + 1];
    strcpy(create_machine_symbol, "CLM_Create_");
    strcat(create_machine_symbol, name);
    void* create_machine_ptr = dlsym(machine_lib_handle, create_machine_symbol);
    if (!create_machine_ptr)
    {
        fprintf(stderr, "Error getting CL Create Machine symbol - dlerror(): %s\n", dlerror());
        return CLError;
    }
    
    CLMachine* (*createMachine)(int, const char*) = (CLMachine* (*)(int, const char*)) (create_machine_ptr);
    if (!createMachine)
    { 
        fprintf(stderr, "CL Create Machine function from dlsym is NULL\n");
        return CLError;
    }

    // Call the machine lib's create CL machine function
    int machine_id = last_unique_id + 1;
    CLMachine* machine_ptr = createMachine(machine_id, name);
    free((char*)(name));

    if (!machine_ptr)
    {
        fprintf(stderr, "CL Create Machine return NULL\n");
        return CLError;
    }
    last_unique_id = machine_id;

    // Create internal CL machine context for machine
    Machine *machine_context = createMachineContext(machine_ptr);
    if (!machine_context)
    {
        fprintf(stderr, "Error creating internal machine context");
        return CLError;
    }
    machine_ptr->setMachineContext(machine_context);
    
    // Place machine in CFSM array
    finite_state_machines.push_back(machine_ptr);
    int index = finite_state_machines.size() -1;
    set_number_of_machines(number_of_machines() + 1);

    // Suspend the machine if initiallySuspended
    if (initiallySuspended) { FSM::control_machine_at_index(index, CLSuspend); }
 
    // Get pointer to machine lib's create metamachine function
    void* create_meta_machine_ptr = dlsym(machine_lib_handle, "Create_ScheduledMetaMachine");
    if (!create_meta_machine_ptr) {
        fprintf(stderr, "Error getting Create Meta Machine symbol - dlerror(): %s\n", dlerror());
        return CLError;
    }
    refl_metaMachine (*createMetaMachine)(void*) = (refl_metaMachine (*)(void*)) (create_meta_machine_ptr);
    if (!createMetaMachine)
    {
        fprintf(stderr, "Create Meta Machine function pointer from dlsym is NULL\n");
        return CLError;
    }

    // Call the machine lib's create metamachine function
    refl_metaMachine meta_machine = createMetaMachine(machine_ptr);
    
    // Initialise CLReflect API and register metamachine
    CLReflectResult *result = (CLReflectResult*) calloc(1, sizeof(CLReflectResult));
    refl_initAPI(result);
    if (!result || *result != REFL_SUCCESS)
    {
        fprintf(stderr, "Error initialising CLReflect API\n");
        return CLError;
    }
    refl_registerMetaMachine(meta_machine, machine_id, result);
    if (!result || *result != REFL_SUCCESS)
    {
        fprintf(stderr, "Error registering Meta Machine\n");
        return CLError;
    }
    free(result);

    // Place machine lib handle in lib handles vector so it can be closed later.
    machine_lib_handles.push_back(machine_lib_handle);

    if (dynamic) 
    { 
        loaded_machineIDs.push_back(machine_id);
    }
    dynamic = true; // Reset flag if it was turned off.
    
    return index;
}

/**
 * Unloads the machine at the given index
 *
 * @param index index of the machine to unload
 * @return true on success, false on failure
 */
bool FSM::unloadMachineAtIndex(int index)
{
    if ( index < 0 || index > number_of_machines() ) return false;
    
    if (dynamic)
    {
        CLMachine *machine = machine_at_index(index);
        int machine_id = machine->machineID();
        unloaded_machineIDs.push_back(machine_id);
    }
    dynamic = true; // Reset flag if it was turned off.

    finite_state_machines.erase(finite_state_machines.begin() + index);
    set_number_of_machines(number_of_machines() - 1);
    
    // Get machine lib handle for this machine and close the lib.
    void* machine_lib_handle = machine_lib_handles.at(index);
    if (dlclose(machine_lib_handle)) 
    { 
        fprintf(stderr, "Error closing machine library - dlerror(): %s\n", dlerror()); return CLError; 
    }

    return true;
}
