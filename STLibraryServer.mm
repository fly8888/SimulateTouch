/*
 * Name: libSimulateTouch
 * Author: iolate <iolate@me.com>
 *
 */

#import <mach/mach_time.h>
#include <substrate.h>
#import <CoreGraphics/CoreGraphics.h>
#import "rocketbootstrap.h"
extern void redirectNSlogToFile();
#define LOOP_TIMES_IN_SECOND 40
//60
#define MACH_PORT_NAME @"kr.iolate.simulatetouch"
#define MACH_PORT_NAME2 @"kr.iolate.simulatetouch.swipeEvent"

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%@\n" fmt), [NSDate date], ##__VA_ARGS__);
#else
#   define DLog(...)
#endif


typedef enum {
    STTouchMove = 0,
    STTouchDown,
    STTouchUp,

    // For these types, (int)point_x denotes button type
    STButtonUp,
    STButtonDown
} STTouchType;

typedef struct {
    int type;       // STTouchType values
    int index;      // pathIndex holder in message
    float point_x;
    float point_y;
} STEvent;

typedef struct {
    int eventType ;
    int type; //터치 종류 0: move/stay| 1: down| 2: up
    int pathIndex;
    CGPoint startPoint;
    CGPoint endPoint;
    uint64_t startTime;
    float requestedTime;
} ZFEvent;

// typedef enum {
//     UIInterfaceOrientationPortrait           = 1,//UIDeviceOrientationPortrait,
//     UIInterfaceOrientationPortraitUpsideDown = 2,//UIDeviceOrientationPortraitUpsideDown,
//     UIInterfaceOrientationLandscapeLeft      = 4,//UIDeviceOrientationLandscapeRight,
//     UIInterfaceOrientationLandscapeRight     = 3,//UIDeviceOrientationLandscapeLeft
// } UIInterfaceOrientation;

// @interface UIScreen
// +(id)mainScreen;
// -(CGRect)bounds;
// @end

@interface STTouchA : NSObject
{
@public
    int type; //터치 종류 0: move/stay| 1: down| 2: up
    int pathIndex;
    CGPoint startPoint;
    CGPoint endPoint;
    uint64_t startTime;
    float requestedTime;
}
@end
@implementation STTouchA
@end

@interface SimulateTouch : NSObject
+(int)simulateTouch:(int)pathIndex atPoint:(CGPoint)point withType:(int)type;
+(int)simulateSwipeFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(float)duration;
@end


static NSMutableArray* ATouchEvents = nil;
static BOOL FTLoopIsRunning = FALSE;
#pragma mark -
extern int ZFReceivedMsgEvent(STEvent * touch);

CFDataRef ZFMessageCallBack(CFMessagePortRef local, SInt32 msgid, CFDataRef cfData, void *info)
{
    DLog(@"----ZFMessageCallBack-----");
    if (msgid == 1) {
        if (CFDataGetLength(cfData) == sizeof(ZFEvent)) {
            ZFEvent* touch = (ZFEvent *)[(NSData *)cfData bytes];
            if (touch != NULL) 
            {
                if(touch->eventType==1)
                {
                    [SimulateTouch simulateTouch:touch->pathIndex atPoint:touch->startPoint withType:touch->type];

                }else if(touch->eventType==2)
                {
                    [SimulateTouch simulateSwipeFromPoint:touch->startPoint toPoint:touch->endPoint duration:touch->requestedTime];

                }
                int pathIndex = touch->pathIndex;
                return (CFDataRef)[[NSData alloc] initWithBytes:&pathIndex length:sizeof(pathIndex)];
            }
        }
    } else {
        DLog(@"### ST: Unknown message type: %d", (int)msgid); //%x
    }
    return NULL;
}

static int send_event(STEvent * event) 
{
    return ZFReceivedMsgEvent(event);
}


static int simulate_button_event(int index, int button, int state) {
    STEvent event;
    event.index = index;
    
    event.type    = (int)STButtonUp + state;
    event.point_x = button;
    event.point_y = 0.0f;

    return send_event(&event);
}

static int simulate_touch_event(int index, int type, CGPoint point) {
    STEvent event;
    event.index = index;
    
    event.type = type;
    event.point_x = point.x;
    event.point_y = point.y;
    
    return send_event(&event);
}

double MachTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer / (double)timebase.denom / 1e9;
}


