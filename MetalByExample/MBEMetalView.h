//
//  MBEMetalView.h
//  MetalByExample
//
//  Created by Dan Jiang on 2018/6/8.
//  Copyright © 2018年 Dan Jiang. All rights reserved.
//

@import UIKit;
@import Metal;

@protocol MBEMetalViewDelegate;

@interface MBEMetalView : UIView

@property (nonatomic, weak) id<MBEMetalViewDelegate> delegate;
@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (nonatomic, assign) MTLClearColor clearColor;
@property (nonatomic, readonly) NSTimeInterval frameDuration;
@property (nonatomic, readonly) MTLRenderPassDescriptor *currentRenderPassDescriptor;
@property (nonatomic, readonly) id<CAMetalDrawable> currentDrawable;

@end

@protocol MBEMetalViewDelegate <NSObject>

- (void)drawInView:(MBEMetalView *)view;

@end
