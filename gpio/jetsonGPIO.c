/*
 * jetsonGPIO.c
 *
 * This modeule handles GPIOs of Jetson TX1. The code is originally from
 * https://github.com/jetsonhacks/jetsonTX1GPIO, then modified and
 * maintained by JK Jung <jkjung13@gmail.com>. The original copyright
 * notice is retained below.
 */

/*
 * Copyright (c) 2015 JetsonHacks
 * www.jetsonhacks.com
 *
 * Based on Software by RidgeRun
 * Originally from:
 * https://developer.ridgerun.com/wiki/index.php/Gpio-int-test.c
 */
/*
 * Copyright (c) 2011, RidgeRun
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    This product includes software developed by the RidgeRun.
 * 4. Neither the name of the RidgeRun nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY RIDGERUN ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL RIDGERUN BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include "jetsonGPIO.h"

#define error_open(msg)  \
        do {  \
                char errorBuffer[128];  \
                snprintf(errorBuffer, sizeof(errorBuffer), msg, gpio);  \
                perror(errorBuffer);  \
                return fileDescriptor;  \
        } while (0)

#define error_other(msg)  \
        do {  \
                perror(msg);  \
                close(fileDescriptor);  \
                return -1;  \
        } while (0)

/*
 * gpioExport
 * Export the given gpio to userspace;
 * Return: Success = 0 ; otherwise open file error
 */
int gpioExport(jetsonGPIO gpio)
{
        int fileDescriptor, length;
        char commandBuffer[MAX_BUF];

        snprintf(commandBuffer, sizeof(commandBuffer), SYSFS_GPIO_DIR  "/gpio%d/direction", gpio);
        fileDescriptor = open(commandBuffer, O_WRONLY);
        if (fileDescriptor >= 0) {
                /* the "direction" file for this gpio already exists, so don't need to do export again */
                close(fileDescriptor);
                return 0;
        }

        fileDescriptor = open(SYSFS_GPIO_DIR "/export", O_WRONLY);
        if (fileDescriptor < 0)
                error_open("gpioExport unable to open gpio%d");

        length = snprintf(commandBuffer, sizeof(commandBuffer), "%d", gpio);
        if (write(fileDescriptor, commandBuffer, length) != length)
                error_other("gpioExport");

        close(fileDescriptor);
        return 0;
}

/*
 * gpioUnexport
 * Unexport the given gpio from userspace
 * Return: Success = 0 ; otherwise open file error
 */
int gpioUnexport(jetsonGPIO gpio)
{
        int fileDescriptor, length;
        char commandBuffer[MAX_BUF];

        fileDescriptor = open(SYSFS_GPIO_DIR "/unexport", O_WRONLY);
        if (fileDescriptor < 0)
                error_open("gpioUnexport unable to open gpio%d");

        length = snprintf(commandBuffer, sizeof(commandBuffer), "%d", gpio);
        if (write(fileDescriptor, commandBuffer, length) != length)
                error_other("gpioUnexport");

        close(fileDescriptor);
        return 0;
}

/*
 * gpioSetDirection
 * Set the direction of the GPIO pin 
 * Return: Success = 0 ; otherwise open file error
 */
int gpioSetDirection(jetsonGPIO gpio, unsigned int out_flag)
{
        int fileDescriptor;
        char commandBuffer[MAX_BUF];

        snprintf(commandBuffer, sizeof(commandBuffer), SYSFS_GPIO_DIR  "/gpio%d/direction", gpio);
        fileDescriptor = open(commandBuffer, O_WRONLY);
        if (fileDescriptor < 0)
                error_open("gpioSetDirection unable to open gpio%d");

        if (out_flag) {
                if (write(fileDescriptor, "out", 4) != 4)
                        error_other("gpioSetDirection");
        }
        else {
                if (write(fileDescriptor, "in", 3) != 3)
                        error_other("gpioSetDirection");
        }

        close(fileDescriptor);
        return 0;
}

/*
 * gpioSetValue
 * Set the value of the GPIO pin to 1 or 0
 * Return: Success = 0 ; otherwise open file error
 */
int gpioSetValue(jetsonGPIO gpio, unsigned int value)
{
        int fileDescriptor;
        char commandBuffer[MAX_BUF];

        snprintf(commandBuffer, sizeof(commandBuffer), SYSFS_GPIO_DIR "/gpio%d/value", gpio);
        fileDescriptor = open(commandBuffer, O_WRONLY);
        if (fileDescriptor < 0)
                error_open("gpioSetValue unable to open gpio%d");

        if (value) {
                if (write(fileDescriptor, "1", 2) != 2)
                        error_other("gpioSetValue");
        }
        else {
                if (write(fileDescriptor, "0", 2) != 2)
                        error_other("gpioSetValue");
        }

        close(fileDescriptor);
        return 0;
}

/*
 * gpioGetValue
 * Get the value of the requested GPIO pin ; value return is 0 or 1
 * Return: Success = 0 ; otherwise open file error
 */
int gpioGetValue(jetsonGPIO gpio, unsigned int *value)
{
        int fileDescriptor;
        char commandBuffer[MAX_BUF];
        char ch;

        snprintf(commandBuffer, sizeof(commandBuffer), SYSFS_GPIO_DIR "/gpio%d/value", gpio);
        fileDescriptor = open(commandBuffer, O_RDONLY);
        if (fileDescriptor < 0)
                error_open("gpioGetValue unable to open gpio%d");

        if (read(fileDescriptor, &ch, 1) != 1)
                error_other("gpioGetValue");

        *value = (ch != '0') ? 1 : 0;

        close(fileDescriptor);
        return 0;
}

/*
 * gpioSetEdge
 * Set the edge of the GPIO pin
 * Valid edges: 'none' 'rising' 'falling' 'both'
 * Return: Success = 0 ; otherwise open file error
 */
int gpioSetEdge(jetsonGPIO gpio, char *edge)
{
        int fileDescriptor;
        char commandBuffer[MAX_BUF];

        snprintf(commandBuffer, sizeof(commandBuffer), SYSFS_GPIO_DIR "/gpio%d/edge", gpio);
        fileDescriptor = open(commandBuffer, O_WRONLY);
        if (fileDescriptor < 0)
                error_open("gpioSetEdge unable to open gpio%d");

        if (write(fileDescriptor, edge, strlen(edge) + 1) != ((int) (strlen(edge) + 1)))
                error_other("gpioSetEdge");

        close(fileDescriptor);
        return 0;
}

/*
 * gpioActiveLow
 * Set the active_low attribute of the GPIO pin to 1 or 0
 * Return: Success = 0 ; otherwise open file error
 */
int gpioActiveLow(jetsonGPIO gpio, unsigned int value)
{
        int fileDescriptor;
        char commandBuffer[MAX_BUF];

        snprintf(commandBuffer, sizeof(commandBuffer), SYSFS_GPIO_DIR "/gpio%d/active_low", gpio);
        fileDescriptor = open(commandBuffer, O_WRONLY);
        if (fileDescriptor < 0)
                error_open("gpioActiveLow unable to open gpio%d");

        if (value) {
                if (write(fileDescriptor, "1", 2) != 2)
                        error_other("gpioActiveLow");
        }
        else {
                if (write(fileDescriptor, "0", 2) != 2)
                        error_other("gpioActiveLow");
        }

        close(fileDescriptor);
        return 0;
}
