/*
 * app_MPU6050_DMP6.xc
 *
 *  Created on: Jan 25, 2014
 *      Author: CJ
 */
/*
 * MPU-6050 6-axis DMP demo app
 * Adapted from jrowberg/i2cdevlib MPU6050_DMP6
 * and ahenshaw's Two-wheeled balancer MPU6050 angle sensor handler
 */
#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "mpu6050.h"
#include "i2c.h"

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

in  port butP = XS1_PORT_32A;                           //Button is bit 0, used to stop gracefully

void show_imu(chanend dmp_out){
    ypr_t ypr_cmd;
    //float q[4],g[3],euler[3],ypr[3];
    while (1){
        select {
            case dmp_out :> ypr_cmd:
            /*case dmp_out :> q[0]:
                 dmp_out :> q[1];
                 dmp_out :> q[2];
                 dmp_out :> q[3];
                 dmp_out :> g[0];
                 dmp_out :> g[1];
                 dmp_out :> g[2];
                 dmp_out :> euler[0];
                 dmp_out :> euler[1];
                 dmp_out :> euler[2];
                 dmp_out :> ypr[0];
                 dmp_out :> ypr[1];
                 dmp_out :> ypr[2];
            */

                 //printf("quat(%0.2f,%0.2f,%0.2f,%0.2f) ",q[0],q[1],q[2],q[3]);
                 //printf("grav(%0.2f,%0.2f,%0.2f) ",g[0],g[1],g[2]);
                 //printf("ypr(%0.2f,%0.2f,%0.2f) ",ypr[0],ypr[1],ypr[2]);
                 //printf("euler(%0.2f,%0.2f,%0.2f)\n",euler[0],euler[1],euler[2]);
                 printf("ypr(%0.2f,%0.2f,%0.2f)\n ",ypr_cmd.y,ypr_cmd.p,ypr_cmd.r);
                 break;
        }
    }
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
                /*
                dmp_out <: q[0];
                dmp_out <: q[1];
                dmp_out <: q[2];
                dmp_out <: q[3];
                */
                mpu_getGravity(q,g);
                /*
                dmp_out <: g[0];
                dmp_out <: g[1];
                dmp_out <: g[2];
                */
                mpu_getEuler(euler,q);
                /*
                dmp_out <: euler[0];
                dmp_out <: euler[1];
                dmp_out <: euler[2];
                */

                mpu_getYawPitchRoll(q,g,ypr);
                /*
                dmp_out <: ypr[0];
                dmp_out <: ypr[1];
                dmp_out <: ypr[2];
                */
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
void dmp_6axis(chanend dmp_out){                        //does all MPU6050 actions
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
                dmp_out <: q[0];
                dmp_out <: q[1];
                dmp_out <: q[2];
                dmp_out <: q[3];

                mpu_getGravity(q,g);
                dmp_out <: g[0];
                dmp_out <: g[1];
                dmp_out <: g[2];

                mpu_getEuler(euler,q);
                dmp_out <: euler[0];
                dmp_out <: euler[1];
                dmp_out <: euler[2];

                mpu_getYawPitchRoll(q,g,ypr);
                dmp_out <: ypr[0];
                dmp_out <: ypr[1];
                dmp_out <: ypr[2];

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

void show_dmp(chanend dmp_out){
    float q[4],g[3],euler[3],ypr[3];
    while (1){
        select {
            case dmp_out :> q[0]:
                 dmp_out :> q[1];
                 dmp_out :> q[2];
                 dmp_out :> q[3];
                 dmp_out :> g[0];
                 dmp_out :> g[1];
                 dmp_out :> g[2];
                 dmp_out :> euler[0];
                 dmp_out :> euler[1];
                 dmp_out :> euler[2];
                 dmp_out :> ypr[0];
                 dmp_out :> ypr[1];
                 dmp_out :> ypr[2];

                 printf("quat(%0.2f,%0.2f,%0.2f,%0.2f) ",q[0],q[1],q[2],q[3]);
                 printf("grav(%0.2f,%0.2f,%0.2f) ",g[0],g[1],g[2]);
                 printf("ypr(%0.2f,%0.2f,%0.2f) ",ypr[0],ypr[1],ypr[2]);
                 printf("euler(%0.2f,%0.2f,%0.2f)\n",euler[0],euler[1],euler[2]);
                 break;
        }
    }
}

int main() {
    chan dmp_out;

    par {
        //on tile[0]:dmp_6axis(dmp_out);
        //on tile[0]:show_dmp(dmp_out);

        on tile[0]:imu_task(dmp_out);
        on tile[0]:show_imu(dmp_out);

        /*
        imu_task(dmp_out);
        show_imu(dmp_out);
        */

    }
    return 0;
}
