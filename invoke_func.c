//
//  invoke_func.c
//  swiftfsm
//
//  Created by Callum McColl on 8/09/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

#include "invoke_func.h"

int invoke_fun(void * p) {
    int (*f)(int, char *[]) = p;
    char * args[0];
    return f(0, args);
}