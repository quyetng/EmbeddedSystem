
/*
 * HW09-Robot.xc
 *
 *  Created on: Nov 18, 2018
 *      Author: quyetnguyen
 */



#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
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
    int wheel;
} encoder_t;


void uart_transmit_byte(out port oPort, char value, unsigned int baudrate);
char uart_receive_byte(in port iPort, unsigned int baudrate);

void uart_transmit_bytes(out port oPort, const char values[], unsigned int baudrate);
void uart_receive_bytes(in port iPort, char values[], unsigned int n, unsigned int baudrate);
void toggle_port(out port oLED, unsigned int hz);
//void toggle_port(out port oLED);
void uarttoconsoletask();
void uart_to_console_task(chanend trigger_chan, chanend out_motor, chanend encoder_sig);
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

void commandF(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[]);

void commandf(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[]);
void commandr(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[]);
void commandR(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[]);


void commandT(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[]);
void commandS(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[]);
void commandt(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[]);
void commands(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[]);
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

//
int main()
{


   //const char message[] = "";
   chan trigger_chan;
   chan motor_cmd_chan;
   chan encoder_sig;
   oSTB <: 1;
   oWiFiRX <: 1;

   par
   {
       //uart_transmit_bytes(oWiFiRX, message, BAUDRATE);
       //toggle_port(oLED, 2);
       //toggle_port(oLED);
       //uarttoconsoletask();

       uart_to_console_task(trigger_chan, motor_cmd_chan, encoder_sig);

       output_task(trigger_chan);

       multi_motor_task(oMotorPWMA, oMotorPWMB, oMotorControl, motor_cmd_chan);
       encoder_task(iEncoders, oLED1, oLED2, encoder_sig);

       //
       /*
       uart_to_console_task(trigger_chan, motor_cmd_chan, encoder_sig);

       output_task(trigger_chan);
       multi_motor_task(oMotorPWMA, oMotorPWMB, oMotorControl, motor_cmd_chan);
       encoder_task(iEncoders, oLED1, oLED2, encoder_sig);
       */
       //
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

void uart_to_console_task(chanend trigger_chan, chanend out_motor, chanend encoder_sig)
{
    const char * ptr = "lua: cannot open init.lua";
    char buffer[LENTHBUFFER];
    char str[LENTHBUFFER];
    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;
    int flag = 0;

    int cm_good;

    int i = 0;
    while(1)
    {

        char chr;
        chr = uart_receive_byte(iWiFiTX, BAUDRATE);
        if(chr == '\n' || chr == '\r' || i == LENTHBUFFER - 1)
        {
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

                strcpy(msg.data, "OK: forward full");
                trigger_chan <: msg;
                driveforwardfullspeed(out_motor);

            }
            else if(strncmp(buffer,"F", 1) == 0)
            {
                flag = 1;
                commandF(trigger_chan, out_motor, encoder_sig, str, buffer);


            }
            else if(strcmp("f", buffer) == 0)
            {
                flag = 1;

                strcpy(msg.data, "OK: forward half");
                trigger_chan <: msg;
                driveforwardhaftspeed(out_motor);
            }
            else if(strncmp(buffer,"F", 1) == 0)
            {
                flag = 1;
                commandf(trigger_chan, out_motor, encoder_sig, str, buffer);


            }
            else if(strcmp("R", buffer) == 0)
            {
                flag = 1;

                strcpy(msg.data, "OK: backward full");
                trigger_chan <: msg;
                drivebackwardfullspeed(out_motor);
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
                printf("cm_good = %d\n", cm_good);
                if(cm_good == 1)
                {
                    commandR(trigger_chan, out_motor, encoder_sig,
                            str, buffer);
                }

            }
            else if(strcmp("r", buffer) == 0)
            {
                flag = 1;

                strcpy(msg.data, "OK: backward half");
                trigger_chan <: msg;

                drivebackwardhaftspeed(out_motor);
            }
            else if(strncmp(buffer,"r", 1) == 0)
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
                printf("cm_good = %d\n", cm_good);
                if(cm_good == 1)
                {
                    commandR(trigger_chan, out_motor, encoder_sig,
                            str, buffer);
                }




            }

            else if(strncmp(buffer,"T", 1) == 0)
            {
                flag = 1;
                commandT(trigger_chan, out_motor, encoder_sig,
                        str, buffer);
            }
            else if(strncmp(buffer,"S", 1) == 0)
            {
                flag = 1;
                commandS(trigger_chan, out_motor, encoder_sig,
                        str, buffer);
            }

            else if(strncmp(buffer,"t", 1) == 0)
            {
                flag = 1;
                commandt(trigger_chan, out_motor, encoder_sig,
                        str, buffer);
            }

            else if(strncmp(buffer,"s", 1) == 0)
            {
                flag = 1;
                commands(trigger_chan, out_motor, encoder_sig,
                        str, buffer);
            }
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
                        strcat(msg.data, buffer);
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
                        strcat(msg.data, buffer);
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

                sprintf (str, "OK: ? Left: %d Right: %d", en.left, en.right);


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



    }
}
void uarttoconsoletask()
{
    char buffer[64];
    while(1)
    {
        for(int i = 0; i < 64; i++)
        {
            char chr;
            chr = uart_receive_byte(iWiFiTX, BAUDRATE);
            if(chr == '\n' || chr == '\r')
            {
                buffer[i] = '\0';
            }
            else
            {
                buffer[i] = chr;
            }

        }
        printstrln(buffer);


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

/*
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
*/
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
void turn(int left_duty, int right_duty, chanend out_motor)
{
    printstr("turn\n");
    motor_cmd_t cmd;
    cmd.left_duty_cycle  = left_duty;
    cmd.right_duty_cyle = right_duty;
    out_motor <: cmd;

}

void driveforwardfullspeed(chanend out_motor)
{

    motor_cmd_t cmd;
    cmd.left_duty_cycle = -100;
    cmd.right_duty_cyle = -100;
    out_motor <: cmd;
}

void driveforwardhaftspeed(chanend out_motor)
{


    motor_cmd_t cmd;
    cmd.left_duty_cycle = -50;
    cmd.right_duty_cyle = -50;
    out_motor <: cmd;
}

void drivebackwardfullspeed(chanend out_motor)
{


    motor_cmd_t cmd;
    cmd.left_duty_cycle = 100;
    cmd.right_duty_cyle = 100;
    out_motor <: cmd;
}

void drivebackwardhaftspeed(chanend out_motor)
{

    motor_cmd_t cmd;
    cmd.left_duty_cycle = 50;
    cmd.right_duty_cyle = 50;
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
    //tmr when timerafter(time + PWM_FRAME_TICKS) :> void;

}

void commandF(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[])
{

    printstr("commandF\n");
    message_t msg;


    int len = strlen(buffer);
    int duty_cycle = 0;
    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }

    sprintf (str, "OK: forward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(-duty_cycle, -duty_cycle, out_motor);


}

void commandf(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[])
{

    printstr("commandF\n");
    message_t msg;


    int len = strlen(buffer);
    int duty_cycle = 0;
    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }

    sprintf (str, "OK: forward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(-duty_cycle, -duty_cycle, out_motor);


}

void commandR(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[])
{

    message_t msg;

    int len = strlen(buffer);
    int duty_cycle = 0;
    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';


    }

    sprintf (str, "OK: Backward %d duty cycle", duty_cycle);

    strcpy(msg.data, str);
    trigger_chan <: msg;

    turn(duty_cycle, duty_cycle, out_motor);


}

void commandr(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[])
{

    message_t msg;

    int len = strlen(buffer);
    int duty_cycle = 0;
    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';


    }

    sprintf (str, "OK: Backward %d duty cycle", duty_cycle);

    strcpy(msg.data, str);
    trigger_chan <: msg;

    turn(duty_cycle, duty_cycle, out_motor);


}

void commandT(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[])
{

    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    int en_flag = 0; // encoder flag
    timer tmr;
    unsigned time;
    unsigned t0;
    unsigned t1;
    unsigned delay; // delay bw 2 wheel ticks

    int newCommand = 0;
    int duty_cycle = 0;
    int len = strlen(buffer);

    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }

    sprintf (str, "OK: forward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(-duty_cycle, -duty_cycle, out_motor);
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
            printf("en.left = %d en.right = %d\n en.wheel = %d", en.left, en.right, en.wheel);
            printf("delay = %d\n", delay);
            break;
        }

        //tmr :> time;

    }
    tmr :> time;
    while(newCommand == 0)
    {

        select
        {

            // listen to new command
        case iWiFiTX :> void:
            //printstr()
            printstr("new command\n");
            newCommand = 1;
            break;
        // check encoder
        case encoder_sig :> en:

            break;
            // Time out. Don't receive wheel rotation indication. Stop
        case tmr when timerafter(time + delay*(100 + duty_cycle)/100) :> void:
            stop(out_motor);
            break;

        }

    }

}
void commandS(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[])
{


    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    int en_flag = 0; // encoder flag
    timer tmr;
    unsigned time;
    unsigned t0;
    unsigned t1;
    unsigned delay; // delay bw 2 wheel ticks

    int newCommand = 0;
    int duty_cycle = 0;
    int len = strlen(buffer);

    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }

    sprintf (str, "OK: forward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(-duty_cycle, -duty_cycle, out_motor);
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
            printf("en.left = %d en.right = %d\n en.wheel = %d", en.left, en.right, en.wheel);
            printf("delay = %d\n", delay);
            break;
        }

        //tmr :> time;

    }
    tmr :> time;
    while(newCommand == 0)
    {

        select
        {

            // listen to new command
        case iWiFiTX :> void:
            //printstr()
            printstr("new command\n");
            newCommand = 1;
            break;
            // check encoder
        case encoder_sig :> en:

            break;
            // Time out. Don't receive wheel rotation indication. Stop
        case tmr when timerafter(time + delay*(100 + duty_cycle)/100) :> void:
                stop(out_motor);
                break;

        }

    }

}
void commandt(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[])
{


    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    int en_flag = 0; // encoder flag
    timer tmr;
    unsigned time;
    unsigned t0;
    unsigned t1;
    unsigned delay; // delay bw 2 wheel ticks

    int newCommand = 0;
    int duty_cycle = 0;
    int len = strlen(buffer);

    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }

    sprintf (str, "OK: backward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(duty_cycle, duty_cycle, out_motor);
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
            printf("en.left = %d en.right = %d\n en.wheel = %d", en.left, en.right, en.wheel);
            printf("delay = %d\n", delay);
            break;
        }

        //tmr :> time;

    }
    tmr :> time;
    while(newCommand == 0)
    {

        select
        {

            // listen to new command
        case iWiFiTX :> void:
            //printstr()
            printstr("new command\n");
            newCommand = 1;
            break;
            // check encoder
        case encoder_sig :> en:

            break;
            // Time out. Don't receive wheel rotation indication. Stop
        case tmr when timerafter(time + delay*(100 + duty_cycle)/100) :> void:
                stop(out_motor);
                break;

        }

    }

}
void commands(chanend trigger_chan, chanend out_motor, chanend encoder_sig,
        char str[], char buffer[])
{


    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    int en_flag = 0; // encoder flag
    timer tmr;
    unsigned time;
    unsigned t0;
    unsigned t1;
    unsigned delay; // delay bw 2 wheel ticks

    int newCommand = 0;
    int duty_cycle = 0;
    int len = strlen(buffer);

    for(int i = 1; i < len; i++)
    {
        duty_cycle = duty_cycle*10 + buffer[i] - '0';
    }

    sprintf (str, "OK: backward %d duty cycle", duty_cycle);
    strcpy(msg.data, str);
    trigger_chan <: msg;
    turn(duty_cycle, duty_cycle, out_motor);
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
            printf("en.left = %d en.right = %d\n en.wheel = %d", en.left, en.right, en.wheel);
            printf("delay = %d\n", delay);
            break;
        }

        //tmr :> time;

    }
    tmr :> time;
    while(newCommand == 0)
    {

        select
        {

            // listen to new command
        case iWiFiTX :> void:
            //printstr()
            printstr("new command\n");
            newCommand = 1;
            break;
            // check encoder
        case encoder_sig :> en:

            break;
            // Time out. Don't receive wheel rotation indication. Stop
        case tmr when timerafter(time + delay*(100 + duty_cycle)/100) :> void:
                stop(out_motor);
                break;

        }

    }

}

