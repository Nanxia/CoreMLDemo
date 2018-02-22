//
//  ViewController.m
//  CoreMLDemo
//
//  Created by Liaozq on 08/06/2017.
//  Copyright © 2017 Liaozq. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+Utils.h"
#import "PCHModel.h"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer; // 实时显示摄像的区域
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutPut;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInputDevice; // 当前使用的视频设备
@property (nonatomic, strong) AVCaptureDeviceInput *frontCamera; // 前后摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *backCamera;

@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) UIView *realTimeView; // 实时显示的区域容器
@property (nonatomic, strong) UILabel *classifyLabel, *rateLabel;
@property (nonatomic, strong) UIButton *swithBtn, *classifyBtn;
@property (nonatomic, strong) UITableView *tableView;

/** 定时器 */
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *classifyText;

//model
@property (nonatomic, strong) PCHModel *pchModel;

@end

@implementation ViewController

#pragma mark - model

- (PCHModel *)pchModel
{
    if (!_pchModel) {
        _pchModel = [[PCHModel alloc] init];
    }
    return _pchModel;
}

#pragma mark - lifeCycle

- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
    [self initAVCapturWritterConfig];
    [self setUpSubviews];
//    [self setUpTimer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startVideoCapture];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopVideoCapture];
}

- (void)initData
{
    _queue = dispatch_queue_create("CMSampleBufferRef", NULL);
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)initAVCapturWritterConfig
{
    self.session = [[AVCaptureSession alloc] init];
    
    //创建视频设备
    AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    NSArray *videoDevices = devicesIOS10.devices;
    NSLog(@"       %@",videoDevices);
    
    //初始化摄像头
    self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
    self.videoInputDevice = self.backCamera;
    self.pchModel.isBackCameraForFirst = [self.videoInputDevice isEqual:self.backCamera];
    
    
    if ([self.session canAddInput:self.videoInputDevice]) {
        [self.session addInput:self.videoInputDevice];
    }
    
    //视频
    self.videoOutPut = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],(id)kCVPixelBufferPixelFormatTypeKey, nil];
    [self.videoOutPut setVideoSettings:outputSettings];
    if ([self.session canAddOutput:self.videoOutPut]) {
        [self.session addOutput:self.videoOutPut];
    }
    self.videoConnection = [self.videoOutPut connectionWithMediaType:AVMediaTypeVideo];
    self.videoConnection.enabled = NO;
    [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (void)setUpSubviews
{
    // 容器
    self.realTimeView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.realTimeView];
    
    // 实时图像预览
    self.previewLayer.frame = self.realTimeView.frame;
    [self.realTimeView.layer addSublayer:self.previewLayer];
    
    // 分类标签
    self.classifyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 40, self.view.bounds.size.width, 40)];
    self.classifyLabel.textAlignment = NSTextAlignmentCenter;
    self.classifyLabel.font = [UIFont systemFontOfSize:20];
    self.classifyLabel.textColor = [UIColor whiteColor];
    self.classifyLabel.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.classifyLabel];
    
    // 识别率
    self.rateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 40, self.view.bounds.size.width, 40)];
    self.rateLabel.textAlignment = NSTextAlignmentLeft;
    self.rateLabel.font = [UIFont systemFontOfSize:20];
    self.rateLabel.textColor = [UIColor whiteColor];
    self.rateLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.rateLabel];
    
    // 切换摄像头
    self.swithBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.swithBtn setFrame:CGRectMake(self.view.bounds.size.width - 50, self.view.bounds.size.height - 40, 50, 40)];
    [self.swithBtn setTitle:@"切换" forState:UIControlStateNormal];
    [self.swithBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.swithBtn addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.swithBtn];
    
    // 分类开关
    self.classifyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.classifyBtn setFrame:CGRectMake(self.view.bounds.size.width - 50, 20, 50, 40)];
    [self.classifyBtn setTitle:@"分类" forState:UIControlStateNormal];
    [self.classifyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.classifyBtn addTarget:self action:@selector(handlerClassifyBotton:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.classifyBtn];
    
    // 分类列表
//    [self.view addSubview:self.tableView];
}

- (UITableView *)tableView
{
    if (!_tableView) {
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(50, 50, 200, 300) style:UITableViewStylePlain];
        _tableView.center = self.view.center;
        _tableView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
//        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (void)setUpTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateLabel) userInfo:nil repeats:YES];
}

#pragma mark - set

