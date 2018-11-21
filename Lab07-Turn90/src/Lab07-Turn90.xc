/*
 * Lab07-Turn90.xc
 *
 *  Created on: Oct 30, 2018
 *      Author: quyetnguyen
 */
/*
 * HW06-RobotRC.xc
 *
 *  Created on: Oct 28, 2018
 *      Author: quyetnguyen
 */



#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <platform.h>
#include <math.h>
#include "mpu6050.h"
#include "i2c.h"
/*
in port iUartRx = XS1_PORT_1B;
out port oUartTx = XS1_PORT_1A;
*/
//out port oLED = XS1_PORT_1D;

out port oWiFiRX = XS1_PORT_1F ;
out port oSTB = XS1_PORT_1O;
out port oLED1 = XS1_PORT_1A; // LED1
out port oLED2 = XS1_PORT_1D; // LED2
out port oMotorControl = XS1_PORT_4D;
out port oMotorPWMA = XS1_PORT_1P;
out port oMotorPWMB = XS1_PORT_1I;
in  port butP = XS1_PORT_32A; //Button is bit 0, used to stop gracefully
in port iWiFiTX = XS1_PORT_1H;
in port iEncoders = XS1_PORT_4C;

// bit masks for control pins
#define BIN1_ON 0b0010
#define BIN2_ON 0b1000
#define AIN1_ON 0b0100
#define AIN2_ON 0b0001



// constants

#define TICKS_PER_SEC (XS1_TIMER_HZ)
#define TICKS_PER_MS (XS1_TIMER_HZ/1000)
#define TICKS_FOR_TURN (XS1_TIMER_HZ/1000000)
#define TICKS_PER_MICROSEC XS1_TIMER_HZ/1000000

#define LEN 10;
#define LENTHBUFFER 150
#define MESSAGE_SIZE 128
#define BAUDRATE 9600 // 9600
#define PWM_FRAME_TICKS TICKS_PER_MS
#define BIT_TIME XS1_TIMER_HZ/BAUDRATE // ticks per bit


/*
in port iUartRx = XS1_PORT_1B;
out port oUartTx = XS1_PORT_1A;
out port oLED = XS1_PORT_1D;

out port oWiFiRX = XS1_PORT_1F ;
in port iWiFiTX = XS1_PORT_1H;
*/

// message struct
typedef struct
{
    char data[MESSAGE_SIZE];

} message_t;

typedef struct
{
    int left_duty_cycle;
    int right_duty_cyle;

} motor_cmd_t;

typedef struct
{
    int left;
    int right;
} encoder_t;

typedef struct
{
    float y;
    float p;
    float r;

}ypr_t;
//using GY-521 breakout board with 3.3V
struct IMU imu = {{
        on tile[0]:XS1_PORT_1L,                         //scl
        on tile[0]:XS1_PORT_4E,                         //sda
        400},};                                         //clockticks (1000=i2c@100kHz)



void uart_transmit_byte(out port oPort, char value, unsigned int baudrate);
char uart_receive_byte(in port iPort, unsigned int baudrate);

void uart_transmit_bytes(out port oPort, const char values[], unsigned int baudrate);
void uart_receive_bytes(in port iPort, char values[], unsigned int n, unsigned int baudrate);
void toggle_port(out port oLED, unsigned int hz);
//void toggle_port(out port oLED);
void uart_to_console_task(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out);
void line(const char buffer[]);

void output_task(chanend trigger_chan);
void run_wifi_setup();


// Wheel control
void stop(chanend out_motor);
void turn(int left_duty, int right_duty, chanend out_motor);
void driveforwardfullspeed(chanend out_motor);
void driveforwardhaftspeed(chanend out_motor);
void drivebackwardfullspeed(chanend out_motor);
void drivebackwardhaftspeed(chanend out_motor);
void turnRight90degree(chanend out_motor);
void turnLeft90degree(chanend out_motor);
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

// IMU

void imu_task(chanend dmp_out);


