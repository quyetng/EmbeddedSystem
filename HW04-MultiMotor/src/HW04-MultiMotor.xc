/*
 * HW04-MultiMotor.xc
 *
 *  Created on: Oct 9, 2018
 *      Author: quyetnguyen
 */

#include <xs1.h>
#include <stdio.h>
#include <print.h>
#include <stdlib.h>
// bit masks for control pins
#define BIN1_ON 0b0010
#define BIN2_ON 0b1000
#define AIN1_ON 0b0100
#define AIN2_ON 0b0001

// constants
#define TICKS_PER_SEC (XS1_TIMER_HZ)
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#define PWM_FRAME_TICKS TICKS_PER_MS
#define TICKS_FOR_TURN (XS1_TIMER_HZ/1000000)
#define TICKS_PER_MICROSEC XS1_TIMER_HZ/1000000
// ports

out port oMotorPWMA = XS1_PORT_1P;
out port oMotorPWMB = XS1_PORT_1I;
out port oMotorControl = XS1_PORT_4D;
//out port oLED = XS1_PORT_1A;
out port oSTB = XS1_PORT_1O;

out port oLED1 = XS1_PORT_1A; // LED1
out port oLED2 = XS1_PORT_1D; // LED2


// SIG1 - D15 - P4C1
// SIG2 - D14 - P4C0
in port iEncoders = XS1_PORT_4C;

typedef struct
{
    int left_duty_cycle;
    int right_duty_cyle;

} motor_cmd_t;

void driver_task(
        chanend out_motor_cmd_chan,
        int increment,
        unsigned int delay_ticks);

void multi_motor_task(
        out port oLeftPWM,
        out port oRightPWM,
        out port oMotorControl,
        chanend in_motor_cmd_chan);

void encoder_task(
        in port iEncoder,
        out port oled1,
        out port oled2,
        chanend out_encoder_cmd_chan);

void square_task(chanend encoder, chanend motor);

/*
void controlLeftWheel(out port oLeftPWM,
        unsigned int delay_high,
        unsigned int delay_low
);
void controlRightWheel(out port oRightPWM,
        unsigned int delay_high,
        unsigned int delay_low);
*/

motor_cmd_t listenToCommand(chanend in_motor_cmd_chan, unsigned int timeout);
void waitFullCycle(chanend encoder, int cycle);

void turn(int left_duty, int righ_duty, chanend out_motor);
void straight(chanend out_motor);
void stop(chanend out_motor);
int main()
{
    chan motor_cmd_chan;
    chan encoder_sig;
    oSTB <: 1;
    par
    {

        encoder_task(iEncoders, oLED1, oLED2, encoder_sig);
        //driver_task(motor_cmd_chan, 5, TICKS_PER_SEC/8);
        multi_motor_task(oMotorPWMA, oMotorPWMB, oMotorControl, motor_cmd_chan);
        square_task(encoder_sig, motor_cmd_chan);

    }
    return 0;
}
void driver_task(chanend out_motor_cmd_chan,
        int increment,
        unsigned int delay_ticks)
{

    timer tmr;
    unsigned time;
    int duty_cycle = 0;
    int cycle_flag = 1;
    motor_cmd_t cmd;
    cmd.left_duty_cycle = 0;
    cmd.right_duty_cyle = 0;
    tmr :> time;
    while(1)
    {


        out_motor_cmd_chan <: cmd;
        //printf("out_l = %d\n", cmd.left_duty_cycle);
        //printf("out_r = %d\n", cmd.right_duty_cyle);
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

        cmd.left_duty_cycle = duty_cycle;
        cmd.right_duty_cyle = duty_cycle;

    }
}

