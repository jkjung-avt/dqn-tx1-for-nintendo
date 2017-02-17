/*
 *  gpio.c
 *
 *  DESCRIPTION:
 *
 *  This code implements TX1 GPIO API for Lua by FFI. It uses jetsonGPIO
 *  code from JetsonHacks.com.
 *
 *  PROCESS:
 *
 *  GLOBALS:
 *
 *  REFERENCE:
 *
 *  LIMITATIONS:
 *
 *  REVISION HISTORY:
 *
 *    Date             Description                             Author
 *    2017-02-16       initial coding                          jkjung
 *
 *  TARGET: Linux C
 *
 */
 
#include <unistd.h>
#include <stdlib.h>
#include "jetsonGPIO.h"

#if 0
void gpio_export(int pin);
void gpio_unexport(int pin);
void gpio_set_output(int pin);
void gpio_set_high(int pin);
void gpio_set_low(int pin);
#endif /* 0 */ 

void gpio_export(int pin)
{
        gpioExport(pin);
}

void gpio_unexport(int pin)
{
        gpioUnexport(pin);
}

void gpio_set_output(int pin)
{
        gpioSetDirection(pin, outputPin);
}

void gpio_set_high(int pin)
{
        gpioSetValue(pin, high);
}

void gpio_set_low(int pin)
{
        gpioSetValue(pin, low);
}
