#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"\n" fmt), ##__VA_ARGS__);
#else
#   define DLog(...)
#endif