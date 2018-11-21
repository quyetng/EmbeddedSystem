/*
 * HW02-HotPotato.xc
 *
 *  Created on: Sep 27, 2018
 *      Author: quyetnguyen
 */

#include <stdio.h>
#include <xs1.h>
#include <stdlib.h>
#include <print.h>

#define TICKS_PER_SEC XS1_TIMER_HZ
#define TICKS_PER_MSEC XS1_TIMER_HZ/1000
#define TICKS_PER_MICROSEC XS1_TIMER_HZ/1000000
#define MAX_TOKEN 10

in port iButton = XS1_PORT_1C;
out port oButtonSim = XS1_PORT_1A;

void button_listener_task(chanend left, chanend right);
void worker(unsigned int worker_id, chanend left, chanend right);
void button_simulator();
int main()
{
    chan c1, c2, c3, c4;

    par
    {
        button_listener_task(c1, c2);
        worker(1, c4, c1);
        worker(2, c3, c2);
        worker(3, c4, c3);
        button_simulator();
    }

    return 0;
}

void worker(unsigned int worker_id, chanend left, chanend right)
{

    unsigned time;
    timer tmr;
    int token;
    char buffer[64];

    // start hot potato
    if(worker_id == 1)
    {
        token = 1;
        right <: token;
    }
    while(1)
    {
        tmr :> time;

        select
        {
            case left :> token:
                token++;
                if(token > MAX_TOKEN)
                    return;
                sprintf(buffer, "worker %d, new token is %d\n", worker_id, token);
                printstr(buffer);
                //delay
                tmr when timerafter(time + 10*TICKS_PER_MICROSEC) :> void;
                right <: token;

                break;
            case right :> token:
                token++;
                if(token > MAX_TOKEN)
                    return;
                sprintf(buffer, "worker %d, new token is %d\n", worker_id, token);
                printstr(buffer);
                //delay
                tmr when timerafter(time + 10*TICKS_PER_MICROSEC) :> void;
                left <: token;
                break;
            // time out
            case tmr when timerafter(time + TICKS_PER_MSEC) :> void:
                return;
                break;
        }
    }


}

void button_listener_task(chanend left, chanend right)
{
    int token;
    unsigned time;
    timer tmr;
    int flag = 0;
    // wait for pin to go high
    iButton when pinseq(1) :> void;
    while(1)
    {
        tmr :> time;
        select
        {
            case left :> token:
                if(flag == 1)
                {
                    left <: token;
                    flag = 0;
                }
                else
                {
                    right <: token;
                }

                break;

            case right :> token:
                if(flag == 1)
                {
                    right <: token;
                    flag = 0;
                }
                else
                {
                    left <: token;
                }

                break;

            case iButton when pinseq(0) :> void:
                // wait for releasing
                iButton when pinseq(1) :> void;
                // reverse direction ?
                flag = 1;
                break;
            // terminate when it hits timeout
            case tmr when timerafter(time + 2*TICKS_PER_MSEC) :> void:
                exit(0);
                break;
        }
    }

}

void button_simulator()
{
    timer t;
    unsigned time;
    // output to high
    oButtonSim <: 1;

    /*
    while(1)
    {
        t :> time;

        // wait 1 mcro
        t when timerafter(time + TICKS_PER_MICROSEC) :> void;
        oButtonSim <: 0;

        // wait 1 mcro
        t when timerafter(time + TICKS_PER_MICROSEC) :> void;
        oButtonSim <: 1;


    }
    */

    t :> time;

    // wait 1 mcro
    t when timerafter(time + TICKS_PER_MICROSEC) :> void;
    oButtonSim <: 0;

    // wait 1 mcro
    t when timerafter(time + TICKS_PER_MICROSEC) :> void;
    oButtonSim <: 1;

}
