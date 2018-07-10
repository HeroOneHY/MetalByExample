//
//  MBEOBJMesh.h
//  MetalByExample
//
//  Created by Dan Jiang on 2018/7/4.
//  Copyright © 2018年 Dan Jiang. All rights reserved.
//

@import Foundation;
@import Metal;
#import "MBEMesh.h"

@class MBEOBJGroup;

@interface MBEOBJMesh : MBEMesh

- (instancetype)initWithGroup:(MBEOBJGroup *)group device:(id<MTLDevice>)device;

@end
