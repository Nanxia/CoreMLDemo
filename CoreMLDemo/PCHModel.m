//
//  PCHModel.m
//  CoreMLDemo
//
//  Created by liao.zq on 29/1/18.
//  Copyright © 2018年 Liaozq. All rights reserved.
//

#import "PCHModel.h"
#import "Interior_Exterior_Model2.h"
#import "SceneIdentifyModel.h"
#import "IdentifyPoxModel.h"
#import "IdentifyPoxModel1.h"
#import "IdentifyPoxModel2.h"
#import "three_classify_pox_model.h"
#import "OfficeRestaurantModel.h"
#import "FourClassifyModel.h"

@interface PCHModel ()

//Interior_Exterior_Model1 ：1500张图片训练结果
@property (nonatomic, strong) Interior_Exterior_Model2 *ieModel2;
@property (nonatomic, strong) Interior_Exterior_Model2Input *input2_ie;
@property (nonatomic, strong) Interior_Exterior_Model2Output *output2_ie;

//SceneIdentifyModel ：三大类的训练结果
@property (nonatomic, strong) SceneIdentifyModel *siModel;
@property (nonatomic, strong) SceneIdentifyModelInput *input_si;
@property (nonatomic, strong) SceneIdentifyModelOutput *output_si;

//IdentifyPoxModel ：有痘痘和无痘痘的训练结果
@property (nonatomic, strong) IdentifyPoxModel *ipModel;
@property (nonatomic, strong) IdentifyPoxModelInput *input_ip;
@property (nonatomic, strong) IdentifyPoxModelOutput *output_ip;

//IdentifyPoxModel1 ：有痘痘和无痘痘的训练结果1
@property (nonatomic, strong) IdentifyPoxModel1 *ipModel1;
@property (nonatomic, strong) IdentifyPoxModel1Input *input_ip1;
@property (nonatomic, strong) IdentifyPoxModel1Output *output_ip1;

//IdentifyPoxModel2 ：有痘痘和无痘痘的训练结果2
@property (nonatomic, strong) IdentifyPoxModel2 *ipModel2;
@property (nonatomic, strong) IdentifyPoxModel2Input *input_ip2;
@property (nonatomic, strong) IdentifyPoxModel2Output *output_ip2;

//IdentifyPoxModel ：痘痘严重级别的训练结果
@property (nonatomic, strong) three_classify_pox_model *poxModel;
@property (nonatomic, strong) three_classify_pox_modelInput *input_pox;
@property (nonatomic, strong) three_classify_pox_modelOutput *output_pox;

//OfficeRestaurantModel ：办公室和餐厅的训练结果
@property (nonatomic, strong) OfficeRestaurantModel *orModel;
@property (nonatomic, strong) OfficeRestaurantModelInput *input_or;
@property (nonatomic, strong) OfficeRestaurantModelOutput *output_or;

//FourClassifyModel  ：办公室,餐厅,室内和室外的训练结果
@property (nonatomic, strong) FourClassifyModel *fourModel;
@property (nonatomic, strong) FourClassifyModelInput *input_four;
@property (nonatomic, strong) FourClassifyModelOutput *output_four;

@property (nonatomic, strong) NSString *classLabel;
@property (nonatomic, assign) NSInteger addNum;

@end

@implementation PCHModel

#pragma mark -- init

- (instancetype)init
{
    if (self = [super init]) {
        _addNum = 0;
        _classLabel = @"室内";
        _isSwitchCamera = NO;
        _isBackCameraForFirst = YES;
        _labelProbabilityDic = [NSDictionary dictionary];
        _classifyArr = @[@"室内室外分类",@"室内室外聚餐分类",@"有无痘痘分类2",@"痘痘严重程度分类",@"办公室和餐厅分类",@"办公室,餐厅,室内和室外分类"];//,@"有无痘痘分类",@"有无痘痘分类1"
    }
    return self;
}

#pragma mark -- extension

- (PCHCameraState)getCameraState
{
    PCHCameraState cameraState = PCHBackCameraState;
    
    if (self.isBackCameraForFirst && !self.isSwitchCamera) {
        cameraState = PCHBackCameraState;
    }
    else if (!self.isBackCameraForFirst && !self.isSwitchCamera){
        cameraState = PCHFrontCameraState;
    }
    else if (self.isBackCameraForFirst && self.isSwitchCamera){
        cameraState = PCHBackAfterSwitchCameraState;
    }
    else if (!self.isBackCameraForFirst && self.isSwitchCamera){
        cameraState = PCHFrontAfterSwitchCameraState;
    }
    
    return cameraState;
}

