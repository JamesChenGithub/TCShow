//
//  ConstHeader.h
//  TIMChat
//
//  Created by AlexiChen on 16/2/17.
//  Copyright © 2016年 AlexiChen. All rights reserved.
//

#ifndef ConstHeader_h
#define ConstHeader_h

#define kTextRedColor       RGBOF(0xD54A45)

//=========================================================
// CommonLibrary UI样式配置

// 背景色
#define kAppBakgroundColor          RGBOF(0xEFEFF4)

// 导航主色调
#define kNavBarThemeColor             RGBOF(0xDC4B53)


//=========================================================
// CommonLibrary代码开关配置

//=========================================================
// IMSDK相关
// 如果用户在随心播工程上更新了AppID,AccountType，记得将kIsTCShowSupportIMCustom改为0
// 用户更新为自己的app配置
// 以及IMSDK相关的配置
#define kSdkAppId       @"1400001692"
#define kSdkAccountType @"884"

// 用户App(非随心播)改成0
#define kIsTCShowSupportIMCustom 1

#if DEBUG
#define kAVSDKDefaultOpenMic 1
#endif

#define kIsMeasureSpeed 1
#define kSupportILiveSDK 0
//#define kSupportIMMsgCache 0

#define kTCAVLogSwitch 1
//=========================================================

#define kDefaultUserIcon            [UIImage imageNamed:@"default_head@2x.jpg"]
#define kDefaultCoverIcon           [UIImage imageNamed:@"default_cover@2x.jpg"]
#define kDefaultSubGroupIcon        [UIImage imageWithColor:kOrangeColor size:CGSizeMake(32, 32)]


#define kAppLargeTextFont       [UIFont systemFontOfSize:16]
#define kAppMiddleTextFont      [UIFont systemFontOfSize:14]
#define kAppSmallTextFont       [UIFont systemFontOfSize:12]

// 是否支持直播界面，上下swipe手势，切换直播间
// 使用时，请确保列表中有两个可用的直播间信息
#define kSupportSwitchRoom  1

// 是否支持互动直播
// 为0时，只显示直播，为1时直播与互动都显示
#define kSupportMultiLive 1

//渲染界面旋转模式
//自动校正:      ILiveRotation_Auto = 0,
//始终全屏显示:   ILiveRotation_FullScreen = 1,
//剪裁校正:      ILiveRotation_Crop = 2,

#define kAVGLCustomRenderViewRotateMode 1

#endif /* ConstHeader_h */
