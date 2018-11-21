/*
 * Lab02-SimSetup.xc
 *
 *  Created on: Sep 20, 2018
 *      Author: quyetnguyen
 */


#include <xs1.h>
#include <print.h>

#include <utility>
//#include "utility.h"
//#include <utility.h>

#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
in port iButton = XS1_PORT_1C;
out port oButtonSim = XS1_PORT_1B;

void button_simulator();
void monitor_button();


int main()
{
    par {
        monitor_button();
        button_simulator();
    }
    return 0;
}
int test()
{
    char buffer[64];
    // BEGIN TEST CASES
    format_message(buffer, TICKS_PER_MS, 50*TICKS_PER_MS);
    printstr(buffer);
    format_message(buffer, 900*TICKS_PER_MS, TICKS_PER_MS);
    printstr(buffer);
    // END TEST CASES
    return 0;
}
void button_simulator()
{
    timer t;
    unsigned time;
    oButtonSim <: 1;
    t :> time;
    while(1)
    {
        oButtonSim <: 0;

        // wait 1ms
        t when timerafter(time += TICKS_PER_MS) :> void;
        oButtonSim <: 1;

        // wait 0.5 ms
        t when timerafter(time += TICKS_PER_MS/2) :> void;
    }

}


void monitor_button()
{
    unsigned value;
    char buffer[64];

    unsigned t0, t1;
    timer t;

    iButton when pinseq(1) :> void;
    while(1)
    {
        select
        {
            case iButton when pinsneq(value) :> unsigned newvalue:

                if((newvalue&0x1) == 0)
                {
                    t :> t0;
                }
                if((newvalue&0x1) == 1)
                {

                    t :> t1;
                }

                format_message(buffer, t0, t1);
                printstr(buffer);
                value = newvalue;
                break;

        }
    }


}

