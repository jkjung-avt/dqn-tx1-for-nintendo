/*
 * jetsonGPIO.c
 *
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

/*
 * gpioExport
 * Export the given gpio to userspace;
 * Return: Success = 0 ; otherwise open file error
 */
int gpioExport(jetsonGPIO gpio)
{
        int fileDescriptor, length;
        char commandBuffer[MAX_BUF];

        fileDescriptor = open(SYSFS_GPIO_DIR "/export", O_WRONLY);
        if (fileDescriptor < 0) {
                char errorBuffer[128] ;
                snprintf(errorBuffer, sizeof(errorBuffer), "gpioExport unable to open gpio%d", gpio);
                perror(errorBuffer);
                return fileDescriptor;
        }

        length = snprintf(commandBuffer, sizeof(commandBuffer), "%d", gpio);
        if (write(fileDescriptor, commandBuffer, length) != length) {
                perror("gpioExport");
                close(fileDescriptor);
                return -1;
        }

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
        if (fileDescriptor < 0) {
                char errorBuffer[128];
                snprintf(errorBuffer,sizeof(errorBuffer), "gpioUnexport unable to open gpio%d", gpio);
                perror(errorBuffer);
                return fileDescriptor;
        }

        length = snprintf(commandBuffer, sizeof(commandBuffer), "%d", gpio);
        if (write(fileDescriptor, commandBuffer, length) != length) {
                perror("gpioUnexport");
                close(fileDescriptor);
                return -1;
        }

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
        if (fileDescriptor < 0) {
                char errorBuffer[128] ;
                snprintf(errorBuffer, sizeof(errorBuffer), "gpioSetDirection unable to open gpio%d", gpio);
                perror(errorBuffer);
                return fileDescriptor;
        }

        if (out_flag) {
                if (write(fileDescriptor, "out", 4) != 4) {
                        perror("gpioSetDirection");
                        close(fileDescriptor);
                        return -1;
                }
        }
        else {
                if (write(fileDescriptor, "in", 3) != 3) {
                        perror("gpioSetDirection");
                        close(fileDescriptor);
                        return -1;
                }
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
        if (fileDescriptor < 0) {
                char errorBuffer[128];
                snprintf(errorBuffer, sizeof(errorBuffer), "gpioSetValue unable to open gpio%d", gpio);
                perror(errorBuffer);
                return fileDescriptor;
        }

        if (value) {
                if (write(fileDescriptor, "1", 2) != 2) {
                        perror("gpioSetValue");
                        close(fileDescriptor);
                        return -1;
                }
        }
        else {
                if (write(fileDescriptor, "0", 2) != 2) {
                        perror("gpioSetValue");
                        close(fileDescriptor);
                        return -1;
                }
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
        if (fileDescriptor < 0) {
                char errorBuffer[128];
                snprintf(errorBuffer, sizeof(errorBuffer), "gpioGetValue unable to open gpio%d", gpio);
                perror(errorBuffer);
                return fileDescriptor;
        }

        if (read(fileDescriptor, &ch, 1) != 1) {
                perror("gpioGetValue");
                close(fileDescriptor);
                return -1;
        }

        if (ch != '0') {
                *value = 1;
        } else {
                *value = 0;
        }

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
        if (fileDescriptor < 0) {
                char errorBuffer[128] ;
                snprintf(errorBuffer,sizeof(errorBuffer), "gpioSetEdge unable to open gpio%d",gpio);
                perror(errorBuffer);
                return fileDescriptor;
        }

        if (write(fileDescriptor, edge, strlen(edge) + 1) != ((int) (strlen(edge) + 1))) {
                perror("gpioSetEdge");
                close(fileDescriptor);
                return -1;
        }

        close(fileDescriptor);
        return 0;
}

/*
 * gpioOpen
 * Open the given pin for reading
 * Returns the file descriptor of the named pin
 */
int gpioOpen(jetsonGPIO gpio)
{
        int fileDescriptor;
        char commandBuffer[MAX_BUF];

        snprintf(commandBuffer, sizeof(commandBuffer), SYSFS_GPIO_DIR "/gpio%d/value", gpio);

        fileDescriptor = open(commandBuffer, O_RDONLY | O_NONBLOCK);
        if (fileDescriptor < 0) {
                char errorBuffer[128] ;
                snprintf(errorBuffer,sizeof(errorBuffer), "gpioOpen unable to open gpio%d",gpio);
                perror(errorBuffer);
        }
        return fileDescriptor;
}

/*
 * gpioClose
 * Close the given file descriptor
 */
int gpioClose(int fileDescriptor)
{
        return close(fileDescriptor);
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
        if (fileDescriptor < 0) {
                char errorBuffer[128];
                snprintf(errorBuffer, sizeof(errorBuffer), "gpioActiveLow unable to open gpio%d", gpio);
                perror(errorBuffer);
                return fileDescriptor;
        }

        if (value) {
                if (write(fileDescriptor, "1", 2) != 2) {
                        perror("gpioActiveLow");
                        close(fileDescriptor);
                        return -1;
                }
        }
        else {
                if (write(fileDescriptor, "0", 2) != 2) {
                        perror("gpioActiveLow");
                        close(fileDescriptor);
                        return -1;
                }
        }

        close(fileDescriptor);
        return 0;
}

