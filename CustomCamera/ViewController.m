//
//  ViewController.m
//  CustomCamera
//
//  Created by ibos on 16/12/12.
//  Copyright © 2016年 ibos. All rights reserved.
//

#import "ViewController.h"
#import "CameraViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)takePhoto:(id)sender {
    [self presentViewController:[CameraViewController new] animated:YES completion:nil];
}

@end