int main()
{

   chan dmp_out;
   chan trigger_chan;
   chan motor_cmd_chan;
   chan encoder_sig;
   oSTB <: 1;
   oWiFiRX <: 1;

   par
   {
       /*
       on tile[0].core[0]:imu_task(dmp_out);
       on tile[0].core[0]:uart_to_console_task(trigger_chan, motor_cmd_chan, encoder_sig, dmp_out);
       on tile[0].core[1]:output_task(trigger_chan);

       on tile[0].core[1]:multi_motor_task(oMotorPWMA, oMotorPWMB, oMotorControl, motor_cmd_chan);
       on tile[0].core[1]:encoder_task(iEncoders, oLED1, oLED2, encoder_sig);
        */
       /*
       on tile[0]:imu_task(dmp_out);
       on tile[0]:uart_to_console_task(trigger_chan, motor_cmd_chan, encoder_sig, dmp_out);
       on tile[0]:output_task(trigger_chan);

       on tile[0]:multi_motor_task(oMotorPWMA, oMotorPWMB, oMotorControl, motor_cmd_chan);
       on tile[0]:encoder_task(iEncoders, oLED1, oLED2, encoder_sig);
       */

       uart_to_console_task(trigger_chan, motor_cmd_chan, encoder_sig, dmp_out);

       output_task(trigger_chan);

       multi_motor_task(oMotorPWMA, oMotorPWMB, oMotorControl, motor_cmd_chan);
       encoder_task(iEncoders, oLED1, oLED2, encoder_sig);
       imu_task(dmp_out);


   }

   return 0;
}

void run_wifi_setup()
{
    line("dofile(\"wif.lua\")");

}

void line(const char buffer[])
{
    //delay by about a 4th to an 8th of a second ?
    timer tmr;
    unsigned time;
    tmr :> time;
    //tmr when timerafter(time + TICKS_PER_SEC/8) :> void;
    //tmr when timerafter(time + TICKS_PER_SEC/2) :> void;

    // have to slow to TICKS_PER_SEC
    tmr when timerafter(time + TICKS_PER_SEC) :> void;

    uart_transmit_bytes(oWiFiRX, buffer, BAUDRATE);
    uart_transmit_bytes(oWiFiRX, "\r", BAUDRATE);
    uart_transmit_bytes(oWiFiRX, "\n", BAUDRATE);
    //uart_transmit_bytes(oWiFiRX, "\0", BAUDRATE);
}

