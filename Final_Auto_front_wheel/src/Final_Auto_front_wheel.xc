/*
 * Final_Auto_front_wheel.xc
 *
 *  Created on: Nov 18, 2018
 *      Author: quyetnguyen
 */

/*
 * Final_Auto.xc
 *
 *  Created on: Nov 18, 2018
 *      Author: quyetnguyen
 */


#include <bfs.h>

#include <print.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <platform.h>
#include <math.h>
#include "mpu6050.h"
#include "i2c.h"
#include <command.h>
#include <ctype.h>
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

#define BAUDRATE 9600 // 9600
#define PWM_FRAME_TICKS TICKS_PER_MS
#define BIT_TIME XS1_TIMER_HZ/BAUDRATE // ticks per bit
char commandArr[ELEMENT_COUNT/2];
// Wheel control
//using GY-521 breakout board with 3.3V
struct IMU imu = {{
        on tile[0]:XS1_PORT_1L,                         //scl
        on tile[0]:XS1_PORT_4E,                         //sda
        400},};                                         //clockticks (1000=i2c@100kHz)

void commandF(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag);
void commandf(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag);
void commandR(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag);
void commandr(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag);
void commandT(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag);
void commandS(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag);
void commandt(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag);
void commands(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag);


void commandF_100(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[]);
void commandf_50(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[]);
void commandR_100(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[]);
void commandr_50(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[]);

int countWheelTicks(chanend encoder_sig);

void uart_transmit_byte(out port oPort, char value, unsigned int baudrate);
//char uart_receive_byte(in port iPort, unsigned int baudrate);
char uart_receive_byte(in port iPort, unsigned int baudrate, int read_flag);

void uart_transmit_bytes(out port oPort, const char values[], unsigned int baudrate);
void uart_receive_bytes(in port iPort, char values[], unsigned int n, unsigned int baudrate);
//void toggle_port(out port oLED, unsigned int hz);

void uart_to_console_task(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out);
void line(const char buffer[]);

void output_task(chanend trigger_chan);
void run_wifi_setup();




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

