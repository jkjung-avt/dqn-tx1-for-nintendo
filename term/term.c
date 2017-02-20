/*
 *  term.c
 *
 *  DESCRIPTION:
 *
 *  This code implements a wait_key() method for Lua by FFI. It uses terminal
 *  I/O calls which should work on all Linux platforms.
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
 *    2017-02-17       initial coding                          jkjung
 *
 *  TARGET: Linux C
 *
 */
 
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>

#if 0
void term_init();
void term_cleanup();
int  term_waitkey(int timeout);
#endif  /* 0 */

static void stdin_set(int cmd)
{
        struct termios t;

        tcgetattr(STDIN_FILENO, &t);
        switch (cmd) {
        case 1:
                t.c_lflag &= ~(ICANON | ECHO);
                break;
        default:
                t.c_lflag |= (ICANON | ECHO);
                break;
        }
        tcsetattr(STDIN_FILENO, TCSANOW, &t);
}

static void bye()
{
        /* reset terminal back to canonical mode */
        stdin_set(0);
}

void term_init()
{
        atexit(bye);

        /*
         * set terminal to canonical mode so that getchar() would return
         * immediately without waiting for '\n' or EOF.
         */
        stdin_set(1);
}

void term_cleanup()
{
        bye();
}

int  term_waitkey(int timeout)  /* timeout in msecs */
{
        int c;

        /* TO-DO: implement timeout with select() */
        c = getchar();
        return c;
}
