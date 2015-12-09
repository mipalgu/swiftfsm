//
//  to_opaque.c
//  swiftfsm
//
//  Created by Callum McColl on 8/09/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

#include "to_opaque.h"

void * to_opaque(int (*f)(int, char *[])) {
    void * p = f;
    return p;
}