//
//  SafeDownloadOperation.m
//  WholeApp 2.0
//
//  Created by Valerii Lider on 12/6/12.
//  Copyright (c) 2012 Dilious Solutions. All rights reserved.
//

#import "SafeDownloadOperation.h"

@interface SafeDownloadOperation()

@property (strong) NSMutableURLRequest *request;
//@property (strong) NSURLConnection *fileSizeConnection;
@property (strong) NSURLConnection *fileConnection;
@property (strong) NSFileHandle *fileHandle;
@property (assign) unsigned long long fileSize;
@property (assign) BOOL finished;
@property (assign) BOOL executing;
@end

@implementation SafeDownloadOperation

- (void)dealloc
{
//    NSLog(@"SafeDownloadOperation deallocated");
}

- (id)initWithURL:(NSURL *)url savePath:(NSURL *)path
{
    self = [ super init ];
    if( self )
    {
        self.finished = NO;
        self.executing = NO;
        
        self.destinationURL = path;
        self.sourceURL = url;
    }
    
    return self;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return self.executing;
}

- (BOOL)isFinished
{
    return self.finished;
}

- (void)_start
{
    [ self requestForFile ];
//    [ self requestForFileSize ];
}

- (void)start
{
    @autoreleasepool
    {
        if( [ self isCancelled ] )
            return [ self shutdown ];
        
        self.executing = YES;
        
        NSFileManager *manager = [ NSFileManager defaultManager ];
        if( ![ manager fileExistsAtPath:self.destinationURL.path ] )
        {
            BOOL isDirectory = NO;
            NSString *directoryPath = [ self.destinationURL.path stringByDeletingLastPathComponent ];
            if( ![ manager fileExistsAtPath:directoryPath isDirectory:&isDirectory ] )
            {
                [ manager createDirectoryAtPath:directoryPath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:NULL ];
            }
            
            if( ![ manager createFileAtPath:self.destinationURL.path contents:[ NSData data ] attributes:nil ] )
            {
                self.error = [ NSError errorWithDomain:NSStringFromClass([ self class ]) code:10 userInfo:nil ];
                [ self shutdown ];
            }
            else
                [ self performSelector:@selector(_start) onThread:self.runInThread withObject:nil waitUntilDone:NO ];
        }
        else
            [ self performSelector:@selector(_start) onThread:self.runInThread withObject:nil waitUntilDone:NO ];
    }
}

- (void)cancel
{
    self.error = [ NSError errorWithDomain:NSStringFromClass([ self class ]) code:30 userInfo:nil ];
    
    [ super cancel ];
}

- (void)shutdown
{
    if( self.isExecuting && !self.isFinished )
    {
        [ self willChangeValueForKey:@"isExecuting" ];
        self.executing = NO;
        [ self didChangeValueForKey:@"isExecuting" ];
        
        [ self willChangeValueForKey:@"isFinished" ];
        self.finished = YES;
        [ self didChangeValueForKey:@"isFinished" ];
        
//        [ self.fileSizeConnection unscheduleFromRunLoop:[ NSRunLoop currentRunLoop ] forMode:NSRunLoopCommonModes ];
        [ self.fileConnection unscheduleFromRunLoop:[ NSRunLoop currentRunLoop ] forMode:NSRunLoopCommonModes ];
        
        if( self.error )
        {
            NSError *error = nil;
            [ [ NSFileManager defaultManager ] removeItemAtURL:self.destinationURL error:&error ];
        }
        else
        {
            unsigned long long fileOffset = self.fileHandle.seekToEndOfFile;
            unsigned long long fileSize = self.fileSize;
            
            if( fileSize != fileOffset )
            {
                NSError *error = nil;
                [ [ NSFileManager defaultManager ] removeItemAtURL:self.destinationURL error:&error ];
            }
        }
    }
}

//- (void)requestForFileSize
//{
//    self.request = [ NSMutableURLRequest requestWithURL:self.sourceURL
//                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
//                                        timeoutInterval:10 ];
//    [ self.request setHTTPMethod:@"HEAD" ];
//    [ self.request setValue:@"close" forHTTPHeaderField:@"Connection" ];
//    
//    self.fileSizeConnection = [ [ NSURLConnection alloc ] initWithRequest:self.request delegate:self startImmediately:NO ];
//    [ self.fileSizeConnection scheduleInRunLoop:[ NSRunLoop currentRunLoop ] forMode:NSRunLoopCommonModes ];
//    [ self.fileSizeConnection start ];
//}

- (void)requestForFile
{
    NSError *error = nil;
    self.fileHandle = [ NSFileHandle fileHandleForWritingToURL:self.destinationURL error:&error ];
    if( nil == error )
    {
        [ self.fileHandle truncateFileAtOffset:0UL ];
        
        self.request = [ NSMutableURLRequest requestWithURL:self.sourceURL
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:10 ];
        [ self.request setHTTPMethod:@"GET" ];
        
        self.fileConnection = [ [ NSURLConnection alloc ] initWithRequest:self.request delegate:self startImmediately:NO ];
        [ self.fileConnection scheduleInRunLoop:[ NSRunLoop currentRunLoop ] forMode:NSRunLoopCommonModes ];
        [ self.fileConnection start ];
    }
    else
    {
        self.error = [ NSError errorWithDomain:NSStringFromClass([ self class ]) code:30 userInfo:nil ];
        
        [ self shutdown ];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = [ NSError errorWithDomain:NSStringFromClass([ self class ]) code:20 userInfo:nil ];
    
    [ self shutdown ];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if( self.isCancelled )
        return [ self shutdown ];
    
//    if( connection == self.fileSizeConnection )
    {
        NSDictionary *headers = [ (NSHTTPURLResponse *)response allHeaderFields ];
        self.fileSize = [ [ headers valueForKey:@"Content-Length" ] longLongValue ];
        if( 0UL != self.fileSize )
        {
//            [ self requestForFile ];
        }
        else
        {
            NSLog(@"Requested file have size equal to 0MB");
            
            self.error = [ NSError errorWithDomain:NSStringFromClass([ self class ])
                                              code:30
                                          userInfo:nil ];
            [ self shutdown ];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if( self.isCancelled )
        return [ self shutdown ];
    
    if( connection == self.fileConnection )
        [ self.fileHandle writeData:data ];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if( connection == self.fileConnection )
        [ self shutdown ];
}

@end
