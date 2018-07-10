//
//  MBERenderer.m
//  MetalByExample
//
//  Created by Dan Jiang on 2018/7/3.
//  Copyright © 2018年 Dan Jiang. All rights reserved.
//

#import "MBERenderer.h"
#import "MBEMathUtilities.h"
@import Metal;
@import simd;

static const NSInteger MBEInFlightBufferCount = 3;

typedef struct {
  vector_float4 position;
  vector_float4 color;
} MBEVertex;

typedef uint16_t MBEIndex;
const MTLIndexType MBEIndexType = MTLIndexTypeUInt16;

typedef struct {
  matrix_float4x4 modelViewProjectionMatrix;
} MBEUniforms;

@interface MBERenderer ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;
@property (nonatomic, strong) dispatch_semaphore_t displaySemaphore;
@property (nonatomic, assign) float rotationX, rotationY, time;
@property (nonatomic, assign) NSInteger bufferIndex;

@end

@implementation MBERenderer

- (instancetype)init {
  self = [super init];
  if (self) {
    [self makeDevice];
    _displaySemaphore = dispatch_semaphore_create(MBEInFlightBufferCount);
    [self makeBuffers];
    [self makePipeline];
  }
  return self;
}

- (void)updateUniformsForView:(MBEMetalView *)view duration:(NSTimeInterval)duration {
  self.time += duration;
  self.rotationX += duration * (M_PI / 2);
  self.rotationY += duration * (M_PI / 3);
  float scaleFactor = sinf(5 * self.time) * 0.25 + 1;
  const vector_float3 xAxis = { 1, 0, 0 };
  const vector_float3 yAxis = { 0, 1, 0 };
  const matrix_float4x4 xRot = matrix_float4x4_rotation(xAxis, self.rotationX);
  const matrix_float4x4 yRot = matrix_float4x4_rotation(yAxis, self.rotationY);
  const matrix_float4x4 scale = matrix_float4x4_uniform_scale(scaleFactor);
  const matrix_float4x4 modelMatrix = matrix_multiply(matrix_multiply(xRot, yRot), scale);
  
  const vector_float3 cameraTranslation = { 0, 0, -5 };
  const matrix_float4x4 viewMatrix = matrix_float4x4_translation(cameraTranslation);
  
  const CGSize drawableSize = view.metalLayer.drawableSize;
  const float aspect = drawableSize.width / drawableSize.height;
  const float fov = (2 * M_PI) / 5;
  const float near = 1;
  const float far = 100;
  const matrix_float4x4 projectionMatrix = matrix_float4x4_perspective(aspect, fov, near, far);
  
  MBEUniforms uniforms;
  uniforms.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, matrix_multiply(viewMatrix, modelMatrix));
  
  const NSUInteger uniformBufferOffset = sizeof(MBEUniforms) * self.bufferIndex;
  memcpy([self.uniformBuffer contents] + uniformBufferOffset, &uniforms, sizeof(uniforms));
}

- (void)drawInView:(MBEMetalView *)view {
  dispatch_semaphore_wait(self.displaySemaphore, DISPATCH_TIME_FOREVER);
  
  view.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);

  [self updateUniformsForView:view duration:view.frameDuration];
  
  id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
  
  MTLRenderPassDescriptor *passDescriptor = [view currentRenderPassDescriptor];

  id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
  [renderPass setRenderPipelineState:self.pipeline];
  [renderPass setDepthStencilState:self.depthStencilState];
  [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
  [renderPass setCullMode:MTLCullModeBack];
  
  const NSUInteger uniformBufferOffset = sizeof(MBEUniforms) * self.bufferIndex;
  
  [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
  [renderPass setVertexBuffer:self.uniformBuffer offset:uniformBufferOffset atIndex:1];
  
  [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                         indexCount:[self.indexBuffer length] / sizeof(MBEIndex)
                          indexType:MBEIndexType
                        indexBuffer:self.indexBuffer
                  indexBufferOffset:0];

  [renderPass endEncoding];
  
  [commandBuffer presentDrawable:view.currentDrawable];
  
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
    self.bufferIndex = (self.bufferIndex + 1) % MBEInFlightBufferCount;
    dispatch_semaphore_signal(self.displaySemaphore);
  }];
  
  [commandBuffer commit];
}

- (void)makeDevice {
  _device = MTLCreateSystemDefaultDevice();
}

- (void)makeBuffers {
  static const MBEVertex vertices[] =
  {
    { .position = { -1,  1,  1, 1 }, .color = { 0, 1, 1, 1 } },
    { .position = { -1, -1,  1, 1 }, .color = { 0, 0, 1, 1 } },
    { .position = {  1, -1,  1, 1 }, .color = { 1, 0, 1, 1 } },
    { .position = {  1,  1,  1, 1 }, .color = { 1, 1, 1, 1 } },
    { .position = { -1,  1, -1, 1 }, .color = { 0, 1, 0, 1 } },
    { .position = { -1, -1, -1, 1 }, .color = { 0, 0, 0, 1 } },
    { .position = {  1, -1, -1, 1 }, .color = { 1, 0, 0, 1 } },
    { .position = {  1,  1, -1, 1 }, .color = { 1, 1, 0, 1 } }
  };
  
  static const MBEIndex indices[] =
  {
    3, 2, 6, 6, 7, 3,
    4, 5, 1, 1, 0, 4,
    4, 0, 3, 3, 7, 4,
    1, 5, 6, 6, 2, 1,
    0, 1, 2, 2, 3, 0,
    7, 6, 5, 5, 4, 7
  };
  
  self.vertexBuffer = [self.device newBufferWithBytes:vertices
                                               length:sizeof(vertices)
                                              options:MTLResourceCPUCacheModeDefaultCache];
  self.vertexBuffer.label = @"Vertices";
  
  self.indexBuffer = [self.device newBufferWithBytes:indices
                                              length:sizeof(indices)
                                             options:MTLResourceOptionCPUCacheModeDefault];
  self.indexBuffer.label = @"Indices";
  
  self.uniformBuffer = [self.device newBufferWithLength:sizeof(MBEUniforms) * MBEInFlightBufferCount
                                                  options:MTLResourceOptionCPUCacheModeDefault];
  self.uniformBuffer.label = @"Uniforms";
}

- (void)makePipeline {
  id<MTLLibrary> library = [self.device newDefaultLibrary];
  id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_project"];
  id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_flatcolor"];
  
  MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
  pipelineDescriptor.vertexFunction = vertexFunc;
  pipelineDescriptor.fragmentFunction = fragmentFunc;
  pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
  pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
  
  MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
  depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
  depthStencilDescriptor.depthWriteEnabled = YES;
  self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];

  NSError *error = nil;
  self.pipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                              error:&error];
  
  if (!self.pipeline) {
    NSLog(@"Error occurred when creating render pipeline state: %@", error);
  }
  
  self.commandQueue = [self.device newCommandQueue];
}

@end
