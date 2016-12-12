//
//  CameraViewController.m
//  ibosvip
//
//  Created by 肖睿 on 2016/10/8.
//  Copyright © 2016年 ibos. All rights reserved.
//

#import "CameraViewController.h"
#import <AVFoundation/AVFoundation.h>


#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height


@interface CameraViewController ()<UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *backView;


/**
 *  捕获设备
 */
@property (nonatomic, strong) AVCaptureDevice *device;
/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession *session;
/**
 *  输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
/**
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 *  最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;

@property (nonatomic, strong) UIView *focusView;

@property (nonatomic, strong) UIImageView *photoView;


@property (nonatomic, assign) BOOL isFrontCamera;
@end

@implementation CameraViewController

- (UIView *)focusView {
    if (!_focusView) {
        _focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
        _focusView.layer.borderWidth = 1.0;
        _focusView.layer.borderColor =[UIColor greenColor].CGColor;
        _focusView.backgroundColor = [UIColor clearColor];
        _focusView.hidden = YES;
        [self.backView addSubview:_focusView];
    }
    return _focusView;
}

- (UIImageView *)photoView {
    if (!_photoView) {
        _photoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight - 120)];
        _photoView.contentMode = UIViewContentModeScaleAspectFill;
        _photoView.hidden = YES;
        [self.backView addSubview:_photoView];
    }
    return _photoView;
}


#pragma mark life circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
   
    
    [self initAVCaptureSession];
    [self setUpGesture];
    
    _isFrontCamera = NO;
    self.effectiveScale = self.beginGestureScale = 1.0f;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
     self.navigationController.navigationBar.hidden = YES;
    if (self.session) [self.session startRunning];
}


- (void)viewWillDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
     self.navigationController.navigationBar.hidden = NO;
    if (self.session) [self.session stopRunning];
}


#pragma mark private method
- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [self.device lockForConfiguration:nil];
    [self.device setFlashMode:AVCaptureFlashModeAuto];//闪光灯
    [self.device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];

    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    self.stillImageOutput.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight - 120);
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.backView.layer.masksToBounds = YES;
    [self.backView.layer addSublayer:self.previewLayer];
}


//- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
//    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
//    if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
//        return AVCaptureVideoOrientationLandscapeRight;
//    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight)
//        return AVCaptureVideoOrientationLandscapeLeft;
//    return result;
//}

- (void)setUpGesture{
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.backView addGestureRecognizer:pinch];
    
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
    [self.backView addGestureRecognizer:tapGesture];
}



#pragma mark respone method
- (IBAction)changeCamera:(UIButton *)sender {
    AVCaptureDevicePosition desiredPosition = _isFrontCamera?AVCaptureDevicePositionBack: AVCaptureDevicePositionFront;
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (d.position == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
    _isFrontCamera = !_isFrontCamera;
}

- (IBAction)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)takePhotoButtonClick:(UIButton *)sender {
    self.photoView.hidden = sender.selected;
    self.photoView.image = nil;
    if (!sender.selected) {
        AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
//        UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
//        AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
//        [stillImageConnection setVideoOrientation:avcaptureOrientation];
        [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
        
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [self normalizedImage:[UIImage imageWithData:jpegData]];
            self.photoView.image = image;//[self imageFromImage:image];
        }];
    }
    sender.selected = !sender.selected;
}

- (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

//- (UIImage *)imageFromImage:(UIImage *)image{
//    CGFloat height = ScreenWidth * image.size.height / image.size.width - ScreenHeight;
//    CGFloat y = height / ScreenWidth * image.size.width;
//    CGRect rect = CGRectMake(0, y, image.size.width, (ScreenHeight - 120) / ScreenWidth * image.size.width);
//    CGImageRef sourceImageRef = image.CGImage;
//    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
//    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
//    CGImageRelease(newImageRef);
//    return newImage;
//}

#pragma mark gestureRecognizer delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    self.effectiveScale = self.beginGestureScale * recognizer.scale;
    if (self.effectiveScale < 1.0) self.effectiveScale = 1.0;
    CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
    if (self.effectiveScale > maxScaleAndCropFactor) self.effectiveScale = maxScaleAndCropFactor;
    self.previewLayer.affineTransform = CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale);
}


- (void)focusGesture:(UITapGestureRecognizer*)gesture{
    CGPoint point = [gesture locationInView:gesture.view];
    CGSize size = self.backView.bounds.size;
    CGPoint focusPoint = CGPointMake( point.y / size.height ,1 - point.x / size.width);
    if ([self.device lockForConfiguration:nil]) {
        
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.device setExposurePointOfInterest:focusPoint];
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        [self.device unlockForConfiguration];
        self.focusView.center = point;
        _focusView.hidden = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
            _focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                _focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                _focusView.hidden = YES;
            }];
        }];
    }
}
@end