/*
// Path
void generatePath(int rankArr[]);
// Command
void generateCommand(int ranArr[], char command[]);
*/
int main()
{

   chan dmp_out;
   chan trigger_chan;
   chan motor_cmd_chan;
   chan encoder_sig;
   oSTB <: 1;
   oWiFiRX <: 1;
   int rankArr[ELEMENT_COUNT];

   generatePath(rankArr);

   /*for(int i = 0; i < ELEMENT_COUNT; i++)
   {
       if(rankArr[i] != -1)
       {
           printf("(%d, %d) \n", ROW(rankArr[i]), COL(rankArr[i]));
       }

   }*/
   generateCommand(rankArr, commandArr);
   free(rankArr);

   for(int i = 0; i < ELEMENT_COUNT/2; i++)
   {

       if(commandArr[i] != 'n')
       {
           printf("%c\n", commandArr[i]);
       }
   }

   par
   {

       //generatePath();
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

    }
}
/*
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
}*/
/*
float getAverageYaw(int n, chanend dmp_out)
{
    ypr_t yprMsg;
    float result = 0;
    for(int i = 0; i < n; i++)
    {
        select
        {
            case dmp_out :> yprMsg:
                break;
        }
        result += yprMsg.y;
    }

    result = result/5;
    return result;
}*/
void uart_to_console_task(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out)
{
    //int rankArr[ELEMENT_COUNT];
    //char command[ELEMENT_COUNT/2];
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
    int read_flag = 0;

    int cm_good = 1;
    int flag = 0;

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
            chr = uart_receive_byte(iWiFiTX, BAUDRATE, read_flag);

            if(chr == '\n' || chr == '\r' || i == LENTHBUFFER - 1)
            {
                //newCommand = 1; // a new command is coming
                buffer[i] = '\0';
                printstrln(buffer);
                i = 0;

                if(strcmp(ptr, buffer) == 0)
                {

                    //trigger_chan <: 0;
                    strcpy(msg.data, "run_wifi_setup");
                    trigger_chan <: msg;
                }
                else if(strcmp("A", buffer) == 0) // Automation
                {
                    // generate command
                    flag = 1;
                    //printstr("path\n");
                    //generatePath(rankArr);
                    /*
                                    for(int i = 0; i < ELEMENT_COUNT; i++)
                                    {
                                        if(rankArr[i] != -1)
                                        {
                                            printf("(%d, %d) \n", ROW(rankArr[i]), COL(rankArr[i]));
                                        }

                                    }*/
                    //generateCommand(rankArr, command);
                    //printstr("command\n");
                    sprintf (str, "Automation");
                    strcpy(msg.data, str);
                    trigger_chan <: msg;
                    int count;
                    for(int i = 0; i < ELEMENT_COUNT/2; i++)
                    {

                        if(commandArr[i] != 'n')
                        {
                            //printf("%c\n", commandArr[i]);
                            //printf("(%d, %d) \n", ROW(rankArr[i]), COL(rankArr[i]));
                            //printstr(command[i]);
                            //printf("%c\n", command[i]);

                            if(commandArr[i] == 'f')
                            {
                                printstr("f\n");
                                // move forward
                                //commandf_50(trigger_chan, out_motor, encoder_sig, dmp_out, str, buffer);
                                //driveforwardhaftspeed(out_motor);

                                turn(30, 30, out_motor);
                                // count wheel tick to stop
                                count = countWheelTicks(encoder_sig);
                                if(count == 8)
                                {
                                    stop(out_motor);
                                }
                                count = 0;

                            }
                            else if(commandArr[i] == '.')
                            {
                                printstr("r\n");
                                turnRight90degree(trigger_chan, out_motor, encoder_sig, dmp_out);

                            }
                            else if(commandArr[i] ==',')
                            {
                                // turn left
                                printstr("l\n");
                                turnLeft90degree(trigger_chan, out_motor, encoder_sig, dmp_out);
                            }
                            else if(commandArr[i] == 'x')
                            {
                                // stop
                                printstr("x\n");
                                stop(out_motor);

                            }
                            //printstr("\n");
                        }


                    }

                    //free(rankArr);
                    //free(command);
                    // execute command

                }

                else if(strcmp("F", buffer) == 0) // chr =='F'
                {
                    flag = 1;
                    commandF_100(trigger_chan, out_motor, encoder_sig,
                                               dmp_out, str, buffer);

                }

                else if(strncmp(buffer,"F", 1) == 0)
                {
                    flag = 1;
                    commandF(trigger_chan, out_motor, encoder_sig,
                            dmp_out, str, buffer, read_flag);

                }
                else if(strcmp("f", buffer) == 0)
                {
                    flag = 1;
                    commandf_50(trigger_chan, out_motor, encoder_sig,
                            dmp_out, str, buffer);
                }

                else if(strncmp(buffer,"f", 1) == 0)
                {
                    flag = 1;
                    commandf(trigger_chan, out_motor, encoder_sig,
                            dmp_out, str, buffer, read_flag);
                }

                else if(strcmp("R", buffer) == 0)
                {
                    flag = 1;
                    commandR_100(trigger_chan, out_motor, encoder_sig,
                            dmp_out, str, buffer);

                }
                else if(strncmp(buffer,"R", 1) == 0)
                {
                    flag = 1;
                    cm_good = 1;
                    //printstr("Rpecent\n");
                    int len = strlen(buffer);
                    // check new command
                    for(int i = 1; i < len; i++)
                    {
                        if(isalpha(buffer[i]))
                        {
                            cm_good = 0;
                            strcpy(msg.data, "unrecognized command: ");
                            strcat(msg.data, buffer);
                            trigger_chan <: msg;

                            break;
                        }
                    }
                    //printf("cm_good = %d\n", cm_good);
                    if(cm_good == 1)
                    {
                        commandR(trigger_chan, out_motor, encoder_sig,
                                dmp_out, str, buffer, read_flag);
                    }

                }

                else if(strcmp("r", buffer) == 0)
                {
                    flag = 1;
                    commandr_50(trigger_chan, out_motor, encoder_sig,
                            dmp_out, str, buffer);

                }

                else if(strncmp(buffer,"r", 1) == 0)
                {
                    flag = 1;
                    commandr(trigger_chan, out_motor, encoder_sig,
                            dmp_out, str, buffer, read_flag);

                }

                else if(strncmp(buffer,"T", 1) == 0)
                {
                    flag = 1;
                    commandT(trigger_chan, out_motor, encoder_sig,
                            dmp_out, str, buffer, read_flag);
                }
                /*
                else if(strncmp(buffer,"S", 1) == 0)
                {
                    flag = 1;
                    commandS(trigger_chan, out_motor, encoder_sig,
                            dmp_out, str, buffer);
                }

                else if(strncmp(buffer,"t", 1) == 0)
                {
                    flag = 1;
                    commandt(trigger_chan, out_motor, encoder_sig,
                                               dmp_out, str, buffer);
                }

                else if(strncmp(buffer,"s", 1) == 0)
                {
                    flag = 1;
                    commands(trigger_chan, out_motor, encoder_sig,
                            dmp_out, str, buffer);
                }*/

                else if(strncmp(buffer,">", 1) == 0)
                {
                    flag = 1;
                    int len = strlen(buffer);
                    int duty_cycle = 0;
                    cm_good = 1;
                    for(int i = 0; i < len; i++)
                    {
                        if(buffer[i] == '>')
                        {
                            duty_cycle += 10;


                        }
                        else
                        {
                            cm_good = 0;
                            strcpy(msg.data, "unrecognized command: ");
                            //strcat(msg.data, buffer);
                            trigger_chan <: msg;
                            break;
                        }

                    }

                    if(cm_good == 1)
                    {
                        sprintf (str, "OK: Turn right: %d", duty_cycle);
                        strcpy(msg.data, str);
                        trigger_chan <: msg;
                        turn(-duty_cycle, duty_cycle, out_motor);
                    }


                }
                else if(strncmp(buffer,"<", 1) == 0)
                {
                    flag = 1;
                    int len = strlen(buffer);
                    int duty_cycle = 0;
                    cm_good = 1;
                    for(int i = 0; i < len; i++)
                    {
                        if(buffer[i] == '<')
                        {
                            duty_cycle += 10;

                        }
                        else
                        {
                            cm_good = 0;
                            strcpy(msg.data, "unrecognized command: ");
                            //strcat(msg.data, buffer);
                            trigger_chan <: msg;
                            break;
                        }

                    }

                    if(cm_good == 1)
                    {
                        sprintf (str, "OK: Turn left: %d", duty_cycle);
                        strcpy(msg.data, str);
                        trigger_chan <: msg;
                        turn(duty_cycle, -duty_cycle, out_motor);
                    }


                }
                else if(strcmp(",", buffer) == 0)
                {
                    flag = 1;
                    turnLeft90degree(trigger_chan, out_motor, encoder_sig, dmp_out);


                }
                else if(strcmp(".", buffer) == 0)
                {
                    flag = 1;

                    turnRight90degree(trigger_chan, out_motor, encoder_sig, dmp_out);


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

                        flag = 0;

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

char uart_receive_byte(in port iPort, unsigned int baudrate, int read_flag)
{
    char value;
    timer tmr;
    unsigned time;
    if(read_flag == 1)
    {
        // dont neet to wait for start bit
        // some where is read start bit already
        // this modification for reading new command
        // reset
        read_flag = 0;
    }
    else
    {
        // wait for start bit
        iPort when pinseq(0) :> void;
    }

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
/*
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
*/

/*
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
    cmd.right_duty_cycle = 0;
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


        if(cmd.right_duty_cycle < 0)
        {
            delay_high_right = -(cmd.right_duty_cycle * PWM_FRAME_TICKS)/100;
        }
        else
        {
            delay_high_right = (cmd.right_duty_cycle * PWM_FRAME_TICKS)/100;
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
        /*
        if(cmd.left_duty_cycle < 0)
        {
            oMotorControl <: AIN2_ON | BIN2_ON;
        }
        else
        {
            oMotorControl <: AIN1_ON | BIN1_ON;
        }
        */
        if(cmd.left_duty_cycle < 0 && cmd.right_duty_cycle < 0)
        {
            oMotorControl <: AIN2_ON | BIN2_ON;
        }
        else if(cmd.left_duty_cycle > 0 && cmd.right_duty_cycle > 0)
        {
            oMotorControl <: AIN1_ON | BIN1_ON;
        }
        else if(cmd.left_duty_cycle > 0 && cmd.right_duty_cycle < 0)
        {
            oMotorControl <: AIN1_ON | BIN2_ON;
        }
        else if(cmd.left_duty_cycle < 0 && cmd.right_duty_cycle > 0)
        {
            oMotorControl <: AIN2_ON | BIN1_ON;

        }
        else if(cmd.left_duty_cycle ==  0 && cmd.right_duty_cycle > 0)
        {
            oMotorControl <: BIN1_ON;
        }
        else if(cmd.left_duty_cycle ==  0 && cmd.right_duty_cycle < 0)
        {
            oMotorControl <: BIN2_ON;
        }
        else if(cmd.left_duty_cycle > 0 && cmd.right_duty_cycle == 0)
        {
            oMotorControl <: AIN1_ON;
        }
        else if(cmd.left_duty_cycle < 0 && cmd.right_duty_cycle == 0)
        {
            oMotorControl <: AIN2_ON;
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
    en.right = 0;

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
            en.wheel = 1;
            //out_encoder_cmd_chan <: 1;
            out_encoder_cmd_chan <: en;
            //out_encoder_cmd_chan <: 1;
            sig1 = newSig1;


        }

        if(sig2 != newSig2)
        {
            en.right++;
            en.wheel = 2;
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
/*
void turn(int left_duty, int right_duty, chanend out_motor)
{
    //printstr("turn\n");
    motor_cmd_t cmd;
    cmd.left_duty_cycle  = left_duty;
    cmd.right_duty_cycle = right_duty;
    out_motor <: cmd;

}
*/
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
            //printf("Exiting...\n");
            GO_FLAG=0;
        }


    }
    mpu_Stop(imu);      //reset hardware gracefully and put into sleep mode
    //printf("Fifo Overflows:%d Fifo Corruptions:%d\n",fifooverflowcount,fifocorrupt);

    exit(0);
}
void commandF(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        chanend dmp_out, char str[], char buffer[], int read_flag)
{

    printstr("commandF\n");
    message_t msg;
    ypr_t yprMsg;
    int newCommand = 0;

    float currentYaw;

    int len = strlen(buffer);
    int duty_cycle = 0;
    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }

    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;
    printf("currentYaw = %f\n", currentYaw);
    sprintf (str, "OK: forward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(duty_cycle, duty_cycle, out_motor);

    // adjust yaw to keep robot straight
    while(newCommand == 0)
    {

        //printstr("loop\n");
        select
        {
        case dmp_out :> yprMsg:
            break;
            // listen to new command
        //case iWiFiTX :> void:
        case iWiFiTX when pinseq(0) :> void:
            printstr("new command\n");
            newCommand = 1;
            read_flag = 1;

            break;
        }

        //printf("new currentYaw = %f\n", yprMsg.y);
        if(yprMsg.y < currentYaw)
        {
            // adjust to right
            // reduce right
            // increase left

            turn(duty_cycle - (duty_cycle*0.05), duty_cycle,  out_motor);

        }
        else if(yprMsg.y > currentYaw)
        {

            // adjust to left
            // increase right
            // reduce left
            turn(duty_cycle, duty_cycle - (duty_cycle*0.05), out_motor);
        }
    }
}
void commandf(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        chanend dmp_out, char str[], char buffer[], int read_flag)
{

    message_t msg;

    ypr_t yprMsg;
    int newCommand = 0;

    float currentYaw;

    int len = strlen(buffer);
    int duty_cycle = 0;
    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }

    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;
    //printf("currentYaw = %f\n", currentYaw);
    sprintf (str, "OK: forward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(duty_cycle, duty_cycle, out_motor);

    // adjust yaw to keep robot straight
    while(newCommand == 0)
    {

        //printstr("loop\n");
        select
        {
        case dmp_out :> yprMsg:
            break;
            // listen to new command
            //case iWiFiTX :> void:
        case iWiFiTX when pinseq(0) :> void:
            printstr("new command\n");
            newCommand = 1;
            read_flag = 1;

            break;
        }

        //printf("new currentYaw = %f\n", yprMsg.y);
        if(yprMsg.y < currentYaw)
        {
            // adjust to right
            // reduce right
            // increase left

            turn(duty_cycle - (duty_cycle*0.05), duty_cycle,  out_motor);

        }
        else if(yprMsg.y > currentYaw)
        {

            // adjust to left
            // increase right
            // reduce left
            turn(duty_cycle, duty_cycle - (duty_cycle*0.05), out_motor);
        }

    }
}
void commandR(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag)
{
    //printstr("commandR\n");
    message_t msg;

    ypr_t yprMsg;

    float currentYaw;

    int newCommand = 0;
    int len = strlen(buffer);
    int duty_cycle = 0;
    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';


    }


    newCommand = 0;
    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;
    //printf("currentYaw = %f\n", currentYaw);
    sprintf (str, "OK: Backward %d duty cycle", duty_cycle);

    strcpy(msg.data, str);
    trigger_chan <: msg;

    turn(-duty_cycle, -duty_cycle, out_motor);
    // adjust yaw to keep robot straight
    while(newCommand == 0)
    {

        select
        {
        case dmp_out :> yprMsg:
            break;
        // listen to new command

        case iWiFiTX when pinseq(0) :> void:
            printstr("new command\n");
            newCommand = 1;
            read_flag = 1;
            break;
        }


        if(yprMsg.y < currentYaw)
        {
            // adjust to right
            // reduce right
            // increase left

            turn(-duty_cycle, -duty_cycle + (duty_cycle*0.05), out_motor);

        }
        else if(yprMsg.y > currentYaw)
        {

            // adjust to left
            // increase right
            // reduce left
            turn(-duty_cycle + (duty_cycle*0.05), -duty_cycle, out_motor);
        }
    }

}

void commandr(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag)
{
    //printstr("commandr\n");
    message_t msg;

    ypr_t yprMsg;

    float currentYaw;

    int newCommand = 0;
    int len = strlen(buffer);
    int duty_cycle = 0;
    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';


    }


    newCommand = 0;
    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;

    sprintf (str, "OK: Backward %d duty cycle", duty_cycle);

    strcpy(msg.data, str);
    trigger_chan <: msg;

    turn(-duty_cycle, -duty_cycle, out_motor);
    // adjust yaw to keep robot straight
    while(newCommand == 0)
    {

        select
        {
        case dmp_out :> yprMsg:
            break;
            // listen to new command

        case iWiFiTX when pinseq(0) :> void:
            printstr("new command\n");
            newCommand = 1;
            read_flag = 1;
            break;
        }


        if(yprMsg.y < currentYaw)
        {
            // adjust to right
            // reduce right
            // increase left

            turn(-duty_cycle, -duty_cycle + (duty_cycle*0.05), out_motor);

        }
        else if(yprMsg.y > currentYaw)
        {

            // adjust to left
            // increase right
            // reduce left
            turn(-duty_cycle + (duty_cycle*0.05), -duty_cycle, out_motor);
        }
    }

}
void commandt(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag)
{

    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;

    int en_flag = 0; // encoder flag
    timer tmr;
    unsigned time;
    unsigned t0;
    unsigned t1;
    unsigned delay = 0; // delay bw 2 wheel ticks
    float currentYaw;

    int newCommand = 0;
    int duty_cycle = 0;
    int len = strlen(buffer);

    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }


    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;
    //printf("currentYaw = %f\n", currentYaw);
    sprintf (str, "OK: forward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(-duty_cycle, -duty_cycle, out_motor);

    // delay bw wheel ticks
    while(1)
    {
        encoder_sig:> en;
        if(en.wheel == 1 && en_flag == 0)
        {
            tmr :> t0;
            en_flag = 1;
        }
        else if(en.wheel == 1 && en_flag == 1)
        {
            tmr :> t1;
            en_flag = 0;
            delay = t1 - t0;
            //printf("en.left = %d en.right = %d\n en.wheel = %d", en.left, en.right, en.wheel);
            //printf("t0 = %ld t1 = %ld delay = %ld\n", t0, t1, delay);
            break;
        }


    }
    // adjust yaw to keep robot straight
    while(newCommand == 0)
    {
        //dmp_out :> yprMsg;
        //printstr("loop\n");
        select
        {
        case dmp_out :> yprMsg:

            break;
            // listen to new command
        case iWiFiTX when pinseq(0) :> void:
            //printstr()
            printstr("new command\n");
            read_flag = 1;
            newCommand = 1;
            break;

        }

        tmr :> time;
        select
        {


            // get encoder info
        case encoder_sig:> en:
            printstr("encoder\n");
            break;
            // Time out. Don't receive wheel rotation indication. Stop
        case tmr when timerafter(time + delay*(100 + duty_cycle)/100) :> void:
                stop(out_motor);
                break;

        }

        //printf("new currentYaw = %f\n", yprMsg.y);
        if(yprMsg.y < currentYaw)
        {
            // adjust to right
            // reduce right
            // increase left

            turn(-duty_cycle, -duty_cycle + (duty_cycle*0.05), out_motor);

        }
        else if(yprMsg.y > currentYaw)
        {

            // adjust to left
            // increase right
            // reduce left
            turn(-duty_cycle + (duty_cycle*0.05), -duty_cycle, out_motor);
        }
    }

}
void commands(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag)
{
    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;

    int en_flag = 0; // encoder flag
    timer tmr;
    unsigned time;
    unsigned t0;
    unsigned t1;
    unsigned delay = 0; // delay bw 2 wheel ticks
    float currentYaw;

    int newCommand = 0;
    int duty_cycle = 0;
    int len = strlen(buffer);

    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }


    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;
    //printf("currentYaw = %f\n", currentYaw);
    sprintf (str, "OK: forward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(-duty_cycle, -duty_cycle, out_motor);

    // delay bw wheel ticks
    while(1)
    {
        encoder_sig:> en;
        if(en.wheel == 1 && en_flag == 0)
        {
            tmr :> t0;
            en_flag = 1;
        }
        else if(en.wheel == 1 && en_flag == 1)
        {
            tmr :> t1;
            en_flag = 0;
            delay = t1 - t0;
            //printf("en.left = %d en.right = %d\n en.wheel = %d", en.left, en.right, en.wheel);
            break;
        }


    }
    // adjust yaw to keep robot straight
    while(newCommand == 0)
    {
        //dmp_out :> yprMsg;
        //printstr("loop\n");
        select
        {
        case dmp_out :> yprMsg:
            break;
            // listen to new command
        case iWiFiTX when pinseq(0) :> void:
            //printstr()
            printstr("new command\n");
            read_flag = 1;
            newCommand = 1;
            break;

        }

        tmr :> time;
        select
        {


            // get encoder info
        case encoder_sig:> en:
            break;
            // Time out. Don't receive wheel rotation indication. Stop
        case tmr when timerafter(time + delay*(100 + duty_cycle)/100) :> void:
                stop(out_motor);
                break;

        }

        //printf("new currentYaw = %f\n", yprMsg.y);
        if(yprMsg.y < currentYaw)
        {
            // adjust to right
            // reduce right
            // increase left

            turn(-duty_cycle, -duty_cycle + (duty_cycle*0.05), out_motor);

        }
        else if(yprMsg.y > currentYaw)
        {

            // adjust to left
            // increase right
            // reduce left
            turn(-duty_cycle + (duty_cycle*0.05), -duty_cycle, out_motor);
        }
    }

}
void commandT(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag)
{
    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;

    int en_flag = 0; // encoder flag
    timer tmr;
    unsigned time;
    unsigned t0;
    unsigned t1;
    unsigned delay = 0; // delay bw 2 wheel ticks
    float currentYaw;

    int newCommand = 0;
    int duty_cycle = 0;
    int len = strlen(buffer);

    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }


    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;
    //printf("currentYaw = %f\n", currentYaw);
    sprintf (str, "OK: backward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(duty_cycle, duty_cycle, out_motor);

    // delay bw wheel ticks
    while(1)
    {
        encoder_sig:> en;
        if(en.wheel == 1 && en_flag == 0)
        {
            tmr :> t0;
            en_flag = 1;
        }
        else if(en.wheel == 1 && en_flag == 1)
        {
            tmr :> t1;
            en_flag = 0;
            delay = t1 - t0;
            //printf("en.left = %d en.right = %d\n en.wheel = %d", en.left, en.right, en.wheel);
            break;
        }


    }
    // adjust yaw to keep robot straight
    while(newCommand == 0)
    {
        //dmp_out :> yprMsg;
        //printstr("loop\n");
        select
        {
        case dmp_out :> yprMsg:
            break;
            // listen to new command
        case iWiFiTX when pinseq(0) :> void:
            //printstr()
            printstr("new command\n");
            read_flag = 1;
            newCommand = 1;
            break;

        }

        tmr :> time;
        select
        {


            // get encoder info
        case encoder_sig:> en:
            break;
            // Time out. Don't receive wheel rotation indication. Stop
        case tmr when timerafter(time + delay*(100 + duty_cycle)/100) :> void:
                stop(out_motor);
                break;

        }

        //printf("new currentYaw = %f\n", yprMsg.y);
        if(yprMsg.y < currentYaw)
        {
            // adjust to right
            // reduce right
            // increase left

            turn(-duty_cycle, -duty_cycle + (duty_cycle*0.05), out_motor);

        }
        else if(yprMsg.y > currentYaw)
        {

            // adjust to left
            // increase right
            // reduce left
            turn(-duty_cycle + (duty_cycle*0.05), -duty_cycle, out_motor);
        }
    }
}