/*
void controlLeftWheel( out port oLeftPWM,
        unsigned int delay_high,
        unsigned int delay_low
)
{


    timer tmr;
    unsigned int time;
    tmr :> time;

    //time += delay_high;

    oLeftPWM <: 1;
    //tmr when timerafter(time) :> void;
    tmr when timerafter(time + delay_high) :> void;

    oLeftPWM <: 0;

    tmr :> time;

    //time += delay_low;

    tmr when timerafter(time + delay_low) :> void;


}

void controlRightWheel( out port oRightPWM,
        unsigned int delay_high,
        unsigned int delay_low)
{

    timer tmr;
    unsigned int time;
    tmr :> time;
    //printf("time %d\n", time);
    //printf("delay_high %d\n", delay_high);
    //printstr("high right\n");
    oRightPWM <: 1;
    //printf("h %d\n", (time + delay_high));
    //tmr when timerafter(time += delay_high) :> void;
    tmr when timerafter(time + delay_high) :> void;

    //printstr("low right");
    oRightPWM <: 0;
    tmr :> time;
    //printf("l %d\n", (time + delay_low));
    tmr when timerafter(time + delay_low) :> void;


}
motor_cmd_t listenToCommand(chanend in_motor_cmd_chan, unsigned int timeout)
{
    motor_cmd_t result, cmd;
    cmd.left_duty_cycle = 0;
    cmd.right_duty_cyle = 0;
    timer tmr;
    unsigned int time;
    tmr :> time;
    //time += timeout;
    time += timeout;
    int flag = 1;

    while(1)
    {
        if(flag == 0)
        {
            break;
        }

        select
        {
            case in_motor_cmd_chan :> cmd:
                //printf("lc %d rc %d\n", cmd.left_duty_cycle, cmd.right_duty_cyle);

                break;
            case tmr when timerafter(time) :> void:
                //printstr("time out\n");
                flag = 0;
                break;

        }
    }
    return cmd;
}
*/


void multi_motor_task(
        out port oLeftPWM,
        out port oRightPWM,
        out port oMotorControl,
        chanend in_motor_cmd_chan)
{

    timer tmrL, tmrR, tmrF;
    unsigned timeL, timeR, timeF;

    unsigned delay_high_left, delay_low_left;
    unsigned delay_high_right, delay_low_right;
    // start off
    motor_cmd_t cmd;
    cmd.left_duty_cycle = 0;
    cmd.right_duty_cyle = 0;
    int flag = 0;

    //tmr :> time;

    while(1)
    {
        //printf("l %d r %d\n", cmd.left_duty_cycle, cmd.right_duty_cyle);
        // calculate delay time based on duty cycle
        if(cmd.left_duty_cycle < 0)
        {
            delay_high_left = -(cmd.left_duty_cycle * PWM_FRAME_TICKS)/100;
        }
        else
        {
            delay_high_left = (cmd.left_duty_cycle * PWM_FRAME_TICKS)/100;
        }

        delay_low_left = PWM_FRAME_TICKS - delay_high_left;


        if(cmd.right_duty_cyle < 0)
        {
            delay_high_right = -(cmd.right_duty_cyle * PWM_FRAME_TICKS)/100;
        }
        else
        {
            delay_high_right = (cmd.right_duty_cyle * PWM_FRAME_TICKS)/100;
        }

        delay_low_right = PWM_FRAME_TICKS - delay_high_right;



        tmrL :> timeL;
        tmrR :> timeR;
        tmrF :> timeF;
        timeL += delay_high_left;
        timeR += delay_high_right;
        timeF += PWM_FRAME_TICKS;
        /*
        par
        {
            controlLeftWheel(oLeftPWM, timeL, delay_low_left);
            controlRightWheel(oRightPWM, timeR, delay_low_right);
            cmd = listenToCommand(in_motor_cmd_chan, PWM_FRAME_TICKS);


        }
        */


        // set to high

        if(delay_high_left > 0)
        {
            oLeftPWM <: 1;
        }

        if(delay_high_right > 0)
        {
            oRightPWM <: 1;
        }


        flag = 0;
        while(flag != 1)
        {
            select
            {
                // read duty cycle
                case in_motor_cmd_chan :> cmd:
                    //printf("lc %d rc %d\n", cmd.left_duty_cycle, cmd.right_duty_cyle);
                    break;
                // time out
                case tmrF when timerafter(timeF) :> void:

                    flag = 1;
                    break;
                // left
                case tmrL when timerafter(timeL) :> void:
                    oLeftPWM <: 0;
                    timeL += 2*PWM_FRAME_TICKS; // Add to 2 frame to push timeL beyond
                                                // so, it won't run this case again during timeF

                    break;
                // right
                case tmrR when timerafter(timeR) :> void:
                    oRightPWM <: 0;
                    timeR += 2*PWM_FRAME_TICKS; // Add to 2 frame to push timeR beyond
                                                // so, it won't run this case again during timeF
                    break;
            }
        }


        // controll cw and ccw for each wheel
        if(cmd.left_duty_cycle < 0)
        {
            oMotorControl <: AIN2_ON | BIN2_ON;
        }
        else
        {
            oMotorControl <: AIN1_ON | BIN1_ON;
        }


    }

}