- (NSString *)predictImageScene:(CVPixelBufferRef)buffer modelClassify:(PCHPredictModelClassify)modelClassify
{
    NSError *error;
    NSString *predictLabel;
    
//    switch (modelClassify) {
//        case InteriorExteriorModelClassify:
//        {
//            [self.input_si setImage:buffer];
//            SceneIdentifyModelOutput *output_si = [self.siModel predictionFromFeatures:self.input_si error:&error];
//            predictLabel = output_si.label;
//            self.labelProbabilityDic = output_si.labelProbability;
//        }
//            break;
//        case SceneIdentifyModelClassify:
//        {
//            [self.input2_ie setImage:buffer];
//            Interior_Exterior_Model2Output *output2_ie = [self.ieModel2 predictionFromFeatures:self.input2_ie error:&error];
//            predictLabel = output2_ie.label;
//            self.labelProbabilityDic = output2_ie.labelProbability;
//        }
//            break;
////        case IdentifyPoxModelClassify:
////        {
////            [self.input_ip setImage:buffer];
////            IdentifyPoxModelOutput *output_ip = [self.ipModel predictionFromFeatures:self.input_ip error:&error];
////            predictLabel = output_ip.label;
////            self.labelProbabilityDic = output_ip.labelProbability;
////        }
////            break;
////        case IdentifyPoxModelClassify1:
////        {
////            [self.input_ip1 setImage:buffer];
////            IdentifyPoxModel1Output *output_ip1 = [self.ipModel1 predictionFromFeatures:self.input_ip1 error:&error];
////            predictLabel = output_ip1.label;
////            self.labelProbabilityDic = output_ip1.labelProbability;
////        }
////            break;
//        case IdentifyPoxModelClassify2:
//        {
//            [self.input_ip2 setImage:buffer];
//            IdentifyPoxModel2Output *output_ip2 = [self.ipModel2 predictionFromFeatures:self.input_ip2 error:&error];
//            predictLabel = output_ip2.label;
//            self.labelProbabilityDic = output_ip2.labelProbability;
//        }
//            break;
//        case ThreeClassifyPoxModelClassify:
//        {
//            [self.input_pox setImage:buffer];
//            three_classify_pox_modelOutput *output_pox = [self.poxModel predictionFromFeatures:self.input_pox error:&error];
//            predictLabel = output_pox.label;
//            self.labelProbabilityDic = output_pox.labelProbability;
//        }
//            break;
//        case OfficeRestaurantModelClassify:
//        {
//            [self.input_or setImage:buffer];
//            OfficeRestaurantModelOutput *output_or = [self.orModel predictionFromFeatures:self.input_or error:&error];
//            predictLabel = output_or.label;
//            self.labelProbabilityDic = output_or.labelProbability;
//        }
//            break;
//        case FourClassifyModelClassify:
//        {
//            [self.input_four setImage:buffer];
//            FourClassifyModelOutput *output_four = [self.fourModel predictionFromFeatures:self.input_four error:&error];
//            predictLabel = output_four.label;
//            self.labelProbabilityDic = output_four.labelProbability;
//        }
//            break;
//        default:
//            break;
//    }
    
    [self.input_four setImage:buffer];
    FourClassifyModelOutput *output_four = [self.fourModel predictionFromFeatures:self.input_four error:&error];
    predictLabel = [self filterClassifyLabelWith:output_four.label];
    self.labelProbabilityDic = output_four.labelProbability;
    
    NSLog(@"--------------------------------: %@",predictLabel);
    
    return predictLabel;
}

- (NSString *)filterClassifyLabelWith:(NSString *)label
{
    // 10
    if (self.classLabel != label && self.addNum > 20) { // 不同
        self.classLabel = label;
        self.addNum = 0;
    }
    else if(self.addNum < 100) { //相同
        self.addNum++;
    }
    
//    NSLog(@"--------------------------------: %ld",self.addNum);
    return self.classLabel;
}


#pragma mark -- model