//切换摄像头
- (void)setVideoInputDevice:(AVCaptureDeviceInput *)videoInputDevice
{
    if ([videoInputDevice isEqual:_videoInputDevice]) {
        return;
    }
    //modifyinput
    [self.session beginConfiguration];
    if (_videoInputDevice) {
        [self.session removeInput:_videoInputDevice];
    }
    if (videoInputDevice) {
        [self.session addInput:videoInputDevice];
    }
    
    [self.session commitConfiguration];
    
    _videoInputDevice = videoInputDevice;
}

#pragma mark - notify

- (void)deviceOrientationDidChange:(NSObject *)sender
{
    UIDevice *device = [sender valueForKey:@"object"];
    //    NSLog(@"device.orientation : %ld",device.orientation);
    self.pchModel.orientation = (UIImageOrientation)([self.videoInputDevice isEqual: self.frontCamera]) ? UIImageOrientationUpMirrored : UIImageOrientationUp;
    
    switch (device.orientation) {
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"Device oriented horizontally, home button on the right");
            self.pchModel.orientation = (UIImageOrientation)([self.videoInputDevice isEqual: self.frontCamera]) ? UIImageOrientationLeftMirrored : UIImageOrientationLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"Device oriented horizontally, home button on the left");
            self.pchModel.orientation = (UIImageOrientation)([self.videoInputDevice isEqual: self.frontCamera]) ? UIImageOrientationRightMirrored : UIImageOrientationRight;
            break;
        default:
            NSLog(@"cannot distinguish");
            break;
    }
}

#pragma mark - action

- (void)startVideoCapture
{
    [self.session startRunning];
    self.videoConnection.enabled = YES;
    self.videoQueue = dispatch_queue_create("videoQueue", NULL);
    [self.videoOutPut setSampleBufferDelegate:self queue:self.videoQueue];
}

- (void)stopVideoCapture
{
    [self.videoOutPut setSampleBufferDelegate:nil queue:nil];
    self.videoConnection.enabled = NO;
    self.videoQueue = nil;
    [self.session stopRunning];
}

- (void)switchCamera
{
    if ([self.videoInputDevice isEqual: self.frontCamera]) {
        self.videoInputDevice = self.backCamera;
        self.pchModel.orientation = (UIImageOrientation)(self.pchModel.orientation - 4);
    }else{
        self.videoInputDevice = self.frontCamera;
        self.pchModel.orientation = (UIImageOrientation)(self.pchModel.orientation + 4);
    }
    self.pchModel.isSwitchCamera = YES;
}

- (void)handlerClassifyBotton:(UIButton *)sender
{
    self.tableView.hidden = !sender.selected;
    sender.selected = !sender.selected;
}

- (void)updateLabel
{
    self.classifyLabel.text = self.classifyText;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.pchModel.classifyArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"identifierCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"identifierCell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@",self.pchModel.classifyArr[indexPath.row]];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.pchModel.modelClassify = (PCHPredictModelClassify)indexPath.row;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.queue, ^{
        
        UIImage *tmpImage = [UIImage imageFromSampleBuffer:sampleBuffer withResize:CGSizeMake(227, 227) withOrientation:weakSelf.pchModel.orientation withCameraState:[weakSelf.pchModel getCameraState]];
        NSString *text = [weakSelf predictImageScene:tmpImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.classifyLabel.text = text;
//            weakSelf.classifyText = text;
            weakSelf.rateLabel.text = [NSString stringWithFormat:@"%.2f",[[NSString stringWithFormat:@"%@",weakSelf.pchModel.labelProbabilityDic[text]] floatValue]];
        });
    });
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
   //...
}

- (NSString *)predictImageScene:(UIImage *)image
{
//    NSError *error;
//    CVPixelBufferRef buffer = [UIImage pixelBufferFromImage:image];
//
//    [self.input_ip setImage:buffer];
//    IdentifyPoxModelOutput *output_ip = [self.ipModel predictionFromFeatures:self.input_ip error:&error];
//    //    NSLog(@"--------------------------------: %@",output2_ie.labelProbability);
//    self.pchModel.labelProbabilityDic = output_ip.labelProbability;
//
//    CFRelease(buffer);
//    return output_ip.label;
    
    
    CVPixelBufferRef buffer = [UIImage pixelBufferFromImage:image];
    NSString *tmpStr = [self.pchModel predictImageScene:buffer modelClassify:self.pchModel.modelClassify];
    CFRelease(buffer);
    return tmpStr;
}



@end
