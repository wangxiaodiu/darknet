/*************************************************************************
 * arapaho                                                               *
 *                                                                       *
 * C++ API for Yolo v2                                                   *
 *                                                                       *
 * This test wrapper reads an image or video file and displays           *
 * detected regions in it.                                               *
 *                                                                       *
 * https://github.com/prabindh/darknet                                   *
 *                                                                       *
 * Forked from, https://github.com/pjreddie/darknet                      *
 *                                                                       *
 * Refer below file for build instructions                               *
 *                                                                       *
 * arapaho_readme.txt                                                    *
 *                                                                       *
 *************************************************************************/

#include "arapaho.hpp"
#include "opencv2/core/core.hpp"
#include <opencv2/imgproc.hpp>
#include "opencv2/highgui/highgui.hpp"
#include <sys/types.h>
#include <sys/stat.h>
#include <chrono>

using namespace cv;

//
// Some configuration inputs
//
static char INPUT_DATA_FILE[]    = "input.data"; 
static char INPUT_CFG_FILE[]     = "input.cfg";
static char INPUT_WEIGHTS_FILE[] = "input.weights";
static char INPUT_AV_FILE[]      = "input.mp4"; //"input.jpg"; // Can take in either Video or Image file
#define MAX_OBJECTS_PER_FRAME (100)

#define TARGET_SHOW_FPS (10)

//
// Some utility functions
// 
bool fileExists(const char *file) 
{
    struct stat st;
    if(!file) return false;
    int result = stat(file, &st);
    return (0 == result);
}

//
// Main test wrapper for arapaho
//
int main()
{
    bool ret = false;
    int expectedW = 0, expectedH = 0;
    box* boxes = 0;
    
    // Early exits
    if(!fileExists(INPUT_DATA_FILE) || !fileExists(INPUT_CFG_FILE) || !fileExists(INPUT_WEIGHTS_FILE))
    {
        EPRINTF("Setup failed as input files do not exist or not readable!\n");
        return -1;       
    }
    
    // Create arapaho
    ArapahoV2* p = new ArapahoV2();
    if(!p)
    {
        return -1;
    }
    
    // TODO - read from arapaho.cfg    
    ArapahoV2Params ap;
    ap.datacfg = INPUT_DATA_FILE;
    ap.cfgfile = INPUT_CFG_FILE;
    ap.weightfile = INPUT_WEIGHTS_FILE;
    ap.nms = 0.4;
    ap.maxClasses = 2;
    
    // Always setup before detect
    ret = p->Setup(ap, expectedW, expectedH);
    if(false == ret)
    {
        EPRINTF("Setup failed!\n");
        if(p) delete p;
        p = 0;
        return -1;
    }
    
    // Steps below this, can be performed in a loop
    
    // loop 
    // {
    //    setup arapahoImage;
    //    p->Detect(arapahoImage);
    //    p->GetBoxes;
    // }
    //
    
    // Setup image buffer here
    ArapahoV2ImageBuff arapahoImage;
    Mat image;

    // Setup show window
    namedWindow ( "Arapaho" , CV_WINDOW_AUTOSIZE );
    
    // open a video or image file
    VideoCapture cap ( INPUT_AV_FILE );
    if( ! cap.isOpened () )  
    {
        EPRINTF("Could not load the AV file %s\n", INPUT_AV_FILE);
        if(p) delete p;
        p = 0;
        return -1;
    }
    // Detection loop
    while(1)
    {
        bool success = cap.read(image); 
        if(!success)
        {
            EPRINTF("cap.read failed/EoF - AV file %s\n", INPUT_AV_FILE);
            if(p) delete p;
            p = 0;
            return -1;
        }    
        if( image.empty() ) 
        {
            EPRINTF("image.empty error - AV file %s\n", INPUT_AV_FILE);
            if(p) delete p;
            p = 0;
            return -1;
        }
        else
        {
            DPRINTF("Image data = %p, w = %d, h = %d\n", image.data, image.size().width, image.size().height);
            
            // Remember the time
            auto detectionStartTime = std::chrono::system_clock::now();

            // Process the image
            arapahoImage.bgr = image.data;
            arapahoImage.w = image.size().width;
            arapahoImage.h = image.size().height;
            arapahoImage.channels = 3;
            // Using expectedW/H, can optimise scaling using HW in platforms where available
            
            int numObjects = 0;
            
            // Detect the objects in the image
            p->Detect(
                arapahoImage,
                0.24,
                0.5,
                numObjects);
            std::chrono::duration<double> detectionTime = (std::chrono::system_clock::now() - detectionStartTime);
            
            printf("==> Detected [%d] objects in [%f] seconds\n", numObjects, detectionTime.count());
            
            if(numObjects > 0 && numObjects < MAX_OBJECTS_PER_FRAME) // Realistic maximum
            {    
                boxes = new box[numObjects];
                if(!boxes)
                {
                    if(p) delete p;
                    p = 0;
                    return -1;
                }
                p->GetBoxes(
                    boxes,
                    numObjects);
                DPRINTF("Box #%d: center {x,y}, box {w,h} = [%f, %f, %f, %f]\n\n", 0, boxes[0].x, boxes[0].y, boxes[0].w, boxes[0].h);
                
                
                // Show image and overlay using OpenCV
                rectangle(image,
                        cvPoint(1 + arapahoImage.w*(boxes[0].x - boxes[0].w/2), 1 + arapahoImage.h*(boxes[0].y - boxes[0].h/2)),
                        cvPoint(1 + arapahoImage.w*(boxes[0].x + boxes[0].w/2), 1 + arapahoImage.h*(boxes[0].y + boxes[0].h/2)),
                        CV_RGB(255,0,0), 1, 8, 0);
            }// If objects were detected
            imshow("Arapaho", image);
            waitKey((1000 / TARGET_SHOW_FPS));

            if (boxes)
            {
                delete[] boxes;
                boxes = NULL;
            }
            p->GetBoxes(
                boxes,
                numObjects);
            for(int i = 0; i<numObjects; i++){
                printf("Box #%d: x,y,w,h = [%f, %f, %f, %f]\n\n", 0, boxes[i].x, boxes[i].y, boxes[i].w, boxes[i].h);
            }
        } //If a frame was read
    }// Detection loop
    
clean_exit:    

    // Clear up things before exiting
    if(p) delete p;
    DPRINTF("Exiting...\n");
    return 0;
}       
