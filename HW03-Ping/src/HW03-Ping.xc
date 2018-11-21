/*
 * HW03-Ping.xc
 *
 *  Created on: Sep 29, 2018
 *      Author: quyetnguyen
 */

#include <xs1.h>
#include <print.h>
#include <stdio.h>

//constants
#define TICKS_PER_SEC XS1_TIMER_HZ
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#define TICKS_PER_MICRO (XS1_TIMER_HZ/1000000)
#define TIMMER_MAX 0xFFFFFFFF
#define SOUND_MM_PER_TICKS 0.0034029 // 340290/100000000
#define TIME_OUT 20*TICKS_PER_MS // 20 ms


const unsigned int NUM_SAMPLES = 3;
const unsigned int SAMPLES_MM[] = {1000, 5000, 10000};
const unsigned int SOUND_MM_PER_SECOND = 340290;

//ports

port ioPingPort = XS1_PORT_1A;
port ioPingSimulator = XS1_PORT_1B;

// prototype
void distance_consumer(chanend c);
void ping_task(port p, chanend c);
void ping_task_timeout(port p, chanend c, unsigned int timeout_ticks);
void ping_simulator(port p, const unsigned int mms[],
        unsigned int n_mms, unsigned int mm_per_second);
unsigned int time_diff(unsigned int t0, unsigned int t1);

int main(void)
{
    chan c;
    par{
        //ping_task(ioPingPort, c);
        ping_task_timeout(ioPingPort, c, TIME_OUT);
        distance_consumer(c);
        ping_simulator(ioPingSimulator,
                SAMPLES_MM,
                NUM_SAMPLES,
                SOUND_MM_PER_SECOND);
    }
    return 0;

}

void distance_consumer(chanend c)
{
    int distanceValue;
    for(int i = 0; i < NUM_SAMPLES; i++)
    {
        c :> distanceValue;
        printstrln("distance value is ");
        printf("%d\n", distanceValue);

    }
}

void ping_task(port p, chanend c)
{

    int distanceValue = 0;
    unsigned int t0, t1, ticks;
    timer tmr;
    unsigned int time;
    float tmp;
    for(int i = 0; i < NUM_SAMPLES; i++)
    {
        // trigger high pulse
        p <: 1;
        tmr :> time;
        tmr when timerafter(time + 5*TICKS_PER_MICRO) :> void;
        // low pulse
        p <: 0;

        // wait to get high return from sensor
        p when pinseq(1) :> void;
        tmr :> t0;
        // wait to get low return from sensor
        p when pinseq(0) :> void;
        tmr :> t1;
        ticks = time_diff(t0, t1);
        tmp = (ticks/2)*SOUND_MM_PER_TICKS;
        printf("tmp = %f\n", tmp);
        distanceValue = tmp;
        c <: distanceValue;
    }

}

void ping_task_timeout(port p, chanend c, unsigned int timeout_ticks)
{
    int distanceValue = 0;
    unsigned int t0, t1, ticks;
    timer tmr;
    unsigned int time;
    float tmp;

    for(int i = 0; i < NUM_SAMPLES; i++)
    {

        // trigger high pulse
        p <: 1;
        tmr :> time;
        tmr when timerafter(time + 5*TICKS_PER_MICRO) :> void;
        // low pulse
        p <: 0;

        tmr :> time;
        time = time + timeout_ticks;
        p :> void;
        select
        {
            // wait to get high return from sensor
            case p when pinseq(1) :> void:
                tmr :> t0;

                // wait to get low return from sensor
                p when pinseq(0) :> void;
                tmr :> t1;
                ticks = time_diff(t0, t1);
                tmp = (ticks/2)*SOUND_MM_PER_TICKS;
                printf("tmp = %f\n", tmp);
                distanceValue = tmp;
                c <: distanceValue;
                break;

            case tmr when timerafter(time) :> void:
                c <: -1;
                break;


        }
    }


}

unsigned int time_diff(unsigned int t0, unsigned int t1)
{
    while(t1 <= t0)
    {
        t1 = t1 + TIMMER_MAX;
    }
    return (t1 - t0);
}
