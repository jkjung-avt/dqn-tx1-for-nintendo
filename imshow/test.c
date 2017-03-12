#include <stdlib.h>
#include <string.h>
#include "opencv/highgui.h"

int main(int argc, char **argv)
{
        // Create a named window with the name of the file.
        cvNamedWindow("test", CV_WINDOW_AUTOSIZE);

        // Load the image from the given file name.
        CvMat *img = cvLoadImageM("image0283.png", CV_LOAD_IMAGE_GRAYSCALE);

        // Show the image in the named window
        cvShowImage("test", img);
        cvReleaseMat(&img);

        // Idle until the user hits the "Esc" key.
        while (1) {
                if (cvWaitKey(100) == 27)  break;
        }

        // Clean up and don't be piggies
        cvDestroyAllWindows();
        exit(0);
}