void encoder_task(in port iEncoder, out port oled1, out port oled2, chanend out_encoder_cmd_chan)
{
    unsigned int encoder;
    unsigned int newEncoder;
    unsigned int mask_sig1 = 0b10;
    unsigned int mask_sig2 = 0b01;
    int sig1, sig2;
    int newSig1, newSig2;

    // Sample to get input
    iEncoder :> encoder;
    sig1 = encoder & mask_sig1;
    sig2 = encoder & mask_sig2;


    while(1)
    {
        iEncoder when pinsneq(encoder) :> newEncoder;
        newSig1 = newEncoder & mask_sig1;
        newSig2 = newEncoder & mask_sig2;

        if(sig1 != newSig1)
        {
            out_encoder_cmd_chan <: 1;
            sig1 = newSig1;

        }

        if(sig2 != newSig2)
        {
            out_encoder_cmd_chan <: 2;
            sig2 = newSig2;
        }


        if(newSig1)
        {
            oled1 <: 1;
        }
        else
        {
            oled1 <: 0;
        }

        // if SIG2 is 1, oled2 will be light
        //if(encoder & mask_sig2)

        if(newSig2)
        {
            oled2 <: 1;
        }
        else
        {
            oled2 <: 0;
        }

        encoder = newEncoder;
    }

}

void waitFullCycle(chanend encoder, int cycle)
{
    int counter = 0;
    int sig1 = 1;
    while(1)
    {
        //printf("counter = %d\n", counter);
        if(counter == cycle)
        {
            break;
        }

        select
        {
            case encoder :> int signal:
                /*if(signal == sig1)
                {
                    counter++;
                }
                */
                counter++;
                break;
        }

    }

}
void square_task(chanend in_encoder, chanend out_motor)
{
    // go straight
    // sending full duty cycle to both left & right
    // turn
    // then repeat

    // go straight 1
    straight(out_motor);
    // wait 5 full cycle
    waitFullCycle(in_encoder, 40);

    stop(out_motor);

    turn(2, 80, out_motor);

    stop(out_motor);

    // go straight 2
    straight(out_motor);
    // wait 5 full cycle
    waitFullCycle(in_encoder, 40);

    stop(out_motor);

    turn(2, 80, out_motor);

    stop(out_motor);

    // go straight 3
    straight(out_motor);
    // wait 5 full cycle
    waitFullCycle(in_encoder, 40);

    stop(out_motor);

    turn(2, 80, out_motor);

    stop(out_motor);

    // go straight 4
    straight(out_motor);
    // wait 5 full cycle
    waitFullCycle(in_encoder, 40);

    stop(out_motor);

    turn(2, 80, out_motor);

    stop(out_motor);
    // go straight 5
    straight(out_motor);
    // wait 5 full cycle
    waitFullCycle(in_encoder, 40);

    stop(out_motor);

}


void turn(int left_duty, int right_duty, chanend out_motor)
{
    printstr("turn\n");
    motor_cmd_t cmd;
    cmd.left_duty_cycle  = left_duty;
    cmd.right_duty_cyle = right_duty;
    out_motor <: cmd;

}

void straight(chanend out_motor)
{

    printstr("go straight\n");
    motor_cmd_t cmd;
    cmd.left_duty_cycle = 30;
    cmd.right_duty_cyle = -30;
    out_motor <: cmd;
}

void stop(chanend out_motor)
{
    timer tmr;
    unsigned int time;
    printstr("stop\n");
    motor_cmd_t cmd;
    cmd.left_duty_cycle = 0;
    cmd.right_duty_cyle = 0;
    out_motor <: cmd;
    tmr when timerafter(time + PWM_FRAME_TICKS) :> void;

}


