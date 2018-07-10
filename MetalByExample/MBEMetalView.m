//
//  MBEMetalView.m
//  MetalByExample
//
//  Created by Dan Jiang on 2018/7/10.
//  Copyright © 2018年 Dan Jiang. All rights reserved.
//

#import "MBEMetalView.h"
@import Metal;
@import simd;

typedef struct {
  vector_float4 position;
  vector_float4 color;
} MBEVertex;

@interface MBEMetalView ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@end

@implementation MBEMetalView

+ (id)layerClass {
  return [CAMetalLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if ((self = [super initWithCoder:aDecoder])) {
    [self makeDevice];
    [self makeBuffers];
    [self makePipeline];
  }
  
  return self;
}

- (CAMetalLayer *)metalLayer {
  return (CAMetalLayer *)self.layer;
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (self.superview) {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  } else {
    [self.displayLink invalidate];
    self.displayLink = nil;
  }
}

- (void)displayLinkDidFire:(CADisplayLink *)displayLink {
  [self redraw];
}

- (void)redraw {
  id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
  id<MTLTexture> texture = drawable.texture;
  
  MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  passDescriptor.colorAttachments[0].texture = texture;
  passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
  passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
  passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1);

  id<MTLCommandQueue> commandQueue = [self.device newCommandQueue];
  id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
  id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
  [commandEncoder setRenderPipelineState:self.pipeline];
  [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
  [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
  [commandEncoder endEncoding];
  
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
}

- (void)makeDevice {
  self.device = MTLCreateSystemDefaultDevice();
  self.metalLayer.device = self.device;
  self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
}

- (void)makeBuffers {
  static const MBEVertex vertices[] = {
    { .position = {  0.0,  0.5, 0, 1 }, .color = { 1, 0, 0, 1 } },
    { .position = { -0.5, -0.5, 0, 1 }, .color = { 0, 1, 0, 1 } },
    { .position = {  0.5, -0.5, 0, 1 }, .color = { 0, 0, 1, 1 } }
  };
  
  self.vertexBuffer = [self.device newBufferWithBytes:vertices
                                               length:sizeof(vertices)
                                              options:MTLResourceCPUCacheModeDefaultCache];
}

- (void)makePipeline {
  id<MTLLibrary> library = [self.device newDefaultLibrary];
  id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_main"];
  id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];
  
  MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
  pipelineDescriptor.vertexFunction = vertexFunc;
  pipelineDescriptor.fragmentFunction = fragmentFunc;
  pipelineDescriptor.colorAttachments[0].pixelFormat = self.metalLayer.pixelFormat;
  
  NSError *error = nil;
  self.pipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                              error:&error];
  
  if (!self.pipeline) {
    NSLog(@"Error occurred when creating render pipeline state: %@", error);
  }
}

@end
