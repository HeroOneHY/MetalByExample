//
//  ViewController.m
//  MetalByExample
//
//  Created by Dan Jiang on 2018/6/8.
//  Copyright © 2018年 Dan Jiang. All rights reserved.
//

#import "ViewController.h"
#import "MBERenderer.h"
#import "MBEMetalView.h"

@interface ViewController ()

@property (nonatomic, strong) MBERenderer *renderer;

@end

@implementation ViewController

- (MBEMetalView *)metalView {
  return (MBEMetalView *)self.view;
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.renderer = [MBERenderer new];
  self.metalView.delegate = self.renderer;
}

@end
