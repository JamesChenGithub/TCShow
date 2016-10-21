//
//  LiveViewController.h
//  TCShow
//
//  Created by AlexiChen on 16/9/26.
//  Copyright © 2016年 AlexiChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LiveViewController : UIViewController<TCILiveManagerDelegate, TCShowLiveTopViewDelegate, TCShowLiveTimeViewDelegate, TCShowLiveBottomViewDelegate, TCShowLiveBottomViewMultiDelegate, TCShowMultiViewDelegate>
{
@protected
    UITextView                  *_parTextView;
    
@protected
    TCShowLiveTopView           *_topView;
    
    TCShowMultiView             *_multiView;
    
    
    TCShowLiveMessageView       *_msgView;
    TCShowLiveBottomView        *_bottomView;
    
    TCShowLiveInputView         *_inputView;
    BOOL                         _inputViewShowing;
    
    NSTimer                     *_refreshTimer;
}

@property (nonatomic, strong) TCShowLiveListItem *roomInfo;
@property (nonatomic, strong) TCShowHost *currentUser;


- (instancetype)initWith:(TCShowLiveListItem *)info user:(TCShowHost *)user;

@end
