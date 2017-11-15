

void redirectNSlogToFile()
{
    NSString * dirPath = @"/var/www/God/Log/";
    NSString * processName = [[NSProcessInfo processInfo]processName];
    NSString * filePath =  [NSString stringWithFormat:@"%@%@.log",dirPath,processName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir = NO;
    BOOL exsit = [fileManager fileExistsAtPath:dirPath isDirectory:&isDir];
    if(exsit&&isDir)
    {
        //文件及已存在    
    }
    else
    {
        if(exsit)[fileManager removeItemAtPath:dirPath error:nil];
        [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if(![fileManager fileExistsAtPath:filePath]) //如果不存在
    {
        NSString *str = @"simulateTouchLog\n";
        [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    // 将log输入到文件
    freopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    freopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
}