void commandS(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[], int read_flag)
{

    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;

    int en_flag = 0; // encoder flag
    timer tmr;
    unsigned time;
    unsigned t0;
    unsigned t1;
    unsigned delay = 0; // delay bw 2 wheel ticks
    float currentYaw;

    int newCommand = 0;
    int duty_cycle = 0;
    int len = strlen(buffer);

    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }


    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;
    //printf("currentYaw = %f\n", currentYaw);
    sprintf (str, "OK: backward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(-duty_cycle, -duty_cycle, out_motor);

    // delay bw wheel ticks
    while(1)
    {
        encoder_sig:> en;
        if(en.wheel == 1 && en_flag == 0)
        {
            tmr :> t0;
            en_flag = 1;
        }
        else if(en.wheel == 1 && en_flag == 1)
        {
            tmr :> t1;
            en_flag = 0;
            delay = t1 - t0;
            //printf("en.left = %d en.right = %d\n en.wheel = %d", en.left, en.right, en.wheel);
            break;
        }


    }
    // adjust yaw to keep robot straight
    while(newCommand == 0)
    {
        //dmp_out :> yprMsg;
        //printstr("loop\n");
        select
        {
        case dmp_out :> yprMsg:
            break;
            // listen to new command
        case iWiFiTX when pinseq(0) :> void:
            //printstr()
            printstr("new command\n");
            read_flag = 1;
            newCommand = 1;
            break;

        }

        tmr :> time;
        select
        {


            // get encoder info
        case encoder_sig:> en:
            break;
            // Time out. Don't receive wheel rotation indication. Stop
        case tmr when timerafter(time + delay*(100 + duty_cycle)/100) :> void:
                stop(out_motor);
                break;

        }

        //printf("new currentYaw = %f\n", yprMsg.y);
        if(yprMsg.y < currentYaw)
        {
            // adjust to right
            // reduce right
            // increase left

            turn(-duty_cycle, -duty_cycle + (duty_cycle*0.05), out_motor);

        }
        else if(yprMsg.y > currentYaw)
        {

            // adjust to left
            // increase right
            // reduce left
            turn(-duty_cycle + (duty_cycle*0.05), -duty_cycle, out_motor);
        }
    }
}


