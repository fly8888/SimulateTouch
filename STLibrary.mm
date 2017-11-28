/*
 * Name: libSimulateTouch
 * Author: iolate <iolate@me.com>
 *
 */
#include <substrate.h>
#import <mach/mach_time.h>
#import <CoreGraphics/CoreGraphics.h>
#import "rocketbootstrap.h"
extern void redirectNSlogToFile();
#define LOOP_TIMES_IN_SECOND 40
//60
#define MACH_PORT_NAME @"kr.iolate.simulatetouch"
#define MACH_PORT_NAME1 @"kr.iolate.simulatetouch.touchEvent"
#define MACH_PORT_NAME2 @"kr.iolate.simulatetouch.swipeEvent"

#import "Pch.h"



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
    int eventType ;//1：点击 2：滑动
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

static CFMessagePortRef messagePort = NULL;

static NSMutableArray* ATouchEvents = nil;
static BOOL FTLoopIsRunning = FALSE;

#pragma mark -
static int postNotify(NSData * data)
{
    DLog(@"发送动作通知");
    if(data&&data.length>0)
    {
        BOOL result = [data writeToFile:@"/var/www/simulatetouch.click" atomically:YES];
        if(result)
        {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFSTR("backboard.postnotify.event"),
                                         NULL,
                                         NULL,
                                         TRUE);
            return 1;
        }
        else
        {
            DLog(@"点击数据写入失败");
            return 0;;
        }
    }else
    {
        DLog(@"接收到的数据有误");
        return 0;
    }
    return 0;
}


/*
static int ZFSimulate_send_event(ZFEvent * event)
{
    DLog(@"发送滑动事件");
    for (int i=0; i<5; i++)
    {
        NSString * portName = [NSString stringWithFormat:@"%@_%d",MACH_PORT_NAME2,i];
        if (messagePort2 && !CFMessagePortIsValid(messagePort2)){
            CFRelease(messagePort2);
            messagePort2 = NULL;
        }
        if (!messagePort2)
        {
            messagePort2 = rocketbootstrap_cfmessageportcreateremote(NULL, (__bridge CFStringRef)portName);
        }
        if (!messagePort2 || !CFMessagePortIsValid(messagePort2))
        {

            if(i==4)
            {
                DLog(@"ERROR-发送失败，滑动事件所有端口无效:%@",portName);
                return 0;
                
            }else
            {
                continue;
            }
        }
        //创建成功
        break;
    }

    CFDataRef cfData = CFDataCreate(NULL, (uint8_t*)event, sizeof(*event));
    CFDataRef rData = NULL;
    CFMessagePortSendRequest(messagePort2, 1, cfData, 1, 1, kCFRunLoopDefaultMode, &rData);
    if (cfData) {
        CFRelease(cfData);
    }
    int pathIndex;
    [(NSData *)rData getBytes:&pathIndex length:sizeof(pathIndex)];
    if (rData) {
        CFRelease(rData);
    }
    DLog(@"SUCCESS-发送滑动事件成功-ID:%d",pathIndex);
    return pathIndex;
}
*/

//发送触摸事件
static int send_event(STEvent * event) 
{
    DLog(@"发送点击事件");
    for (int i=0; i<5; i++)
    {
        NSString * portName = [NSString stringWithFormat:@"%@_%d",MACH_PORT_NAME1,i];
        if (messagePort && !CFMessagePortIsValid(messagePort)){
            CFRelease(messagePort);
            messagePort = NULL;
        }
        if (!messagePort)
        {
            messagePort = rocketbootstrap_cfmessageportcreateremote(NULL, (__bridge CFStringRef)portName);
        }
        if (!messagePort || !CFMessagePortIsValid(messagePort))
        {
            if(i==4)
            {
                DLog(@"ERROR-发送失败，所有发送端口不可用:%@---point_x:%f-point_y:%f-Type:%d----",portName,event->point_x,event->point_y,event->type);
                return 0;       
            }else
            {
                continue;
            }
        }
        //创建成功
        break;
    }

   
    CFDataRef cfData = CFDataCreate(NULL, (uint8_t*)event, sizeof(*event));
    CFDataRef rData = NULL;
    
    CFMessagePortSendRequest(messagePort, 1/*type*/, cfData, 1, 1, kCFRunLoopDefaultMode, &rData);
    
    if (cfData) {
        CFRelease(cfData);
    }
    
    int pathIndex;
    [(NSData *)rData getBytes:&pathIndex length:sizeof(pathIndex)];
    
    if (rData) {
        CFRelease(rData);
    }
    DLog(@"SUCCESS-发送点击事件成功-point_x:%f-point_y:%f-Type:%d--ID:%d-",event->point_x,event->point_y,event->type,pathIndex);
    return pathIndex;
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
    int r = send_event(&event);
    return r;
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
                    NSLog(@"ST Error: touchLoop type:0 index:%d, point:(%d,%d) pathIndex:0", touch->pathIndex, (int)point.x, (int)point.y);
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

@interface SimulateTouch : NSObject
@end

@implementation SimulateTouch

+(void)smtTest
{
    for(int i=0;i<5000;i++)
    {   
        [SimulateTouch simulateTouch:0 atPoint: CGPointMake(200, 300) withType:0];
    }

}

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
        
        NSLog(@"ST Error: simulateButton:state: button:%d state:%d pathIndex:0", button, state);
        return 0;
    }
    return r;
}

+(int)simulateTouch:(int)pathIndex atPoint:(CGPoint)point withType:(int)type
{
    //int r = simulate_touch_event(pathIndex, 8, point);
    // DLog(@"ST Error: simulateTouch:atPoint:withType: index:%d type:%d pathIndex:0", pathIndex, 8);
    ZFEvent event;
    event.eventType=1;
    event.type= 0;// 这里为新增类型，在收到通知后会自动把类型替换为两次事件，类型分别为1，2
    event.pathIndex = pathIndex;
    event.startPoint=point;
    NSData * data = [NSData dataWithBytes:&event length:sizeof(event)];
    DLog(@"第二种方式发送点击数据");
    int result = postNotify(data);
    return result;
}

+(int)simulateSwipeFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint duration:(float)duration
{
    ZFEvent event;
    event.eventType=2;
    event.type= STTouchMove;
    event.startPoint=fromPoint;
    event.endPoint = toPoint;
    event.requestedTime = duration;
    //int r = ZFSimulate_send_event(&event);
    // DLog(@"ST Error: simulateSwipeFromPoint:toPoint:duration: pathIndex:0");
    DLog(@"第二种方式发送滑动数据");
    NSData * data = [NSData dataWithBytes:&event length:sizeof(event)];
    int result = postNotify(data);
    return result;
}

@end
MSInitialize
{
    redirectNSlogToFile();
    DLog(@"init--simulatetouch--");
}