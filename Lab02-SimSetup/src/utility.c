/*
 * utility.c
 *
 *  Created on: Sep 20, 2018
 *      Author: quyetnguyen
 */



#include <stdio.h>
#include <xs1.h>
#include <limits.h>
#include <print.h>

#define TIMMER_MAX 0xFFFFFFFF

unsigned int time_diff(unsigned int t0, unsigned int t1 )
{
    if(t1 <= t0)
    {
        t1 = t1 + TIMMER_MAX;
    }
    return (t1 - t0);
}

void format_message (char buffer[], unsigned int t0, unsigned int t1)
{
    float result = time_diff(t0, t1)/XS1_TIMER_HZ;
    sprintf(buffer, "Difference was %f seconds\n", result);
}