void commandF_100(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[])
{

    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;

    float currentYaw;

    int newCommand = 0; // became old command

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

            // adjust to right
            turn(-100, -95, out_motor);
        }
        else if(yprMsg.y > currentYaw)
        {
            // adjust to left
            turn(-95, -100, out_motor);
        }

    }

}
void commandf_50(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[])
{
    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;
    float currentYaw;
    int newCommand = 0; // became old command
    newCommand = 0;
    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;
    //printf("currentYaw = %f\n", currentYaw);
    //printstr("Half forward\n");
    strcpy(msg.data, "OK: forward half");
    trigger_chan <: msg;
    driveforwardhaftspeed(out_motor);
    // adjust yaw to keep robot straight
    while(newCommand == 0)
    {
        //dmp_out :> yprMsg;
        //printstr("loop\n");
        select
        {
        case dmp_out :> yprMsg:
            break;
        case iWiFiTX when pinseq(0) :> void:
            //printstr()
            //printstr("new command\n");
            newCommand = 1;
            break;
            // listen to new command
            //case iWiFiTX :> void:
            //  printstr("new command\n");
            //newCommand = 1;
            //break;
        }

        //printf("new currentYaw = %f\n", yprMsg.y);
        if(yprMsg.y < currentYaw)
        {
            // adjustt to right
            //printstr("right\n");
            turn(-50, -45, out_motor);
        }
        else if(yprMsg.y > currentYaw)
        {

            // adjust to left
            //printstr("left\n");
            turn(-45, -50, out_motor);
        }

    }

}