//Interior_Exterior_Model1 ：1500张图片训练结果
- (Interior_Exterior_Model2 *)ieModel2
{
    if (!_ieModel2) {
        _ieModel2 = [[Interior_Exterior_Model2 alloc] init];
    }
    return _ieModel2;
}

- (Interior_Exterior_Model2Input *)input2_ie
{
    if (!_input2_ie) {
        CVPixelBufferRef pixel_buffer = NULL;
        _input2_ie = [[Interior_Exterior_Model2Input alloc] initWithImage:pixel_buffer];
    }
    return _input2_ie;
}

//SceneIdentifyModel ：三大类的训练结果
- (SceneIdentifyModel *)siModel
{
    if (!_siModel) {
        _siModel = [[SceneIdentifyModel alloc] init];
    }
    return _siModel;
}

- (SceneIdentifyModelInput *)input_si
{
    if (!_input_si) {
        CVPixelBufferRef pixel_buffer = NULL;
        _input_si = [[SceneIdentifyModelInput alloc] initWithImage:pixel_buffer];
    }
    return _input_si;
}

//IdentifyPoxModel ：有痘痘和无痘痘的训练结果
- (IdentifyPoxModel *)ipModel
{
    if (!_ipModel) {
        _ipModel = [[IdentifyPoxModel alloc] init];
    }
    return _ipModel;
}

- (IdentifyPoxModelInput *)input_ip
{
    if (!_input_ip) {
        CVPixelBufferRef pixel_buffer = NULL;
        _input_ip = [[IdentifyPoxModelInput alloc] initWithImage:pixel_buffer];
    }
    return _input_ip;
}

//IdentifyPoxModel1 ：有痘痘和无痘痘的训练结果1
- (IdentifyPoxModel1 *)ipModel1
{
    if (!_ipModel1) {
        _ipModel1 = [[IdentifyPoxModel1 alloc] init];
    }
    return _ipModel1;
}

- (IdentifyPoxModel1Input *)input_ip1
{
    if (!_input_ip1) {
        CVPixelBufferRef pixel_buffer = NULL;
        _input_ip1 = [[IdentifyPoxModel1Input alloc] initWithImage:pixel_buffer];
    }
    return _input_ip1;
}

//IdentifyPoxModel2 ：有痘痘和无痘痘的训练结果2
- (IdentifyPoxModel2 *)ipModel2
{
    if (!_ipModel2) {
        _ipModel2 = [[IdentifyPoxModel2 alloc] init];
    }
    return _ipModel2;
}

- (IdentifyPoxModel2Input *)input_ip2
{
    if (!_input_ip2) {
        CVPixelBufferRef pixel_buffer = NULL;
        _input_ip2 = [[IdentifyPoxModel2Input alloc] initWithImage:pixel_buffer];
    }
    return _input_ip2;
}

//IdentifyPoxModel ：痘痘严重级别的训练结果
- (three_classify_pox_model *)poxModel
{
    if (!_poxModel) {
        _poxModel = [[three_classify_pox_model alloc] init];
    }
    return _poxModel;
}

- (three_classify_pox_modelInput *)input_pox
{
    if (!_input_pox) {
        CVPixelBufferRef pixel_buffer = NULL;
        _input_pox = [[three_classify_pox_modelInput alloc] initWithImage:pixel_buffer];
    }
    return _input_pox;
}

//OfficeRestaurantModel ：办公室和餐厅的区别
- (OfficeRestaurantModel *)orModel
{
    if (!_orModel) {
        _orModel = [[OfficeRestaurantModel alloc] init];
    }
    return _orModel;
}

- (OfficeRestaurantModelInput *)input_or
{
    if (!_input_or) {
        CVPixelBufferRef pixel_buffer = NULL;
        _input_or = [[OfficeRestaurantModelInput alloc] initWithImage:pixel_buffer];
    }
    return _input_or;
}

//FourClassifyModel  ：办公室,餐厅,室内和室外的训练结果
- (FourClassifyModel *)fourModel
{
    if (!_fourModel) {
        _fourModel = [[FourClassifyModel alloc] init];
    }
    return _fourModel;
}

- (FourClassifyModelInput *)input_four
{
    if (!_input_four) {
        CVPixelBufferRef pixel_buffer = NULL;
        _input_four = [[FourClassifyModelInput alloc] initWithImage:pixel_buffer];
    }
    return _input_four;
}

@end
