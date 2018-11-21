/*
 * Lab06-SetupNodeMCU.xc
 *
 *  Created on: Oct 18, 2018
 *      Author: quyetnguyen
 */


#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include <string.h>

#define BAUDRATE 9600 // 9600
#define BIT_TIME XS1_TIMER_HZ/BAUDRATE // ticks per bit
in port iUartRx = XS1_PORT_1B;
out port oUartTx = XS1_PORT_1A;
out port oLED = XS1_PORT_1D;

out port oWiFiRX = XS1_PORT_1F ;
in port iWiFiTX = XS1_PORT_1H;

// constants
#define TICKS_PER_SEC (XS1_TIMER_HZ)
#define LEN 10;
#define LENTHBUFFER 150
void uart_transmit_byte(out port oPort, char value, unsigned int baudrate);
char uart_receive_byte(in port iPort, unsigned int baudrate);

void uart_transmit_bytes(out port oPort, const char values[], unsigned int baudrate);
void uart_receive_bytes(in port iPort, char values[], unsigned int n, unsigned int baudrate);
void toggle_port(out port oLED, unsigned int hz);
//void toggle_port(out port oLED);
void uarttoconsoletask();
void uart_to_console_task(chanend trigger_chan);
void line(const char buffer[]);
void send_blink_program();
void init_wifi_task(chanend trigger_chan);
void remove_blink_program();
void write_blink_program();
void read_blink_program();
void run_blink_program();

void read_wifi_program();
void run_wifi_program();
void write_wifi_program();
void remove_wifi_program();
void check();
void showfiles();
void renamefile();
int main()
{



   const char message[] = "";
   chan trigger_chan;
   oWiFiRX <: 1;

   par
   {
       //uart_transmit_bytes(oWiFiRX, message, BAUDRATE);
       toggle_port(oLED, 2);
       //toggle_port(oLED);
       //uarttoconsoletask();

       uart_to_console_task(trigger_chan);

       init_wifi_task(trigger_chan);
   }

   return 0;
}


void run_blink_program()
{
    line("dofile('blink.lua')");

}
void read_blink_program()
{


    line("if file.open(\"blink.lua\", \"r\") then");

    line("while 1 do");
    line("line = file.readline()");

    line("if line == nill then break end");
    line("tmr.delay(1000000)");
    line("print(line)");
    line("end");

    line("file.close()");
    line("end");
}

void remove_blink_program()
{
    // remove blink.lua if it exists
    line("if file.exists(\"blink.lua\") then");
    line("file.remove(\"blink.lua\")");
    line("end");

}

void remove_wifi_program()
{
    // remove wifi.lua if it exists
    line("if file.exists(\"wif.lua\") then");
    line("file.remove(\"wifi.lua\")");
    line("end");

}
void write_blink_program()
{



    // start to write a new one
    line("if file.open(\"blink.lua\", \"w\") then");

    line("file.writeline('gpio.mode(3, gpio.OUTPUT)')");
    line("file.writeline('while 1 do')");
    line("file.writeline('gpio.write(3, gpio.HIGH)')");
    line("file.writeline('tmr.delay(1000000)')");
    line("file.writeline('gpio.write(3, gpio.LOW)')");
    line("file.writeline('tmr.delay(1000000)')");
    line("file.flush()");
    line("file.writeline('end')");

    line("file.close()");
    line("end");


}

