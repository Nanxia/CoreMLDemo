//
//  UIImage+Utils.h
//  CoreMLDemo
//
//  Created by Liaozq on 08/06/2017.
//  Copyright © 2017 Liaozq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, PCHCameraState) {
    PCHBackCameraState = 0,         // 初始为后置摄像头
    PCHFrontCameraState,            // 初始为前置摄像头
    PCHBackAfterSwitchCameraState,  // 初始为后置摄像头,切换了一次摄像头后
    PCHFrontAfterSwitchCameraState, // 初始为前置摄像头,切换了一次摄像头后
};

@interface UIImage (Utils)

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer withResize:(CGSize)size withOrientation:(UIImageOrientation)orientation withCameraState:(PCHCameraState)cameraState;

/**
    resize image
 */
- (UIImage *)scaleToSize:(CGSize)size;

/**
    CMSampleBufferRef => UIImage
 */
+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
    fixOrientation 修正图片方向
 */
- (UIImage *)fixOrientation:(UIImageOrientation)orientation withCameraState:(PCHCameraState)cameraState;

/**
     UIImage => CVPixelBufferRef
 */
+ (CVPixelBufferRef)pixelBufferFromImage:(UIImage *)originImage;

/**
     CVPixelBufferRef => UIImage
 **/
+ (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef;

@end
