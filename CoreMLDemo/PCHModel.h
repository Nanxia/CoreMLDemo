//
//  PCHModel.h
//  CoreMLDemo
//
//  Created by liao.zq on 29/1/18.
//  Copyright © 2018年 Liaozq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImage+Utils.h"

typedef NS_ENUM(NSInteger, PCHPredictModelClassify) {
    InteriorExteriorModelClassify = 0, // 1500张图片训练结果
    SceneIdentifyModelClassify, // 三大类的训练结果
//    IdentifyPoxModelClassify, // 有痘痘和无痘痘的训练结果
//    IdentifyPoxModelClassify1, // 有痘痘和无痘痘的训练结果1
    IdentifyPoxModelClassify2, // 有痘痘和无痘痘的训练结果2
    ThreeClassifyPoxModelClassify, // 痘痘严重级别的训练结果
    OfficeRestaurantModelClassify, // 办公室和餐厅的训练结果
    FourClassifyModelClassify, // 办公室,餐厅,室内和室外的训练结果
};

@interface PCHModel : NSObject

@property (nonatomic, strong) NSArray *classifyArr;
@property (nonatomic, strong) NSDictionary *labelProbabilityDic;
@property (nonatomic, assign) UIImageOrientation orientation;
@property (nonatomic, assign) BOOL isSwitchCamera, isBackCameraForFirst;
@property (nonatomic, assign) PCHPredictModelClassify modelClassify;

- (PCHCameraState)getCameraState;

- (NSString *)predictImageScene:(CVPixelBufferRef)buffer modelClassify:(PCHPredictModelClassify)modelClassify;

@end