void output_task(chanend trigger_chan)
{
    timer t;
    unsigned time;
    message_t msg;
    while(1)
    {
        trigger_chan :> msg;
        if(strcmp(msg.data, "run_wifi_setup") == 0)
        {
            run_wifi_setup();
        }
        else
        {
            // send over the UART port
            line(msg.data);
        }
        //trigger_chan :> int tmp;
        //send_blink_program();

        /*
        remove_blink_program();
        t :> time;
        t when timerafter(time += XS1_TIMER_HZ) :> void;

        write_blink_program();

        t :> time;
        t when timerafter(time += XS1_TIMER_HZ) :> void;


        read_blink_program();

        t :> time;
        t when timerafter(time += XS1_TIMER_HZ) :> void;


        run_blink_program();
        */

        /*


        remove_wifi_program();
        t :> time;
        t when timerafter(time += XS1_TIMER_HZ) :> void;


        write_wifi_program();

        t :> time;
        t when timerafter(time += XS1_TIMER_HZ) :> void;


        read_wifi_program();

        t :> time;
        t when timerafter(time += XS1_TIMER_HZ) :> void;



        run_wifi_program();

        */

    }
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
void uart_to_console_task(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out)
{
    const char * ptr = "lua: cannot open init.lua";
    char buffer[LENTHBUFFER];
    char str[LENTHBUFFER];
    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;
    yprMsg.p = 0;
    yprMsg.r = 0;

    int flag = 0;
    int flagR = 0;
    int flagL = 0;
    int newCommand = 0;
    float currentYaw;
    timer tmr;
    unsigned time;


    int i = 0;
    while(1)
    {

        select
        {
            // get ypr info
        case dmp_out :> yprMsg:
            //printf("y: %f  p: %f  r: %f\n", yprMsg.y, yprMsg.p, yprMsg.r);
            break;
            // get encoder info
        case encoder_sig:> en:
            break;
            // process command
        default:

            char chr;
            chr = uart_receive_byte(iWiFiTX, BAUDRATE);

            if(chr == '\n' || chr == '\r' || i == LENTHBUFFER - 1)
            {
                newCommand = 1; // a new command is coming
                buffer[i] = '\0';
                printstrln(buffer);
                i = 0;

                if(strcmp(ptr, buffer) == 0)
                {

                    //trigger_chan <: 0;
                    strcpy(msg.data, "run_wifi_setup");
                    trigger_chan <: msg;
                }
                else if(strcmp("F", buffer) == 0) // chr =='F'
                {
                    flag = 1;
                    newCommand = 0; // became old command

                    currentYaw = yprMsg.y;
                    //printstr("Full forward\n");
                    strcpy(msg.data, "OK: forward full");
                    trigger_chan <: msg;
                    driveforwardfullspeed(out_motor);

                    // adjust yaw to keep robot straight
                    while(newCommand == 0)
                    {
                        select
                        {
                            case dmp_out :> yprMsg:
                                break;
                            // listen to new command
                            case iWiFiTX :> void:
                                newCommand = 1;
                                break;
                        }


                        if(yprMsg.y < currentYaw)
                        {
                            // adjust to left
                            turn(-100, 90, out_motor);
                        }
                        else if(yprMsg.y > currentYaw)
                        {
                            // adjustt to right
                            turn(-90, 100, out_motor);
                        }

                    }


                }
                else if(strcmp("f", buffer) == 0)
                {
                    flag = 1;
                    currentYaw = yprMsg.y;
                    //printstr("Half forward\n");
                    strcpy(msg.data, "OK: forward haft");
                    trigger_chan <: msg;
                    driveforwardhaftspeed(out_motor);
                    // adjust yaw to keep robot straight
                    while(newCommand == 0)
                    {
                        select
                        {
                        case dmp_out :> yprMsg:
                            break;
                            // listen to new command
                        case iWiFiTX :> void:
                            newCommand = 1;
                            break;
                        }


                        if(yprMsg.y < currentYaw)
                        {
                            // adjust to left
                            turn(-50, 40, out_motor);
                        }
                        else if(yprMsg.y > currentYaw)
                        {
                            // adjustt to right
                            turn(-40, 50, out_motor);
                        }

                    }
                }
                else if(strcmp("R", buffer) == 0)
                {
                    flag = 1;

                    //printstr("Full backward\n");
                    strcpy(msg.data, "OK: backward full");
                    trigger_chan <: msg;
                    drivebackwardfullspeed(out_motor);
                    // adjust yaw to keep robot straight
                    while(newCommand == 0)
                    {
                        select
                        {
                        case dmp_out :> yprMsg:
                            break;
                            // listen to new command
                        case iWiFiTX :> void:
                            newCommand = 1;
                            break;
                        }


                        if(yprMsg.y < currentYaw)
                        {
                            // adjust to left
                            turn(100, -90, out_motor);
                        }
                        else if(yprMsg.y > currentYaw)
                        {
                            // adjustt to right
                            turn(90, -100, out_motor);
                        }
                    }
                }
                else if(strcmp("r", buffer) == 0)
                {
                    flag = 1;

                    //printstr("Haft backward\n");
                    strcpy(msg.data, "OK: backward half");
                    trigger_chan <: msg;
                    drivebackwardhaftspeed(out_motor);
                    // adjust yaw to keep robot straight
                    while(newCommand == 0)
                    {
                        select
                        {
                        case dmp_out :> yprMsg:
                            break;
                            // listen to new command
                        case iWiFiTX :> void:
                            newCommand = 1;
                            break;
                        }


                        if(yprMsg.y < currentYaw)
                        {
                            // adjust to left
                            turn(50, -40, out_motor);
                        }
                        else if(yprMsg.y > currentYaw)
                        {
                            // adjustt to right
                            turn(40, -50, out_motor);
                        }
                    }
                }
                else if(strcmp(">", buffer) == 0)
                {
                    flag = 1;

                    //printstr("Turn right\n");
                    strcpy(msg.data, "OK: Turn right");
                    trigger_chan <: msg;
                    turn(2, 80, out_motor);
                }
                else if(strcmp("<", buffer) == 0)
                {
                    flag = 1;

                    //printstr("Turn left\n");
                    strcpy(msg.data, "OK: Turn left");
                    trigger_chan <: msg;
                    turn(80, 20, out_motor);

                }
                else if(strcmp(",", buffer) == 0)
                {
                    flag = 1;
                    flagL = 1;
                    // get current yaw
                    select
                    {
                        case  dmp_out :> yprMsg:
                            break;
                    }
                    currentYaw = yprMsg.y;
                    printf("currentYaw = %f\n", currentYaw);
                    strcpy(msg.data, "OK: Turn left 90 degree");
                    trigger_chan <: msg;
                    //turn(100, 2, out_motor);
                    // get current yaw
                    //currentYaw = yprMsg.y;
                    turn(50, 0, out_motor);
                    while(1)
                    {
                        // check new yaw
                        select
                        {
                            case  dmp_out :> yprMsg:
                                break;
                        }
                        // turn close exactly to 90
                        // consider to change this formula
                        if(abs(currentYaw - yprMsg.y) >= 1.0)  //1.6
                        {
                            printf("y = %f\n", yprMsg.y);
                            stop(out_motor);
                            break;
                        }


                    }
                }
                else if(strcmp(".", buffer) == 0)
                {
                    flag = 1;
                    flagR = 1;
                    // get current yaw
                    select
                    {
                        case  dmp_out :> yprMsg:
                            break;
                    }
                    currentYaw = yprMsg.y;
                    printf("currentYaw = %f\n", currentYaw);
                    strcpy(msg.data, "OK: Turn right 90 degree");
                    trigger_chan <: msg;

                    turn(0, 50, out_motor);
                    while(1)
                    {
                        // check new yaw
                        select
                        {
                            case  dmp_out :> yprMsg:
                                break;
                        }
                        // turn close exactly to 90
                        // consider to change this formula
                        if(abs(currentYaw - yprMsg.y) >= 1.0)  //1.6
                        {
                            printf("y = %f\n", yprMsg.y);
                            stop(out_motor);
                            break;
                        }



                    }

                }
                else if(strcmp("x", buffer) == 0)
                {
                    flag = 1;

                    //printstr("Stop\n");
                    strcpy(msg.data, "OK: Stop");
                    trigger_chan <: msg;
                    stop(out_motor);
                }
                else if(strcmp("?", buffer) == 0)
                {
                    flag = 1;

                    tmr :> time;
                    select
                    {
                        case dmp_out :> yprMsg:
                            break;
                            // this is not waiting TICKS_PER_MICROSEC
                            // it is a time out
                        //case tmr when timerafter(time += TICKS_PER_MICROSEC) :> void:
                           // break;
                    }
                    //dmp_out :> yprMsg;
                    sprintf (str, "OK: ? Left: %d Right: %d y: %f p: %f r: %f", en.left, en.right, yprMsg.y, yprMsg.p, yprMsg.r);


                    strcpy(msg.data, str);
                    trigger_chan <: msg;



                }
                else
                {
                    if(flag == 1)
                    {
                        //printstr("\nunrecognized command: ");
                        //printstrln(buffer);
                        strcpy(msg.data, "unrecognized command: ");
                        strcat(msg.data, buffer);
                        trigger_chan <: msg;

                    }


                }
            }
            else
            {
                buffer[i] = chr;
                i++;

            }

            break;

        }

    }
}



/*
void toggle_port(out port oLED)
{
    timer tmr;
    unsigned int time;
    unsigned int delay;
    delay = XS1_TIMER_HZ / 4;
    tmr :> time;
    while(1)
    {
        oLED <: 1;
        time += delay;
        tmr when timerafter(time) :> void;
        oLED <: 0;


    }
}
*/
void uart_transmit_byte(out port oPort, char value, unsigned int baudrate)
{
    unsigned time;
    timer tmr;

    tmr :> time;
    // ouput start bit = 0
    oPort <: 0;
    time += BIT_TIME;
    tmr when timerafter(time) :> void;

    /*output data bits*/
    for(int i = 0; i < 8; i++)
    {
        oPort <: >> value;
        time += BIT_TIME;
        tmr when timerafter(time) :> void;
    }

    // output stop bit
    oPort <: 1;
    time += BIT_TIME;
    tmr when timerafter(time) :> void;


}

void uart_transmit_bytes(out port oPort, const char values[], unsigned int baudrate)
{

    int i = 0;
    while(values[i] != '\0')
    {
        //printf("< %c\n", values[i]);
        uart_transmit_byte(oPort, values[i], baudrate);
        i++;
    }


}

char uart_receive_byte(in port iPort, unsigned int baudrate)
{
    char value;
    timer tmr;
    unsigned time;
    // wait for start bit
    iPort when pinseq(0) :> void;
    tmr :> time;
    time += BIT_TIME/2;

    // input data bits
    for(int i = 0; i < 8; i++)
    {
        time += BIT_TIME;
        tmr when timerafter(time) :> void;
        iPort :> >> value;
    }

    // input stop bit
    time += BIT_TIME;
    tmr when timerafter(time) :> void;
    iPort :> void;
    return value;

}


void uart_receive_bytes(in port iPort, char values[], unsigned int n, unsigned int baudrate)
{

    char value;
    for(int i = 0; i < n; i++)
    {
        value = uart_receive_byte(iPort, baudrate);
        values[i] = value;
        //printf("> %c\n",values[i]);

    }

}

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
    encoder_t en;
    en.left = 0;
    en. right = 0;

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
            en.left++;
            //out_encoder_cmd_chan <: 1;
            out_encoder_cmd_chan <: en;
            //out_encoder_cmd_chan <: 1;
            sig1 = newSig1;

        }

        if(sig2 != newSig2)
        {
            en.right++;
            //out_encoder_cmd_chan <: 2;
            out_encoder_cmd_chan <: en;
            //out_encoder_cmd_chan <: 2;
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

void turn(int left_duty, int right_duty, chanend out_motor)
{
    printstr("turn\n");
    motor_cmd_t cmd;
    cmd.left_duty_cycle  = left_duty;
    cmd.right_duty_cyle = right_duty;
    out_motor <: cmd;

}

void turnRight90degree(chanend out_motor)
{
    motor_cmd_t cmd;
    cmd.left_duty_cycle  = -2;
    cmd.right_duty_cyle = 100;
    out_motor <: cmd;
}
void turnLeft90degree(chanend out_motor)
{
    motor_cmd_t cmd;
    cmd.left_duty_cycle  = 100;
    cmd.right_duty_cyle = 2;
    out_motor <: cmd;
}

void driveforwardfullspeed(chanend out_motor)
{

    motor_cmd_t cmd;
    /*cmd.left_duty_cycle = 100;
    cmd.right_duty_cyle = -100;*/
    cmd.left_duty_cycle = -100;
    cmd.right_duty_cyle = 100;
    out_motor <: cmd;
}

void driveforwardhaftspeed(chanend out_motor)
{


    motor_cmd_t cmd;

    //cmd.left_duty_cycle = 50;
    //cmd.right_duty_cyle = -50;
    cmd.left_duty_cycle = -50; // for test only
    cmd.right_duty_cyle = 50;
    out_motor <: cmd;
}

void drivebackwardfullspeed(chanend out_motor)
{


    motor_cmd_t cmd;
    cmd.left_duty_cycle = 100;
    cmd.right_duty_cyle = -100;
    out_motor <: cmd;
}

void drivebackwardhaftspeed(chanend out_motor)
{

    motor_cmd_t cmd;
    cmd.left_duty_cycle = 50;
    cmd.right_duty_cyle = -50;
    out_motor <: cmd;
}
void stop(chanend out_motor)
{
    //timer tmr;
    // unsigned int time;
    printstr("stop\n");
    motor_cmd_t cmd;
    cmd.left_duty_cycle = 0;
    cmd.right_duty_cyle = 0;
    out_motor <: cmd;
    //tmr when timerafter(time + PWM_FRAME_TICKS) :> void;

}

void imu_task(chanend dmp_out)
{

    ypr_t ypr_cmd;
    int packetsize,mpuIntStatus,fifoCount;
    int address;
    unsigned char result[64];                           //holds dmp packet of data
    float qtest;
    float q[4]={0,0,0,0},g[3]={0,0,0},euler[3]={0,0,0},ypr[3]={0,0,0};
    int but_state;
    int fifooverflowcount=0,fifocorrupt=0;
    int GO_FLAG=1;

    printf("Starting MPU6050...\n");
    mpu_init_i2c(imu);
    printf("I2C Initialized...\n");
    address=mpu_read_byte(imu.i2c, MPU6050_RA_WHO_AM_I);
    printf("MPU6050 at i2c address: %.2x\n",address);
    mpu_dmpInitialize(imu);
    mpu_enableDMP(imu,1);   //enable DMP

    mpuIntStatus=mpu_read_byte(imu.i2c,MPU6050_RA_INT_STATUS);
    printf("MPU Interrupt Status:%d\n",mpuIntStatus);
    packetsize=42;                  //size of the fifo buffer
    delay_milliseconds(250);

    //The hardware interrupt line is not used, the FIFO buffer is polled
    while (GO_FLAG){
        mpuIntStatus=mpu_read_byte(imu.i2c,MPU6050_RA_INT_STATUS);
        if (mpuIntStatus >= 2) {
            fifoCount = mpu_read_short(imu.i2c,MPU6050_RA_FIFO_COUNTH);
            if (fifoCount>=1024) {              //fifo overflow
                mpu_resetFifo(imu);
                fifooverflowcount+=1;           //keep track of how often this happens to tweak parameters
                //printf("FIFO Overflow!\n");
            }
            while (fifoCount < packetsize) {    //wait for a full packet in FIFO buffer
                fifoCount = mpu_read_short(imu.i2c,MPU6050_RA_FIFO_COUNTH);
            }
            //printf("fifoCount:%d\n",fifoCount);
            mpu_getFIFOBytes(imu,packetsize,result);    //retrieve the packet from FIFO buffer

            mpu_getQuaternion(result,q);
            qtest=sqrt(q[0]*q[0]+q[1]*q[1]+q[2]*q[2]+q[3]*q[3]);
            if (fabs(qtest-1.0)<0.001){                             //check for fifo corruption - quat should be unit quat

                mpu_getGravity(q,g);

                mpu_getEuler(euler,q);


                mpu_getYawPitchRoll(q,g,ypr);

                ypr_cmd.y = ypr[0];
                ypr_cmd.p = ypr[1];
                ypr_cmd.r = ypr[2];

                dmp_out <: ypr_cmd;

            } else {
                mpu_resetFifo(imu);     //if a unit quat is not received, assume fifo corruption
                fifocorrupt+=1;
            }
        }
        butP :> but_state;               //check to see if button is pushed to end program, low means pushed
        but_state &=0x1;
        if (but_state==0){
            printf("Exiting...\n");
            GO_FLAG=0;
        }


    }
    mpu_Stop(imu);      //reset hardware gracefully and put into sleep mode
    printf("Fifo Overflows:%d Fifo Corruptions:%d\n",fifooverflowcount,fifocorrupt);

    exit(0);
}
