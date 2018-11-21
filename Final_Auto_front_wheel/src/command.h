#include <xs1.h>
#include <stdio.h>
#include <string.h>
#include <print.h>

#define MESSAGE_SIZE 128

typedef struct
{
    int left_duty_cycle;
    int right_duty_cycle;
    // left or right

} motor_cmd_t;

// message struct
typedef struct
{
    char data[MESSAGE_SIZE];

} message_t;

typedef struct
{
    float y;
    float p;
    float r;

}ypr_t;

typedef struct
{
    int left;
    int right;
    int wheel;
} encoder_t;


void stop(chanend out_motor);
void turn(int left_duty, int right_duty, chanend out_motor);
void driveforwardfullspeed(chanend out_motor);
void driveforwardhaftspeed(chanend out_motor);
void drivebackwardfullspeed(chanend out_motor);
void drivebackwardhaftspeed(chanend out_motor);
void turnRight90degree(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out);
void turnLeft90degree(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out);
