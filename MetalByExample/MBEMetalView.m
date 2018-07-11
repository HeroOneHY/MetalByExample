//
//  MBEMetalView.m
//  MetalByExample
//
//  Created by Dan Jiang on 2018/6/8.
//  Copyright © 2018年 Dan Jiang. All rights reserved.
//

#import "MBEMetalView.h"

@interface MBEMetalView ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) id<CAMetalDrawable> currentDrawable;
@property (nonatomic, assign) NSTimeInterval frameDuration;
@property (nonatomic, strong) id<MTLTexture> depthTexture;

@end

@implementation MBEMetalView

+ (Class)layerClass {
  return [CAMetalLayer class];
}

- (CAMetalLayer *)metalLayer {
  return (CAMetalLayer *)self.layer;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if ((self = [super initWithCoder:aDecoder]))
  {
    [self commonInit];
    self.metalLayer.device = MTLCreateSystemDefaultDevice();
  }
  
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device {
  if ((self = [super initWithFrame:frame])) {
    [self commonInit];
    self.metalLayer.device = device;
  }
  
  return self;
}

- (void)commonInit {
  _clearColor = MTLClearColorMake(1, 1, 1, 1);
  
  self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
}

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  
  CGFloat scale = [UIScreen mainScreen].scale;
  
  if (self.window) {
    scale = self.window.screen.scale;
  }
  
  CGSize drawableSize = self.bounds.size;
  
  drawableSize.width *= scale;
  drawableSize.height *= scale;
  
  self.metalLayer.drawableSize = drawableSize;
  
  [self makeDepthTexture];
}

- (void)didMoveToWindow {
  if (self.window) {
    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  } else {
    [self.displayLink invalidate];
    self.displayLink = nil;
  }
}

- (void)displayLinkDidFire:(CADisplayLink *)displayLink {
  self.currentDrawable = [self.metalLayer nextDrawable];
  self.frameDuration = displayLink.duration;
  
  if ([self.delegate respondsToSelector:@selector(drawInView:)]) {
    [self.delegate drawInView:self];
  }
}

- (void)makeDepthTexture {
  CGSize drawableSize = self.metalLayer.drawableSize;
  
  if ([self.depthTexture width] != drawableSize.width ||
      [self.depthTexture height] != drawableSize.height) {
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                    width:drawableSize.width
                                                                                   height:drawableSize.height
                                                                                mipmapped:NO];
    desc.usage = MTLTextureUsageRenderTarget;
    
    self.depthTexture = [self.metalLayer.device newTextureWithDescriptor:desc];
  }
}

- (MTLRenderPassDescriptor *)currentRenderPassDescriptor {
  MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  
  passDescriptor.colorAttachments[0].texture = [self.currentDrawable texture];
  passDescriptor.colorAttachments[0].clearColor = self.clearColor;
  passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
  passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
  
  passDescriptor.depthAttachment.texture = self.depthTexture;
  passDescriptor.depthAttachment.clearDepth = 1.0;
  passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
  passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
  
  return passDescriptor;
}

@end
