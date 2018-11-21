/*
 * Lab04-SingleMotor.xc
 *
 *  Created on: Oct 4, 2018
 *      Author: quyetnguyen
 */

#include <xs1.h>
#include <stdio.h>
#include <print.h>
// bit masks for control pins
#define BIN1_ON 0b0010
#define BIN2_ON 0b1000
#define AIN1_ON 0b0100
#define AIN2_ON 0b0001

// ports

out port oMotorPWMA = XS1_PORT_1P;
out port oMotorPWMB = XS1_PORT_1I;
out port oMotorControl = XS1_PORT_4D;
out port oLED = XS1_PORT_1A;
out port oSTB = XS1_PORT_1O;

// constants
#define TICKS_PER_SEC (XS1_TIMER_HZ)
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#define PWM_FRAME_TICKS TICKS_PER_MS

void toggle_port(out port oLED, unsigned int hz);
void motor_task_static(out port oMotorPWM,
        out port oMotorControl, unsigned int control_mask, unsigned int duty_cycle);

void driver_task(chanend out_motor_cmd_chan, int increment,
        unsigned int delay_ticks);

void motor_task(out port oMotorPWM,
        out port oMotorControl,
        unsigned int cw_mask,
        unsigned int ccw_mask,
        chanend in_motor_cmd_chan);

int main()
{


    /*
    par
    {
        motor_task_static(oMotorPWMA, oMotorControl, AIN1_ON, 50);
        //motor_task_static(oMotorPWMB, oMotorControl, BIN1_ON, 50);
        //motor_task_static(oMotorPWMB, oMotorControl, BIN2_ON, 100);
        //motor_task_static(oMotorPWMB, oMotorControl, BIN2_ON, 25);
        toggle_port(oLED, 2);
    }
    */


    chan motor_cmd_chan;
    oSTB <: 1;
    par
    {

        //motor_task(oMotorPWMB, oMotorControl, BIN1_ON, BIN2_ON, motor_cmd_chan);
        motor_task(oMotorPWMA, oMotorControl, AIN1_ON, AIN2_ON, motor_cmd_chan);
        driver_task(motor_cmd_chan, 5, TICKS_PER_SEC/8);
    }

    return 0;
}

void toggle_port(out port oLED, unsigned int hz)
{
    timer tmr;
    unsigned int time;
    unsigned int delay;
    tmr :> time;
    // convert frequencey to period T(s) = 1/f
    delay = (1/hz)*TICKS_PER_SEC;
    while(1)
    {
        oLED <: 1;
        time += delay;
        tmr when timerafter(time) :> void;
        oLED <: 0;


    }
}

void motor_task_static(out port oMotorPWM,
        out port oMotorControl, unsigned int control_mask, unsigned int duty_cycle)
{
    timer tmr;
    unsigned time;
    unsigned delay_high;
    unsigned delay_low;


    // set control mask to motor control port
    oMotorControl <: control_mask;
    // set oSTBY port to 1
    oSTB <: 1;

    delay_high = (duty_cycle * PWM_FRAME_TICKS)/100;
    delay_low = PWM_FRAME_TICKS - delay_high;
    tmr :> time;
    while(1)
    {
        oMotorPWM <: 1;
        tmr when timerafter(time += delay_high) :> void;
        oMotorPWM <: 0;
        tmr when timerafter(time += delay_low) :> void;

    }
}

void driver_task(chanend out_motor_cmd_chan, int increment,
        unsigned int delay_ticks)
{
    timer tmr;
    unsigned time;
    int duty_cycle = 0;
    int cycle_flag = 1;
    tmr :> time;
    while(1)
    {

        out_motor_cmd_chan <: duty_cycle;
        //printf("out = %d\n", duty_cycle);

        time += delay_ticks;
        tmr when timerafter(time) :> void;

        if(cycle_flag == 1)
        {
            if(duty_cycle < 100)
            {
                // increase
                duty_cycle += increment;

            }
            else
            {
                cycle_flag = 0;

            }


        }
        if(cycle_flag == 0)
        {
            if(duty_cycle > -100)
            {
                // decrease
                duty_cycle -= increment;
            }
            else
            {
                cycle_flag = 1;
                duty_cycle = -100 + increment;
            }
        }

    }
}



void motor_task(out port oMotorPWM,
        out port oMotorControl,
        unsigned int cw_mask,
        unsigned int ccw_mask,
        chanend in_motor_cmd_chan)
{
    timer tmr;
    unsigned time;
    unsigned delay_high;
    unsigned delay_low;
    int duty_cycle = 0; // start off
    int flag = 0;

    tmr :> time;
    while(1)
    {
        if(duty_cycle < 0)
        {
            delay_high = -(duty_cycle * PWM_FRAME_TICKS)/100;
        }
        else
        {
            delay_high = (duty_cycle * PWM_FRAME_TICKS)/100;
        }

        delay_low = PWM_FRAME_TICKS - delay_high;
        time += delay_high;
        oMotorPWM <: 1;

        // listen to duty cycle from driver_task
        while(1)
        {
            if(flag == 1)
            {
                flag = 0;
                break;
            }
            else
            {
                select
                {

                    case tmr when timerafter(time) :> void:
                        flag = 1;
                        break;
                    case in_motor_cmd_chan :> duty_cycle:
                        //printf("hin = %d\n", duty_cycle);
                        break;
                }
            }


        }

        oMotorPWM <: 0;
        time += delay_low;
        // listen to duty cycle from driver_task
        while(1)
        {

            if(flag == 1)
            {
                flag = 0;
                break;
            }
            else
            {
                select
                {

                    case  tmr when timerafter(time) :> void:
                        flag = 1;
                        break;
                    case in_motor_cmd_chan :> duty_cycle:
                        //printf("lin = %d\n", duty_cycle);
                        break;
                }


            }

        }

        if(duty_cycle < 0)
        {
            oMotorControl <: ccw_mask;

        }
        else if(duty_cycle > 0)
        {
            oMotorControl <: cw_mask;
        }


    }

}
