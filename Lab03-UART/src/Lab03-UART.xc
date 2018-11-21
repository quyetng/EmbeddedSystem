/*
 * Lab03-UART.xc
 *
 *  Created on: Sep 27, 2018
 *      Author: quyetnguyen
 */

#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include <string.h>

#define BAUDRATE 115200 // 9600
#define BIT_TIME XS1_TIMER_HZ/BAUDRATE // ticks per bit
in port iUartRx = XS1_PORT_1B;
out port oUartTx = XS1_PORT_1A;

void uart_transmit_byte(out port oPort, char value, unsigned int baudrate);
char uart_receive_byte(in port iPort, unsigned int baudrate);
int main_single();
void uart_transmit_bytes(out port oPort, const char values[], unsigned int n, unsigned int baudrate);
void uart_receive_bytes(in port iPort, char values[], unsigned int n, unsigned int baudrate);
int main_array();
int main()
{

    //return main_single();
    return main_array();

}

int main_single()
{

    char value;
    oUartTx <: 1; // idle line is high

    par
    {
        uart_transmit_byte(oUartTx, 'H', BAUDRATE);
        value = uart_receive_byte(iUartRx, BAUDRATE);
    }
    printcharln(value);
    return 0;
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

void uart_transmit_bytes(out port oPort, const char values[], unsigned int n, unsigned int baudrate)
{

    for(int i = 0; i < n; i++)
    {
        printf("< %c\n", values[i]);
        uart_transmit_byte(oPort, values[i], baudrate);
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
        printf("> %c\n",values[i]);

    }

}

int main_array()
{
    const char message[] = "Hello, Cleveland";
    char buffer[64];
    oUartTx <: 1; // idle line is high
    par
    {

        uart_transmit_bytes(oUartTx, message, strlen(message) + 1, BAUDRATE);
        uart_receive_bytes(iUartRx, buffer, strlen(message) + 1, BAUDRATE);
    }
    printstrln(buffer);
    return 0;
}
