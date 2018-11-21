/*
 * Lab04-EncoderTest.xc
 *
 *  Created on: Oct 9, 2018
 *      Author: quyetnguyen
 */
#include <stdio.h>
#include <xs1.h>
// bit masks for control pins
#define BIN1_ON 0b0010
#define BIN2_ON 0b1000
#define AIN1_ON 0b0100
#define AIN2_ON 0b0001

// ports

out port oMotorPWMA = XS1_PORT_1P;
out port oMotorPWMB = XS1_PORT_1I;
out port oMotorControl = XS1_PORT_4D;
//out port oLED = XS1_PORT_1A;
out port oSTB = XS1_PORT_1O; // D38 pin

out port oLED1 = XS1_PORT_1A; // LED1
out port oLED2 = XS1_PORT_1D; // LED2


// SIG1 - D15 - P4C1
// SIG2 - D14 - P4C0
in port iEncoders = XS1_PORT_4C;

// constants
#define TICKS_PER_SEC (XS1_TIMER_HZ)
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#define PWM_FRAME_TICKS TICKS_PER_MS

void motor_task_static(out port oMotorPWM,
        out port oMotorControl, unsigned int control_mask, unsigned int duty_cycle);
void encoder_task(in port iEncoder, out port oled1, out port oled2);
int main()
{
    oSTB <: 1;
    par
    {
        //motor_task_static(oMotorPWMA, oMotorControl, AIN1_ON, 50);
        motor_task_static(oMotorPWMB, oMotorControl, BIN1_ON, 50);
        encoder_task(iEncoders, oLED1, oLED2);
    }
    return 0;
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
    //oSTB <: 1;

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

void encoder_task(in port iEncoder, out port oled1, out port oled2)
{
    unsigned int encoder;
    unsigned int mask_sig1 = 0b10;
    unsigned int mask_sig2 = 0b01;

    while(1)
    {
        iEncoder :> encoder;
        //printf("%u\n", iEncoder);
        // if SIG1 is 1, oled1 will be light
        if(encoder&mask_sig1)
        {
            oled1 <: 1;
        }
        else
        {
            oled1 <: 0;
        }

        // if SIG2 is 1, oled2 will be light
        if(encoder&mask_sig2)
        {
            oled2 <: 1;
        }
        else
        {
            oled2 <: 0;
        }
    }

}

