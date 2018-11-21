#include <command.h>

//in port iWiFiTX = XS1_PORT_1H;
//out port oWiFiRX = XS1_PORT_1F;

void driveforwardfullspeed(chanend out_motor)
{

    motor_cmd_t cmd;
    cmd.left_duty_cycle = 100;
    cmd.right_duty_cycle = 100;
    out_motor <: cmd;
}

void driveforwardhaftspeed(chanend out_motor)
{


    motor_cmd_t cmd;
    cmd.left_duty_cycle = 50;
    cmd.right_duty_cycle = 50;
    out_motor <: cmd;
}

void drivebackwardfullspeed(chanend out_motor)
{

    motor_cmd_t cmd;
    cmd.left_duty_cycle = -100;
    cmd.right_duty_cycle = -100;
    out_motor <: cmd;
}

void drivebackwardhaftspeed(chanend out_motor)
{

    motor_cmd_t cmd;
    cmd.left_duty_cycle = -50;
    cmd.right_duty_cycle = -50;
    out_motor <: cmd;
}

void stop(chanend out_motor)
{

    motor_cmd_t cmd;
    cmd.left_duty_cycle = 0;
    cmd.right_duty_cycle = 0;
    out_motor <: cmd;


}

void turnRight90degree(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out)
{
    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;
    float currentYaw;
    float stopYaw;


    //newCommand = 0;
    // get current yaw
    select
    {
    case  dmp_out :> yprMsg:
        break;
    }
    currentYaw = yprMsg.y;

    stopYaw = currentYaw + 3.14/2;
    //printf("stopYaw = %f\n", stopYaw);
    if(stopYaw > 3.14)
    {
        stopYaw = stopYaw - 6.28;
    }
    //printf("after adjust stopYaw = %f\n", stopYaw);
    //printf("currentYaw = %f\n", currentYaw);
    strcpy(msg.data, "OK: Turn right 90 degree");
    trigger_chan <: msg;
    turn(-50, 50, out_motor); // turn right
    while(1)
    {
        // check new yaw
        dmp_out :> yprMsg;

        if(stopYaw < 0)
        {
            if(yprMsg.y < 0)
            {
                if(yprMsg.y == stopYaw || yprMsg.y > stopYaw)
                {
                    stop(out_motor);
                    break;
                }
            }

        }
        else
        {
            if(yprMsg.y == stopYaw || yprMsg.y > stopYaw)
            {
                stop(out_motor);
                break;
            }
        }

    }
}
void turnLeft90degree(chanend trigger_chan, chanend out_motor, chanend encoder_sig, chanend dmp_out)
{
    message_t msg;
    encoder_t en;
    en.left = 0;
    en.right = 0;

    ypr_t yprMsg;
    yprMsg.y = 0;
    float currentYaw;
    float stopYaw;
    //newCommand = 0;
    // get current yaw
    select
    {
    case  dmp_out :> yprMsg:
        break;
    }
    currentYaw = yprMsg.y;
    //printf("currentYaw = %f\n", currentYaw);
    strcpy(msg.data, "OK: Turn left 90 degree");
    trigger_chan <: msg;

    stopYaw = currentYaw - 3.14/2;
    //printf("stopYaw = %f\n", stopYaw);
    if(stopYaw < -3.14)
    {
        stopYaw = stopYaw + 6.28;
    }
    //printf("after adjust stopYaw = %f\n", stopYaw);
    turn(50, -50, out_motor);
    while(1)
    {
        // check new yaw
        dmp_out :> yprMsg;

        if(stopYaw > 0)
        {
            if(yprMsg.y > 0)
            {
                if(yprMsg.y == stopYaw || yprMsg.y < stopYaw)
                {
                    stop(out_motor);
                    break;
                }
            }

        }
        else
        {
            if(yprMsg.y == stopYaw || yprMsg.y < stopYaw)
            {
                stop(out_motor);
                break;
            }
        }

    }
}
void turn(int left_duty, int right_duty, chanend out_motor)
{
    //printstr("turn\n");
    motor_cmd_t cmd;
    cmd.left_duty_cycle  = left_duty;
    cmd.right_duty_cycle = right_duty;
    out_motor <: cmd;

}

