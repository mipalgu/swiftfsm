/*
 * CLReflect.c
 * CFSMs
 *
 * Created by Callum McColl on 17/10/20.
 * Copyright © 2020 Callum McColl. All rights reserved.
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
 *        This product includes software developed by Callum McColl.
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

#include "CLReflect.h"

#include <dlfcn.h>
#include <stdlib.h>
#include <stdio.h>

static void *handle;
static void (*_refl_registerMetaMachine)(refl_metaMachine, unsigned int, CLReflectResult *) = NULL;
static refl_metaMachine (*_refl_getMetaMachine)(unsigned int, CLReflectResult *) = NULL;
static const char * (*_refl_getMetaMachineName)(refl_metaMachine, CLReflectResult*) = NULL;
static void (*_refl_invokeOnEntry)(refl_metaMachine, unsigned int, CLReflectResult*) = NULL;
static void (*_refl_invokeInternal)(refl_metaMachine, unsigned int, CLReflectResult*) = NULL;
static void (*_refl_invokeOnExit)(refl_metaMachine, unsigned int, CLReflectResult*) = NULL;
static refl_bool (*_refl_evaluateTransition)(refl_metaMachine, unsigned int, unsigned int, CLReflectResult *) = NULL;
static int (*_refl_getSuspendState)(refl_metaMachine, CLReflectResult *) = NULL;
static refl_metaState * (*_refl_getMetaStates)(refl_metaMachine, CLReflectResult *) = NULL;
static unsigned int (*_refl_getNumberOfStates)(refl_metaMachine, CLReflectResult*) = NULL;
static const char* (*_refl_getMetaStateName)(refl_metaState, CLReflectResult *) = NULL;
static unsigned int (*_refl_getNumberOfTransitions)(refl_metaState, CLReflectResult*) = NULL;
static refl_metaTransition const * (*_refl_getMetaTransitions)(refl_metaState, CLReflectResult*) = NULL;
static int (*_refl_getMetaTransitionTarget)(refl_metaTransition, CLReflectResult*) = NULL;

static void reset_pointers()
{
    _refl_registerMetaMachine = NULL;
    _refl_getMetaMachine = NULL;
    _refl_getMetaMachineName = NULL;
    _refl_invokeOnEntry = NULL;
    _refl_invokeInternal = NULL;
    _refl_invokeOnExit = NULL;
    _refl_evaluateTransition = NULL;
    _refl_getSuspendState = NULL;
    _refl_getMetaStates = NULL;
    _refl_getNumberOfStates = NULL;
    _refl_getMetaStateName = NULL;
    _refl_getNumberOfTransitions = NULL;
    _refl_getMetaTransitions = NULL;
    _refl_getMetaTransitionTarget = NULL;
}

void refl_initAPI(CLReflectResult *result)
{
#ifdef __APPLE__
    handle = dlopen("libCLReflect.dylib", RTLD_NOW | RTLD_LOCAL);
#else
    handle = dlopen("libCLReflect.so", RTLD_NOW | RTLD_LOCAL);
#endif
    REFL_UNKNOWN_ERROR = 0;
    REFL_BUFFER_OVERFLOW = 1;
    REFL_INVALID_ARGS = 2;
    REFL_INVALID_CALL = 3;
    REFL_SUCCESS = 4;
    if (!handle) {
        fprintf(stderr, "Unable to load CLReflect library: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    int *unknown_error = (int *) dlsym(handle, "REFL_UNKNOWN_ERROR");
    int *buffer_overflow = (int *) dlsym(handle, "REFL_BUFFER_OVERFLOW");
    int *invalid_args = (int *) dlsym(handle, "REFL_INVALID_ARGS");
    int *invalid_call = (int *) dlsym(handle, "REFL_INVALID_CALL");
    int *success = (int *) dlsym(handle, "REFL_SUCCESS");
    if (!unknown_error || !buffer_overflow || !invalid_args || !invalid_call || !success)
    {
        *result = REFL_UNKNOWN_ERROR;
        dlclose(handle);
        return;
    }
    REFL_UNKNOWN_ERROR = *unknown_error;
    REFL_BUFFER_OVERFLOW = *buffer_overflow;
    REFL_INVALID_ARGS = *invalid_args;
    REFL_INVALID_CALL = *invalid_call;
    REFL_SUCCESS = *success;
    void (*func)(CLReflectResult *) = (void (*)(CLReflectResult *)) dlsym(handle, "refl_initAPI");
    if (!func)
    {
        *result = REFL_UNKNOWN_ERROR;
        dlclose(handle);
        return;
    }
    return func(result);
}

void refl_destroyAPI(CLReflectResult *result)
{
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    void (*func)(CLReflectResult *) = (void (*)(CLReflectResult *)) dlsym(handle, "refl_destroyAPI");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_destroyAPI: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    func(result);
    if (*result != REFL_SUCCESS) return;
    reset_pointers();
    dlclose(handle);
}

void refl_registerMetaMachine(refl_metaMachine metaMachine, unsigned int machineID, CLReflectResult *result)
{
    if (_refl_registerMetaMachine) return _refl_registerMetaMachine(metaMachine, machineID, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    void (*func)(refl_metaMachine, unsigned int, CLReflectResult *) = (void (*)(refl_metaMachine, unsigned int, CLReflectResult *)) dlsym(handle, "refl_registerMetaMachine");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_registerMetaMachine: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    _refl_registerMetaMachine = func;
    return func(metaMachine, machineID, result);
}

refl_metaMachine refl_getMetaMachine(unsigned int machineID, CLReflectResult *result)
{
    if (_refl_getMetaMachine) return _refl_getMetaMachine(machineID, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    refl_metaMachine (*func)(unsigned int, CLReflectResult *) = (refl_metaMachine (*)(unsigned int, CLReflectResult *)) dlsym(handle, "refl_getMetaMachine");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_getMetaMachine: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    _refl_getMetaMachine = func;
    return func(machineID, result);
}

const char * refl_getMetaMachineName(refl_metaMachine machine, CLReflectResult* result)
{
    if (_refl_getMetaMachineName) return _refl_getMetaMachineName(machine, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    const char * (*func)(refl_metaMachine, CLReflectResult*) = (const char * (*)(refl_metaMachine, CLReflectResult*)) dlsym(handle, "refl_getMetaMachineName");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_getMetaMachineName: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    _refl_getMetaMachineName = func;
    return func(machine, result);
}

void refl_invokeOnEntry(refl_metaMachine metaMachine, unsigned int stateNum, CLReflectResult* result)
{
    if (_refl_invokeOnEntry) return _refl_invokeOnEntry(metaMachine, stateNum, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    void (*func)(refl_metaMachine, unsigned int, CLReflectResult*) = (void (*)(refl_metaMachine, unsigned int, CLReflectResult*)) dlsym(handle, "refl_invokeOnEntry");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_invokeOnEntry: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    _refl_invokeOnEntry = func;
    return func(metaMachine, stateNum, result);
}

void refl_invokeInternal(refl_metaMachine metaMachine, unsigned int stateNum, CLReflectResult* result)
{
    if (_refl_invokeInternal) return _refl_invokeInternal(metaMachine, stateNum, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    void (*func)(refl_metaMachine, unsigned int, CLReflectResult*) = (void (*)(refl_metaMachine, unsigned int, CLReflectResult*)) dlsym(handle, "refl_invokeInternal");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_invokeInternal: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    _refl_invokeInternal = func;
    return func(metaMachine, stateNum, result);
}

void refl_invokeOnExit(refl_metaMachine metaMachine, unsigned int stateNum, CLReflectResult* result)
{
    if (_refl_invokeOnExit) return _refl_invokeOnExit(metaMachine, stateNum, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    void (*func)(refl_metaMachine, unsigned int, CLReflectResult*) = (void (*)(refl_metaMachine, unsigned int, CLReflectResult*)) dlsym(handle, "refl_invokeOnExit");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_invokeOnExit: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return;
    }
    _refl_invokeOnExit = func;
    return func(metaMachine, stateNum, result);
}

refl_bool refl_evaluateTransition(refl_metaMachine metaMachine, unsigned int stateNum, unsigned int transitionNum, CLReflectResult *result)
{
    if (_refl_evaluateTransition) return _refl_evaluateTransition(metaMachine, stateNum, transitionNum, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return -1;
    }
    refl_bool (*func)(refl_metaMachine, unsigned int, unsigned int, CLReflectResult *) = (refl_bool (*)(refl_metaMachine, unsigned int, unsigned int, CLReflectResult *)) dlsym(handle, "refl_evaluateTransition");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_evaluateTransition: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return -1;
    }
    _refl_evaluateTransition = func;
    return func(metaMachine, stateNum, transitionNum, result);
}

int refl_getSuspendState(refl_metaMachine metaMachine, CLReflectResult *result)
{
    if (_refl_getSuspendState) return _refl_getSuspendState(metaMachine, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return -1;
    }
    int (*func)(refl_metaMachine, CLReflectResult *) = (int (*)(refl_metaMachine, CLReflectResult *)) dlsym(handle, "refl_getSuspendState");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_getSuspendState: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return -1;
    }
    _refl_getSuspendState = func;
    return func(metaMachine, result);
}

refl_metaState * refl_getMetaStates(refl_metaMachine metaMachine, CLReflectResult *result)
{
    if (_refl_getMetaStates) return _refl_getMetaStates(metaMachine, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    refl_metaState * (*func)(refl_metaMachine, CLReflectResult *) = (refl_metaState * (*)(refl_metaMachine, CLReflectResult *)) dlsym(handle, "refl_getMetaStates");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_getMetaStates: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    _refl_getMetaStates = func;
    return func(metaMachine, result);
}

unsigned int refl_getNumberOfStates(refl_metaMachine machine, CLReflectResult* result)
{
    if (_refl_getNumberOfStates) return _refl_getNumberOfStates(machine, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return 0;
    }
    unsigned int (*func)(refl_metaMachine, CLReflectResult *) = (unsigned int (*)(refl_metaMachine, CLReflectResult *)) dlsym(handle, "refl_getNumberOfStates");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_getNumberOfStates: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return 0;
    }
    _refl_getNumberOfStates = func;
    return func(machine, result);
}

const char* refl_getMetaStateName(refl_metaState metaState, CLReflectResult *result)
{
    if (_refl_getMetaStateName) return _refl_getMetaStateName(metaState, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    const char* (*func)(refl_metaState, CLReflectResult *) = (const char* (*)(refl_metaState, CLReflectResult *)) dlsym(handle, "refl_getMetaStateName");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_getMetaStateName: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    _refl_getMetaStateName = func;
    return func(metaState, result);
}

unsigned int refl_getNumberOfTransitions(refl_metaState metaState, CLReflectResult* result)
{
    if (_refl_getNumberOfTransitions) return _refl_getNumberOfTransitions(metaState, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return 0;
    }
    unsigned int (*func)(refl_metaState, CLReflectResult *) = (unsigned int (*)(refl_metaState, CLReflectResult *)) dlsym(handle, "refl_getNumberOfTransitions");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_getNumberOfTransitions: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return 0;
    }
    _refl_getNumberOfTransitions = func;
    return func(metaState, result);
}

refl_metaTransition const * refl_getMetaTransitions(refl_metaState metaState, CLReflectResult* result)
{
    if (_refl_getMetaTransitions) return _refl_getMetaTransitions(metaState, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    refl_metaTransition const * (*func)(refl_metaState, CLReflectResult *) = (refl_metaTransition const * (*)(refl_metaState, CLReflectResult *)) dlsym(handle, "refl_getMetaTransitions");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_getMetaTransitions: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return NULL;
    }
    _refl_getMetaTransitions = func;
    return func(metaState, result);
}

int refl_getMetaTransitionTarget(refl_metaTransition trans, CLReflectResult* result)
{
    if (_refl_getMetaTransitionTarget) return _refl_getMetaTransitionTarget(trans, result);
    if (!handle) {
        *result = REFL_UNKNOWN_ERROR;
        return -1;
    }
    int (*func)(refl_metaTransition, CLReflectResult *) = (int (*)(refl_metaTransition, CLReflectResult *)) dlsym(handle, "refl_getMetaTransitionTarget");
    if (!func) {
        fprintf(stderr, "Unable to load symbol refl_getMetaTransitionTarget: %s\n", dlerror());
        *result = REFL_UNKNOWN_ERROR;
        return -1;
    }
    _refl_getMetaTransitionTarget = func;
    return func(trans, result);
}
