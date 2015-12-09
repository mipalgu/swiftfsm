//
//  to_opaque.h
//  swiftfsm
//
//  Created by Callum McColl on 8/09/2015.
//  Copyright © 2015 MiPal. All rights reserved.
//

#ifndef to_opaque_h
#define to_opaque_h

#include <stdio.h>

void * to_opaque(int (*f)(int, char *[]));

#endif /* to_opaque_h */
