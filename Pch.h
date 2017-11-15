#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%@\n" fmt), [NSDate date], ##__VA_ARGS__);
#else
#   define DLog(...)
#endif