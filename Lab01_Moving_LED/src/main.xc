/*
 * main.xc
 *
 *  Created on: Sep 14, 2018
 *      Author: quyetnguyen
 */

#include <xs1.h>


#define FLASH_DELAY (XS1_TIMER_HZ / 4)
#define LEDA1 0b01111111011111111111
#define LEDB1 0b11111110011111111111
#define LEDC1 0b11111111010111111111
#define LEDC2 0b11111111011011111111
#define LEDC3 0b11111111011101111111
#define LEDB3 0b11111111001111111111
#define LEDA3 0b11011111011111111111
#define LEDA2 0b10111111011111111111
#define LEDB2 0b11111111011111111111

out port oLEDs = XS1_PORT_32A;


int main()
{

    timer tmr;
    unsigned int t;
    unsigned pattern = LEDB2;
    unsigned arr[] = {LEDA1, LEDB1, LEDC1, LEDC2, LEDC3, LEDB3, LEDA3, LEDA2};
    tmr :> t;
    int i = 0;
    while(1)
    {
        oLEDs <: pattern;
        t += FLASH_DELAY;

        tmr when timerafter(t) :> void;

        pattern = arr[i];
        i++;
        if(i == 8)
        {
            i = 0;
        }
    }

    return 0;
}

