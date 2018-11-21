/*
 * main.xc
 *
 *  Created on: Sep 16, 2018
 *      Author: quyetnguyen
 */


#include <stdio.h>
#include <xs1.h>
#include <stdlib.h>
#include <print.h>

#define TIMMER_MAX UINT_MAX
#define FLASH_DELAY (XS1_TIMER_HZ/2) //a haft of a second
#define FLASH 3 // flash 3 times
#define MICRO 100 // use to convert to microsecond
#define SAMPLE_TIMES 10

in port iButton = XS1_PORT_32A;
out port oLed1 = XS1_PORT_1A;
out port oLed2 = XS1_PORT_1D;

/*
 * Compute the difference bw t1 and t0
 */
unsigned int compute_difference(unsigned int t0, unsigned int t1)
{
    while((t1 <= t0))
    {
        t1 += TIMMER_MAX;
    }
    return (t1 - t0);
}

/*
 * Find maximum number in a array data
 */
unsigned findMax(unsigned data[], int n)
{
    unsigned max = data[0];
    for(int i = 1; i < n; i++)
    {
        if(max < data[i])
        {
            max = data[i];
        }
    }
    return max/MICRO;
}

/*
 * Find minimum number in a array data
 */
unsigned findMin(unsigned data[], int n)
{
    unsigned min = data[0];
    for(int i = 1; i < n; i++)
    {
        if(min > data[i])
        {
            min = data[i];
        }
    }
    return min/MICRO;
}

/*
 * swap two number
 */
void swap(unsigned & a, unsigned & b)
{
    int tmp = a;
    a = b;
    b = tmp;
}
/*
 * Find a median numer in a array data
 */

unsigned findMedian(unsigned data[], int n)
{
    unsigned result = 0;
    // doing bubble sort
    for(int i = 0; i < n; i++)
    {
        int flag = 0;
        for(int j = 0; j < n - 1; j++)
        {
            if(data[j] > data[j+1])
            {
                swap(data[j], data[j+1]);
                flag = 1;
            }
        }
        if(flag == 0)
            break;
    }
    if(n % 2 == 0)
    {
        result = (data[n/2 - 1] + data[n/2]) /2;

    }
    else
    {
        result = data[n/2];

    }

    return result/MICRO;

}

/*
 * calculate average in a array data
 */
unsigned calAverage(unsigned data[], int n)
{
    unsigned total = 0;
    unsigned average = 0;
    for(int i = 0; i < n; i++)
    {
       total += data[i];
    }
    average = total/n;

    return average/MICRO;
}

/*
 * print statictic data
 */
void printData(unsigned data[], int n)
{
    printstr("++++++++ Result of samples ++++++++\n");
    printf("Min = %u microseconds\n", findMin(data, n));
    printf("Max = %u microseconds\n", findMax(data, n));

    printf("Average = %u microseconds\n", calAverage(data, n));
    printf("Median = %u microseconds\n", findMedian(data, n));
    printstr("++++++++ End ++++++++\n");

}

/*
 * ouput data to 2 LEDS user
 */
void output_leds(out port p1, out port p2, unsigned pattern)
{
    p1 <: pattern;
    p2 <: pattern;
}

/*
 * Flash 3 times in 3 seconds
 */
void flash_leds(out port p1, out port p2, unsigned pattern, timer t)
{

    unsigned tm;
    t :> tm;
    int count = 0;
    while(count < 2*FLASH)
    {

        output_leds(p1, p2, pattern);
        tm += FLASH_DELAY;
        t when timerafter(tm) :> void;
        pattern = ~pattern;
        count++;

    }
}

/*
 * listen to the button
 */

void button_handler(in port button, unsigned value, timer t, unsigned t0, unsigned arr[], int times)
{
    printstr("waiting for the button is pressed\n");
    int flag = 0;
    unsigned t1;
    while(1)
    {

        select
        {
        case button when pinsneq(value) :> unsigned newvalue:

            if((newvalue & 0x1) == 0)
            {
                // turn off leds
                output_leds(oLed1, oLed2, 0);
                t :> t1;
                printstr("Pressed ");
                printf("%d\n", times);
                arr[times] = compute_difference(t0, t1);

                flag = 1;
            }

            value = newvalue;

            break;
        }

        if(flag == 1)
            break;
    }

}

int main()
{

    unsigned time, delay, value, t0;
    unsigned arr[10];
    int i = 0;
    timer t;
    unsigned pattern = 1;

    iButton :> value;

    while(1)
    {
        printstr("3 times flashing\n");
        flash_leds(oLed1, oLed2, pattern, t);

        // enter to the delay
        delay = XS1_TIMER_HZ + rand() % XS1_TIMER_HZ;
        t :> time;
        t when timerafter(time + delay) :> void;

        // illuminate leds
        output_leds(oLed1, oLed2, 1);

        t :> t0;

        button_handler(iButton, value, t, t0, arr, i);
        i++;
        if(i == SAMPLE_TIMES)
        {
            // print data
            printData(arr, SAMPLE_TIMES);
            // reset for a new sample
            i = 0;

        }

        // reset pattern
        pattern = 1;

        // delay 1 second
        t :> time;
        t when timerafter(time + XS1_TIMER_HZ) :> void;

    }

    return 0;
}
