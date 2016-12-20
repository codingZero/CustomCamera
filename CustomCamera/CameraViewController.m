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

@interface CameraViewController ()<UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *circleView;
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
@property (nonatomic, weak) UIImageView *photoView;
@end

@implementation CameraViewController

- (UIView *)focusView {
    if (!_focusView) {
        _focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
        _focusView.layer.borderWidth = 1.0;
        _focusView.layer.borderColor = [UIColor colorWithRed:0.251 green:0.694 blue:1.000 alpha:1.000].CGColor;
        _focusView.backgroundColor = [UIColor clearColor];
        _focusView.hidden = YES;
        [self.cameraView addSubview:_focusView];
    }
    return _focusView;
}

- (UIImageView *)photoView {
    if (!_photoView) {
        UIImageView *photoView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        photoView.contentMode = UIViewContentModeScaleAspectFit;
        photoView.backgroundColor = [UIColor blackColor];
        photoView.userInteractionEnabled = YES;
        photoView.hidden = YES;
        [photoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hiddenPhoto)]];
        [self.view addSubview:photoView];
        _photoView = photoView;
    }
    return _photoView;
}


#pragma mark life circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initAVCaptureSession];
    
    self.effectiveScale = self.beginGestureScale = 1.0f;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
    [self.cameraView addGestureRecognizer:tapGesture];
}

#pragma mark private method
- (void)initAVCaptureSession{
    self.session = [[AVCaptureSession alloc] init];
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [self.device lockForConfiguration:nil];
    [self.device setFlashMode:AVCaptureFlashModeAuto];//闪光灯
    //设置帧数
    self.device.activeVideoMinFrameDuration  = CMTimeMake(1, 15);
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
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight - 120);
    self.cameraView.layer.masksToBounds = YES;
    [self.cameraView.layer addSublayer:self.previewLayer];
    
    [self.session startRunning];
}


- (void)hiddenPhoto {
    self.photoView.hidden = YES;
    [self.session startRunning];
}


- (IBAction)takePhoto {
    //去掉快门声音
    static SystemSoundID soundID = 0;
    if (soundID == 0) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"photoShutter2" ofType:@"caf"];
        NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
    }
    AudioServicesPlaySystemSound(soundID);
    
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {

        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:jpegData];
        
        if (self.session.isRunning) [self.session stopRunning];
        self.photoView.image = [self tailorImage:image];
        self.photoView.hidden = NO;
    }];
}


//裁剪图片
- (UIImage *)tailorImage:(UIImage *)image {
    CGFloat scale = image.size.width / _cameraView.frame.size.width;
    CGFloat showImageH = image.size.height / scale;
    CGFloat offsetY = (showImageH - _cameraView.frame.size.height) * 0.5;
    CGFloat factY = (_circleView.frame.origin.y + offsetY) * scale;
    CGRect rect = CGRectMake(factY, _circleView.frame.origin.x * scale, _circleView.frame.size.height * scale, _circleView.frame.size.width * scale);
    
    CGImageRef oriImageRef = image.CGImage;
    CGImageRef tailorImageRef = CGImageCreateWithImageInRect(oriImageRef, rect);
    UIImage *tailorImage = [UIImage imageWithCGImage:tailorImageRef];
    
    //压缩图片并黑白处理，减小图片体积
    tailorImage = [self imageCompressImage:tailorImage targetWidth:800];
    tailorImage = [self convertImageToGreyScale:tailorImage];
    
    return tailorImage;
}


//压缩图片
- (UIImage *)imageCompressImage:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth {
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = (targetWidth / width) * height;
    
    UIGraphicsBeginImageContext(CGSizeMake(targetWidth, targetHeight));
    [sourceImage drawInRect:CGRectMake(0,0,targetWidth, targetHeight)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
    
}

//黑白化
- (UIImage *) convertImageToGreyScale:(UIImage*) image {
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    CGContextDrawImage(context, imageRect, [image CGImage]);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    return newImage;
}


- (void)focusGesture:(UITapGestureRecognizer*)gesture{
    CGPoint point = [gesture locationInView:gesture.view];
    CGSize size = self.cameraView.bounds.size;
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
