SimulateTouch
=============
# 优化部分
1.点击事件和滑动事件，分别建立5个监听，来保证发送通知成功。
2.修改滑动事件传递方式，重新构建结构体，STEvent为ZFEvent，减少通知调用频率。


Simulate touch library for iOS

You can make fake touch(even multi-touch) and swipe.

Support iOS6 and 7

REQUIREMENT: RocketBootstrap by Ryan Petrich
(https://github.com/rpetrich/rocketbootstrap)

API Info: http://api.iolate.kr/simulatetouch/

and refer to main.mm (stouch; command line tool) for how to use.

# How it works

There are two components in this project:

### SimulateTouch.dylib MobileSubstrate

This hooks into `com.apple.backboardd` and exposes a Mach messaging port defined as `MACH_PORT_NAME`, current code value is `kr.iolate.simulatetouch`. It listens for Mach messages and uses `IOHIDEvents` to simulate touches/swipes/buttons.

### stouch command line tool

Interprets command line requests into Mach messages and sends it to `MACH_PORT_NAME` Mach port.

# Dependencies

### Theos

Follow instructions to setup Theos [here](http://iphonedevwiki.net/index.php/Theos/Setup).

### rocketboostrap

* Install the `rocketbootstrap` on the device and copy `rocketbootstrap.h` and ``rocketbootstrap_dynamic.h` from `/usr/include/` to your `$THEOS/usr/include/`.
* Copy `/usr/lib/librocketbootstrap.dylib` from device to your `$THEOS/usr/include`.

### bootstrap.h

Get it from rpetrich's RocketBoostrap [repo](https://github.com/rpetrich/RocketBootstrap).

### simulatetouch

* Install `simulatetouch` on the device and copy `/usr/lib/libsimulatetouch.dylib` from device to your `$THEOS/usr/lib`.