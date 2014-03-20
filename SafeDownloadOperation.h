//
//  SafeDownloadOperation.h
//  WholeApp 2.0
//
//  Created by Valerii Lider on 12/6/12.
//  Copyright (c) 2012 Dilious Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SafeDownloadOperation : NSOperation< NSURLConnectionDelegate >

- (id)initWithURL:(NSURL *)url savePath:(NSURL *)path;

@property (strong) NSError *error;
@property (strong) NSURL *sourceURL;
@property (strong) NSURL *destinationURL;
@property (strong) id completionTarget;
@property (strong) NSString *completionSelector;
@property (strong) NSThread *runInThread;
@property (strong) NSDictionary *userInfo;

@end
