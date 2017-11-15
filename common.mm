void redirectNSlogToFile()
{

    NSString *filePath = @"/var/www/simulateTouchLog.txt";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:filePath]) //如果不存在
    {
        NSString *str = @"simulateTouchLog\n";
        [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    // 将log输入到文件
    freopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    freopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
}

void writeLog(NSString * string)
{

    NSString *filePath = @"/var/www/simulateTouchLog.txt";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:filePath]) //如果不存在
    {
        NSString *str = @"simulateTouchLog\n";
        [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [fileHandle seekToEndOfFile];  //将节点跳到文件的末尾
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *datestr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *str = [NSString stringWithFormat:@"\n%@\n%@",datestr,string];
    NSData* stringData  = [str dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandle writeData:stringData]; //追加写入数据
    [fileHandle closeFile];
   // redirectNSlogToFile();
}