void write_wifi_program()
{
    line("if file.open(\"wif.lua\", \"w\") then");

    line("file.writeline('wifi.setmode(wifi.SOFTAP)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('cfg={}')");
    //line("tmr.delay(1000000)");
    line("file.writeline('cfg.ssid=\"MiniUGVQQNN\"')");
    //line("tmr.delay(1000000)");
    line("file.writeline('cfg.pwd=\"MiniUGVQQQQ\"')");
    //line("tmr.delay(1000000)");
    //line("file.writeline('cfg.ip=\"192.168.0.1\"')");
    line("file.writeline('cfg.ip=\"192.168.1.1\"')");
    //line("tmr.delay(1000000)");
    line("file.writeline('cfg.netmask=\"255.255.255.0\"')");
    //line("tmr.delay(1000000)");
    //line("file.writeline('cfg.gateway=\"192.168.0.1\"')");
    line("file.writeline('cfg.gateway=\"192.168.1.1\"')");
    //line("tmr.delay(1000000)");
    //line("file.writeline('port = 9876')");
    line("file.writeline('port = 7501')");
    //line("tmr.delay(1000000)");
    line("file.writeline('wifi.ap.setip(cfg)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('wifi.ap.config(cfg)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('print(\"SSID: \" .. cfg.ssid .. \"  PASS: \" .. cfg.pwd)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('print(\"RoboRemo app must connect to \" .. cfg.ip .. \":\" .. port)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('tmr.alarm(0,200,0,function() -- run after a delay')");
    //line("tmr.delay(1000000)");
    line("file.writeline('srv=net.createServer(net.TCP, 28800)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('srv:listen(port,function(conn)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('uart.on(\"data\", 0, function(data)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('conn:send(data)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('end, 0)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('conn:on(\"receive\",function(conn,payload)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('uart.write(0, payload)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('end)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('conn:on(\"disconnection\",function(c)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('uart.on(\"data\")')");
    //line("tmr.delay(1000000)");
    line("file.writeline('end)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('end)')");
    //line("tmr.delay(1000000)");
    line("file.writeline('end)')");
    //line("tmr.delay(1000000)");
    line("file.flush()");
    line("file.close()");
    //line("print(\"cannot open wifi.lua\")");
    line("end");
}

void run_wifi_program()
{
    line("dofile(\"wif.lua\")");

}
void read_wifi_program()
{

    line("if file.open(\"wif.lua\", \"r\") then");

    line("while 1 do");
    line("line = file.readline()");

    line("if line == nill then break end");
    line("tmr.delay(1000000)");
    line("print(line)");
    line("end");

    line("file.close()");
    line("end");

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

void init_wifi_task(chanend trigger_chan)
{
    timer t;
    unsigned time;

    while(1)
    {
        trigger_chan :> int tmp;
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



    }
}
void send_blink_program()
{
    line("gpio.mode(3, gpio.OUTPUT)");
    line("while 1 do");
    line("gpio.write(3, gpio.HIGH)");
    line("tmr.delay(1000000)");
    line("gpio.write(3, gpio.LOW)");
    line("tmr.delay(1000000)");
    line("end");
}
void uart_to_console_task(chanend trigger_chan)
{
    const char * ptr = "lua: cannot open init.lua";
    char buffer[LENTHBUFFER];

    int i = 0;
    while(1)
    {

        char chr;
        chr = uart_receive_byte(iWiFiTX, BAUDRATE);
        //if(chr == '\n' || chr == '\r' || chr == '\0' || i == LENTHBUFFER - 1)
        if(chr == '\n' || chr == '\r' || i == LENTHBUFFER - 1)
        {
            buffer[i] = '\0';
            printstrln(buffer);
            i = 0;
            if(strcmp(ptr, buffer) == 0)
            {
                trigger_chan <: 0;
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

void showfiles()
{
    //line("l = file.list(*.lua)");
    line("for k,v in pairs(file.list()) do");
    //line("for k,v in pairs(l) do");
    line("tmr.delay(1000000)");
    //line("print(\"name:\" k \", size:\" v)");
    line("print(\"name: \" ..k..)");
    line("tmr.delay(1000000)");
    line("print(\"size: \" ..v)");
    //line("tmr.delay(1000000)");
    line("end");
}

void check()
{
    line("while 1 do");
    line("if file.open(\"wifi.lua\") == nil then");
    line("tmr.delay(1000000)");
    line("print(\"init.lua deleted or renamed\")");

    line("else");
    line("tmr.delay(1000000)");
    line("print(\"wifi.lua exists\")");
    line("end");
    line("end");
    /*
    line("while 1 do");
    line("print(\"Running\")");
    line("tmr.delay(1000000)");
    line("end");
    */
}
void renamefile()
{
    //line("if file.open(\"a.lua\", \"r\") then");

    line("if file.exists(\"a.lua\") then");
    line("print(\"a.lua exists\")");
    line("tmr.delay(1000000)");
    line("r = file.rename(\"a.lua\",\"w.lua\")");
    line("if r == true then");
    line("tmr.delay(1000000)");
    line("print(\"success\")");
    line("else");
    line("tmr.delay(1000000)");
    line("print(\"fail\")");
    line("end");

    line("else");
    line("print(\"a.lua does not exist\")");
    line("tmr.delay(1000000)");
    line("end");
    //line("file.close()");
    //line("end");
}