void commandR_100(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[]){

    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    int newCommand = 0; // became old command
    float currentYaw;
    dmp_out :> yprMsg;
    currentYaw = yprMsg.y;
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
            //case iWiFiTX :> void:
                //  newCommand = 1;
            //break;
            //}
            // listen to new command
        case iWiFiTX :> void:
            printstr("new command\n");
            newCommand = 1;
            break;
        }

        if(yprMsg.y < currentYaw)
        {
            // adjust to left
            turn(95, 100, out_motor);
        }
        else if(yprMsg.y > currentYaw)
        {
            // adjust to right
            turn(100, 95, out_motor);
        }
    }

}
void commandr_50(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out,
        char str[], char buffer[])
{
    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;

    float currentYaw;

    int newCommand = 0; // became old command

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
            turn(45, 50, out_motor);
        }
        else if(yprMsg.y > currentYaw)
        {
            // adjustt to right
            turn(50, 45, out_motor);
        }
    }


}


int countWheelTicks(chanend encoder_sig)
{
    int count = 0;
    encoder_t en;
    //printstr("countWheelTicks\n");
    while(1)
    {
        select
        {

            // get encoder info
            case encoder_sig:> en:
                if(en.wheel == 1)
                {
                    count = count + en.wheel;
                }

                break;
        }
        if(count == 8)
        {
            break;
        }

    }
    //printf("count = %d\n", count);
    return count;
}


