//
//  MBEMesh.h
//  MetalByExample
//
//  Created by Dan Jiang on 2018/7/4.
//  Copyright © 2018年 Dan Jiang. All rights reserved.
//

@import Metal;

@interface MBEMesh : NSObject

@property (nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> indexBuffer;

@end