static void _simulateTouchLoop()
{
    if (FTLoopIsRunning == FALSE) {
        return;
    }
    int touchCount = [ATouchEvents count];
    
    if (touchCount == 0) {
        FTLoopIsRunning = FALSE;
        return;
    }
    
    NSMutableArray* willRemoveObjects = [NSMutableArray array];
    uint64_t curTime = mach_absolute_time();
    
    for (int i = 0; i < touchCount; i++)
    {
        STTouchA* touch = [ATouchEvents objectAtIndex:i];
        
        int touchType = touch->type;
        //0: move/stay 1: down 2: up
        
        if (touchType == 1) {
            //Already simulate_touch_event is called
            touch->type = STTouchMove;
        }else {
            double dif = MachTimeToSecs(curTime - touch->startTime);
            
            float req = touch->requestedTime;
            if (dif >= 0 && dif < req) {
                //Move
                
                float dx = touch->endPoint.x - touch->startPoint.x;
                float dy = touch->endPoint.y - touch->startPoint.y;
                
                double per = dif / (double)req;
                CGPoint point = CGPointMake(touch->startPoint.x + (float)(dx * per), touch->startPoint.y + (float)(dy * per));
                
                int r = simulate_touch_event(touch->pathIndex, STTouchMove, point);
                if (r == 0) {
                    DLog(@"ST Error: touchLoop type:0 index:%d, point:(%d,%d) pathIndex:0", touch->pathIndex, (int)point.x, (int)point.y);
                    continue;
                }
                
            }else {
                //Up
                simulate_touch_event(touch->pathIndex, STTouchMove, touch->endPoint);
                int r = simulate_touch_event(touch->pathIndex, STTouchUp, touch->endPoint);
                if (r == 0) {
                    DLog(@"ST Error: touchLoop type:2 index:%d, point:(%d,%d) pathIndex:0", touch->pathIndex, (int)touch->endPoint.x, (int)touch->endPoint.y);
                    continue;
                }
                
                [willRemoveObjects addObject:touch];
            }
        }
    }
    
    for (STTouchA* touch in willRemoveObjects) {
        [ATouchEvents removeObject:touch];
        [touch release];
    }
    
    willRemoveObjects = nil;
    
    //recursive
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / LOOP_TIMES_IN_SECOND);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _simulateTouchLoop();
    });
}

#pragma mark -


@implementation SimulateTouch

+(CGPoint)STScreenToWindowPoint:(CGPoint)point withOrientation:(UIInterfaceOrientation)orientation {
    CGSize screen = [[UIScreen mainScreen] bounds].size;
    
    if (orientation == UIInterfaceOrientationPortrait) {
        return point;
    }else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGPointMake(screen.width - point.x, screen.height - point.y);
    }else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        //Homebutton is left
        return CGPointMake(screen.height - point.y, point.x);
    }else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGPointMake(point.y, screen.width - point.x);
    }else return point;
}

+(CGPoint)STWindowToScreenPoint:(CGPoint)point withOrientation:(UIInterfaceOrientation)orientation {
    CGSize screen = [[UIScreen mainScreen] bounds].size;
    
    if (orientation == UIInterfaceOrientationPortrait) {
        return point;
    }else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGPointMake(screen.width - point.x, screen.height - point.y);
    }else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        //Homebutton is left
        return CGPointMake(point.y, screen.height - point.x);
    }else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGPointMake(screen.width - point.y, point.x);
    }else return point;
}

+(int)simulateButton:(int)button state:(int)state
{
    int r = simulate_button_event(0, button, state);
    
    if (r == 0) {
        DLog(@"ST Error: simulateButton:state: button:%d state:%d pathIndex:0", button, state);
        return 0;
    }
    return r;
}

+(int)simulateTouch:(int)pathIndex atPoint:(CGPoint)point withType:(int)type
{
    DLog(@"------server--simulateTouch----------");
    int r = simulate_touch_event(pathIndex, type, point);
    
    if (r == 0) {
        DLog(@"ST Error: simulateTouch:atPoint:withType: index:%d type:%d pathIndex:0", pathIndex, type);
        return 0;
    }
    return r;
}

+(int)simulateSwipeFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(float)duration
{

    DLog(@"------server--simulateSwipeFromPoint----------");
    if (ATouchEvents == nil) {
        ATouchEvents = [[NSMutableArray alloc] init];
    }
    
    STTouchA* touch = [[STTouchA alloc] init];
    
    touch->type = STTouchMove;
    touch->startPoint = fromPoint;
    touch->endPoint = toPoint;
    touch->requestedTime = duration;
    touch->startTime = mach_absolute_time();
    
    [ATouchEvents addObject:touch];
    
    int r = simulate_touch_event(0, STTouchDown, fromPoint);
    if (r == 0) {
        DLog(@"ST Error: simulateSwipeFromPoint:toPoint:duration: pathIndex:0");
        return 0;
    }
    touch->pathIndex = r;
    
    if (!FTLoopIsRunning) {
        FTLoopIsRunning = TRUE;
        _simulateTouchLoop();
    }
    
    return r;
}

@end
MSInitialize
{
    redirectNSlogToFile();
    for(int i=0;i<5;i++)
    {
         NSString * portName = [NSString stringWithFormat:@"%@_%d",MACH_PORT_NAME2,i];
         CFMessagePortRef local = CFMessagePortCreateLocal(NULL,(CFStringRef) portName, ZFMessageCallBack, NULL, NULL);
         if (rocketbootstrap_cfmessageportexposelocal(local) != 0)
         {
            //创建失败
            DLog(@"--ERROR---CFMessagePortCreateLocal---portName:%@---",portName);
            continue;
        }else
        {
            DLog(@"--SUCCESS---CFMessagePortCreateLocal---portName:%@---",portName);
            CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(NULL, local, 0);
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
        }  
    }

}