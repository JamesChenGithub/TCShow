//
//  LiveViewController.m
//  TCShow
//
//  Created by AlexiChen on 16/9/26.
//  Copyright © 2016年 AlexiChen. All rights reserved.
//

#import "LiveViewController.h"

@interface LiveViewController () <TCILiveMsgHandlerListener, TCShowMultiUserListViewDelegate, TIMMessageListener>
{
    NSTimer             *_heartTimer;
    
    __weak TCILiveMsgHandler *_msgHandler;
    
    
    NSMutableDictionary *_interactUserDic;
}

@property (nonatomic, readonly) BOOL isPureMode;
@property (nonatomic, assign) BOOL isPostLiveStart;
@property (nonatomic, assign) BOOL isExiting;
@property (nonatomic, assign) BOOL isHost;

@end

@implementation LiveViewController

- (void)dealloc
{
    DebugLog(@"%@ : %p release", [self class], self);
    [self removeObservers];
    self.navigationController.navigationBarHidden = NO;
    [[TCILiveManager sharedInstance] exitRoom:nil];
}

- (instancetype)initWith:(TCShowLiveListItem *)info user:(TCShowHost *)user
{
    if (self = [super init])
    {
        self.roomInfo = info;
        self.currentUser = user;
        
        // 直播时，更换监听者
        // 直播结束时，再把监听者改成IMAPlatform
        //        [[TIMManager sharedInstance] setUserStatusListener:self];
    }
    return self;
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    
    if (!_isHost)
    {
        //添加键盘监听
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardDidShow:) name:UIKeyboardDidChangeFrameNotification object:nil];
        
    }
    
}

#pragma mark - notification handler

#pragma mark -
#pragma mark Responding to keyboard events
- (void)onKeyboardDidShow:(NSNotification *)notification
{
    if ([_inputView isInputViewActive])
    {
        NSDictionary *userInfo = [notification userInfo];
        NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGRect keyboardRect = [aValue CGRectValue];
        NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        NSTimeInterval animationDuration;
        [animationDurationValue getValue:&animationDuration];
        
        
        [UIView animateWithDuration:animationDuration animations:^{
            CGFloat ky = keyboardRect.origin.y;
            
            CGRect rect = _bottomView.frame;
            rect = CGRectInset(rect, 0, 10);
            rect.origin.y = ky - rect.size.height - (keyboardRect.origin.y + keyboardRect.size.height - self.view.bounds.size.height);
            _inputView.frame = rect;
            _inputView.backgroundColor = kRedColor;
            [_msgView scaleToAboveOf:_inputView margin:kDefaultMargin];
        }];
    }
}

- (void)onKeyboardWillHide:(NSNotification *)notification
{
    if (![_inputView isInputViewActive])
    {
        NSDictionary* userInfo = [notification userInfo];
        
        NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        NSTimeInterval animationDuration;
        [animationDurationValue getValue:&animationDuration];
        
        
        [UIView animateWithDuration:animationDuration animations:^{
            [_inputView alignParentBottomWithMargin:10];
            [_msgView scaleToAboveOf:_bottomView margin:kDefaultMargin];
        }];
    }
}

- (void)onAppEnterForeground
{
    [[TCILiveManager sharedInstance] onEnterForeground];
}

- (void)onAppEnterBackground
{
    [[TCILiveManager sharedInstance] onEnterBackground];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    TCILiveManager *mgr = [TCILiveManager sharedInstance];
    _isHost = [mgr isHostLive];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = !_isHost;
    
    
    [self addObservers];
    
    [mgr createAVGLViewIn:self];
    
    
    //    CGRect rect = view.bounds;
    //    TCIMemoItem *item0 = [[TCIMemoItem alloc] initWith:[[_roomInfo liveHost] imUserId] showRect:rect];
    //
    //    TCIMemoItem *item1 = [[TCIMemoItem alloc] initWithShowRect:CGRectMake(rect.size.width - 100, 90, 90, 120)];
    //    TCIMemoItem *item2 = [[TCIMemoItem alloc] initWithShowRect:CGRectMake(rect.size.width - 100, 220, 90, 120)];
    //    TCIMemoItem *item3 = [[TCIMemoItem alloc] initWithShowRect:CGRectMake(rect.size.width - 100, 350, 90, 120)];
    //    [mgr registerRenderMemo:@[item0, item1, item2, item3]];
    
    [mgr addRenderFor:mgr.room.liveHostID atFrame:self.view.bounds];
    //    [[TCILiveManager sharedInstance] addRenderFor:@"1231212" atFrame:CGRectMake(50, 50, 90, 120)];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self addOwnViews];
    
    if (!_isHost)
    {
        [mgr sendGroupCustomMsg:TCILiveCMD_EnterLive actionParam:nil succ:nil fail:nil];
    }
    
    _msgHandler = [mgr setAutoHandleMsgListener:self refreshInterval:1];
    [_msgHandler registerMsgClass:[TCShowLiveMsg class]];
    [self postLiveStart];
    
    [[TIMManager sharedInstance] setMessageListener:self];
    
    [self layoutOnIPhone];
    
    _interactUserDic = [NSMutableDictionary dictionaryWithCapacity:4];
    
    if (!_isHost)
    {
        [_interactUserDic setObject:[_roomInfo liveHost] forKey:[[_roomInfo liveHost] imUserId]];
    }
}

- (void)onNewMessage:(NSArray *)msgs
{
    [[TCILiveManager sharedInstance] filterCurrentLiveMessageInNewMessages:msgs];
}

- (void)startLiveTimer
{
    [_heartTimer invalidate];
    _heartTimer = nil;
    _heartTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(onPostHeartBeat) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_heartTimer forMode:NSRunLoopCommonModes];
    
    [_topView startLive];
}


- (void)startMyLive
{
    [self startLiveTimer];
}

- (void)onPostHeartBeat
{
    if ([IMAPlatform sharedInstance].isConnected)
    {
        LiveHostHeartBeatRequest *req = [[LiveHostHeartBeatRequest alloc] initWithHandler:nil failHandler:^(BaseRequest *request) {
            // 上传心跳失败
            DebugLog(@"上传心跳失败");
        }];
        req.liveItem = _roomInfo;
        [[WebServiceEngine sharedEngine] asyncRequest:req wait:NO];
    }
}

- (void)exitLive
{
    [_heartTimer invalidate];
    _heartTimer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    __weak typeof(self) ws = self;
    [[TCILiveManager sharedInstance] exitRoom:^(BOOL succ, NSError *err) {
        [ws uiEndLive];
    }];
}

- (void)uiEndLive
{
    if (self.isPostLiveStart)
    {
        [_heartTimer invalidate];
        _heartTimer = nil;
        
        [_topView pauseLive];
        
        TCAVIMLog(@"主播退出直播间上报开始");
        
        __weak typeof(self) ws = self;
        if ([IMAPlatform sharedInstance].isConnected)
        {
            LiveEndRequest *req = [[LiveEndRequest alloc] initWithHandler:^(BaseRequest *request) {
                
                TCAVIMLog(@"主播退出直播间成功回调时间");
                // 上传成功，界面开始计时
                LiveEndResponseData *rec = (LiveEndResponseData *)request.response.data;
                [ws showLiveResult:rec.record];
            } failHandler:^(BaseRequest *request) {
                TCAVIMLog(@"主播退出直播间失败回调时间");
                [ws showLiveResult:ws.roomInfo];
            }];
            req.liveItem = _roomInfo;
            [[WebServiceEngine sharedEngine] asyncRequest:req wait:YES];
        }
        else
        {
            [ws showLiveResult:_roomInfo];
        }
        
        self.isPostLiveStart = NO;
    }
    else
    {
        self.isPostLiveStart = NO;
        [self exitLiveUI];
    }
}

- (void)exitLiveUI
{
    [[TIMManager sharedInstance] setMessageListener:nil];
//    [self dismissViewControllerAnimated:YES completion:nil];
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)showLiveResult:(TCShowLiveListItem *)item
{
    
    __weak typeof(self) ws = self;
    TCShowLiveResultView *resultview = [[TCShowLiveResultView alloc] initWith:item completion:^(id<MenuAbleItem> menu) {
        [ws exitLiveUI];
    }];
    [self.view addSubview:resultview];
    [resultview setFrameAndLayout:self.view.bounds];
    
#if kSupportFTAnimation
    [resultview fadeIn:0.3 delegate:nil];
#endif
}

- (void)alertExitLive
{
    if (_isExiting)
    {
        return;
    }
    _isExiting = YES;
    if (_isHost)
    {
        UIAlertView *alert =  [UIAlertView bk_showAlertViewWithTitle:nil message:@"当前正在直播，是否退出直播" cancelButtonTitle:@"继续" otherButtonTitles:@[@"确定"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1)
            {
                [self exitLive];
            }
            else
            {
                _isExiting = NO;
            }
            
        }];
        [alert show];
    }
    else
    {
        UIAlertView *alert =  [UIAlertView bk_showAlertViewWithTitle:nil message:@"退出直播" cancelButtonTitle:@"取消" otherButtonTitles:@[@"确定"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1)
            {
                [self exitLive];
            }
            else
            {
                _isExiting = NO;
            }
            
        }];
        [alert show];
        
    }
}

- (void)postLiveStart
{
    if (_isHost)
    {
        __weak typeof(self) ws = self;
        LiveStartRequest *req = [[LiveStartRequest alloc] initWithHandler:^(BaseRequest *request) {
            DebugLog(@"主播进入直播间上报开始成功回调");
            // 上传成功，界面开始计时
            ws.isPostLiveStart = YES;
            
            [ws startMyLive];
            
        } failHandler:^(BaseRequest *request) {
            // 上传失败
            [[HUDHelper sharedInstance] tipMessage:[[request response] message] delay:2 completion:^{
                DebugLog(@"主播进入直播间上报失败回调");
                [ws alertExitLive];
            }];
        }];
        req.liveItem = _roomInfo;
        [[WebServiceEngine sharedEngine] asyncRequest:req wait:NO];
    }
}

- (void)addOwnViews
{
    
    _parTextView = [[UITextView alloc] init];
    _parTextView.hidden = YES;
    _parTextView.backgroundColor = [kLightGrayColor colorWithAlphaComponent:0.5];
    _parTextView.editable = NO;
    [self.view addSubview:_parTextView];
    
    _multiView = [[TCShowMultiView alloc] init];
    _multiView.delegate = self;
    [self.view addSubview:_multiView];
    
    _topView = [[TCShowMultiLiveTopView alloc] initWith:_roomInfo];
    _topView.timeView.delegate = self;
    _topView.delegate = self;
    [self.view addSubview:_topView];
    
    _msgView = [[TCShowLiveMessageView alloc] init];
    [self.view addSubview:_msgView];
    //
    _bottomView = [[TCShowLiveBottomView alloc] init];
    _bottomView.delegate = self;
    [self.view addSubview:_bottomView];
    
    BOOL isHost = [[TCILiveManager sharedInstance] isHostLive];
    //    TCIMemoItem *item = [[TCILiveManager sharedInstance] getItemOf:[_roomInfo.liveHost imUserId]];
    [_bottomView changeTo:ETCShowLiveBottom_Host isHost:isHost isPure:NO];
    
    _inputView = [[TCShowLiveInputView alloc] init];
    _inputView.limitLength = 32;
    _inputView.hidden = YES;
    
    __weak typeof(self) ws = self;
    [_inputView addSendAction:^(id selfptr) {
        [ws sendMessage];
    }];
    
    [self.view addSubview:_inputView];
    //
    //
    //    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBlank:)];
    //    tap.numberOfTapsRequired = 1;
    //    tap.numberOfTouchesRequired = 1;
    //    [_msgView addGestureRecognizer:tap];
    
}

- (void)sendMessage
{
    NSString *msg = [_inputView.text trim];
    if (msg.length == 0)
    {
        [[HUDHelper sharedInstance] tipMessage:@"内容不能为空"];
        return;
    }
    
    NSString *text = _inputView.text;
    __weak typeof(_msgHandler) wm = _msgHandler;
    [[TCILiveManager sharedInstance] sendGroupTextMsg:text succ:^{
        [wm onRecvGroupSender:[IMAPlatform sharedInstance].host.profile textMsg:text];
    } fail:nil];
    [_inputView resignFirstResponder];
    [self showActionPanel];
    
    
}

- (void)showActionPanel
{
    if (_inputView.hidden)
    {
        return;
    }
    
    _inputView.text = nil;
    [_inputView resignFirstResponder];
    
#if kSupportFTAnimation
    [_inputView fadeOut:0.3 delegate:nil];
    [_bottomView fadeIn:0.3 delegate:nil];
#else
    _inputView.hidden = YES;
    _bottomView.hidden = NO;
#endif
    
}


- (void)layoutOnIPhone
{
    CGRect rect = self.view.bounds;
    [_topView setFrameAndLayout:CGRectMake(0, 0, rect.size.width, 110)];
    
    CGSize subViewSize = kTCInteractSubViewSize;
    [_multiView sizeWith:CGSizeMake(subViewSize.width, kDefaultMargin)];
    [_multiView layoutBelow:_topView];
    [_multiView alignParentRightWithMargin:kDefaultMargin];
    [_multiView relayoutFrameOfSubViews];
    _multiView.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.3];
    
    [_bottomView sizeWith:CGSizeMake(rect.size.width, 60)];
    [_bottomView alignParentBottomWithMargin:0];
    [_bottomView relayoutFrameOfSubViews];
    _bottomView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
    
    [_inputView sameWith:_bottomView];
    [_inputView shrinkVertical:10];
    [_inputView relayoutFrameOfSubViews];
    
    [_msgView sizeWith:CGSizeMake((NSInteger)(rect.size.width * 0.7), 210)];
    [_msgView layoutBelow:_topView margin:kDefaultMargin];
    [_msgView scaleToAboveOf:_bottomView margin:kDefaultMargin];
    [_msgView relayoutFrameOfSubViews];
    _msgView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    
    [_parTextView sameWith:_topView];
    [_parTextView layoutBelow:_topView margin:kDefaultMargin];
    [_parTextView scaleToAboveOf:_bottomView margin:kDefaultMargin];
    _parTextView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
}



///////////////////////////////////////////////////////////

- (void)onTopViewCloseLive:(TCShowLiveTopView *)topView
{
    [self alertExitLive];
}

- (void)onTopViewClickHost:(TCShowLiveTopView *)topView host:(id<IMUserAble>)host
{
    // 显示主播信息
    UserProfileView *view = [[UserProfileView alloc] init];
    [self.view addSubview:view];
    [view setFrameAndLayout:self.view.bounds];
    [view showUser:host];
}

// for 互动直播
- (void)onTopViewClickInteract:(TCShowLiveTopView *)topView
{
    //
    if ([[IMAPlatform sharedInstance].host isCurrentLiveHost:_roomInfo])
    {
        // TODO: 目前接口暂不支持拉取指定数量的用户
        __weak id<IMUserAble> wu = [_roomInfo liveHost];
        NSString *groupid = [_roomInfo liveIMChatRoomId];
        __weak typeof(self) ws = self;
        [[TIMGroupManager sharedInstance] GetGroupMembers:groupid succ:^(NSArray *members) {
            NSMutableArray *array = [NSMutableArray array];
            for (TIMGroupMemberInfo *mem in members)
            {
                [array addObject:[mem imUserId]];
            }
            
            [[TIMFriendshipManager sharedInstance] GetUsersProfile:array succ:^(NSArray *friends) {
                NSMutableArray *array = [NSMutableArray array];
                for (TIMUserProfile *u in friends)
                {
                    // 过滤掉主播
                    if (![[u imUserId] isEqualToString:[wu imUserId]])
                    {
                        [array addObject:u];
                    }
                    
                    if (array.count == 32)
                    {
                        break;
                    }
                }
                
                [ws showInteractUserView:array];
            } fail:^(int code, NSString *msg) {
                [[HUDHelper sharedInstance] tipMessage:@"没有人在直播间"];
            }];
            
        } fail:^(int code, NSString *msg) {
            [[HUDHelper sharedInstance] tipMessage:@"没有人在直播间"];
        }];
    }
    
}

- (void)showInteractUserView:(NSArray *)members
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (members.count)
        {
            TCShowMultiUserListView *userView = [[TCShowMultiUserListView alloc] initWith:members];
            userView.delegate = self;
            [self.view addSubview:userView];
            [userView setFrameAndLayout:self.view.bounds];
            [userView show];
        }
    });
}

- (BOOL)forcedCancelInteractUser:(id<AVMultiUserAble>)user
{
//
    // 检查是否有该用户在互动
    id<AVMultiUserAble> iu = [_interactUserDic objectForKey:[user imUserId]];
    if (!iu)
    {
        DebugLog(@"%@ 没有在互动中", [user imUserId]);
        return NO;
    }
    
    id<IMUserAble> liveHost = [_roomInfo liveHost];
    id<IMUserAble> curHost = [IMAPlatform sharedInstance].host;
    
    // 主播收到
    if ([[iu imUserId] isEqualToString:[liveHost imUserId]])
    {
        // 主播不能自己取消自己的互动
        DebugLog(@"逻辑错误：主播收到取消互动的消息，而且操作的是自己");
        return NO;
    }
    // 当前用户收到
    else
    {
        // 移除
        [_interactUserDic removeObjectForKey:[user imUserId]];
        
        // 取消请求画面
        [_roomEngine asyncCancelRequestViewOf:iu];
        
        if ([[iu imUserId] isEqualToString:[_mainUser imUserId]])
        {
            // 如果是主界面被移移
            // 找到主播的画面
            DebugLog(@"主屏幕画面用户取消互动");
            id<AVMultiUserAble> ih = [self interactUserOfID:[liveHost imUserId]];
            
            if (!ih)
            {
                // 连主播的画面都没有
                if ([_multiResource count] >= 1)
                {
                    ih = [_multiResource objectAtIndex:0];
                }
                else
                {
                    // 没有画面显示
                    ih = iu;
                }
            }
            
            if (ih != iu)
            {
                [_preview replaceRender:iu withUser:ih];
                // 更新mainuser
                _mainUser = ih;
            }
            else
            {
                [_preview removeRenderOf:iu];
                // TODO:下面这句有可能会有影响
                _mainUser = nil;
            }
            
            // 回收窗口
            if ([_multiDelegate respondsToSelector:@selector(onAVIMMIMManager:recycleWindowResourceOf:)])
            {
                [_multiDelegate onAVIMMIMManager:self recycleWindowResourceOf:ih];
            }
            
        }
        else
        {
            [_preview removeRenderOf:iu];
            
            // 回收窗口
            if ([_multiDelegate respondsToSelector:@selector(onAVIMMIMManager:recycleWindowResourceOf:)])
            {
                [_multiDelegate onAVIMMIMManager:self recycleWindowResourceOf:iu];
            }
            
        }
        
        if ([[iu imUserId] isEqualToString:[curHost imUserId]])
        {
            // 断开自己的资源信息
            [_roomEngine asyncEnableCamera:NO needNotify:NO];
            //            [_roomEngine disableHostCtrlState:EAVCtrlState_Mic];
            
            [_roomEngine asyncEnableMic:NO completion:nil];
            //            [_roomEngine disableHostCtrlState:EAVCtrlState_Camera];
            
            // 不处理Speaker
            // [_roomEngine asyncEnableSpeaker:NO completion:nil];
            
            [self changeToNormalGuestAuthAndRole:^(id selfPtr, BOOL isFinished) {
                DebugLog(@"修改Auth以及Role到普通观众%@", isFinished ? @"成功" : @"失败");
            }];
        }
        
        
    }
    
    // 更新界面上渲染的窗口位置
    DebugLog(@"取消 %@ 互动成功", [iu imUserId]);
    [_preview updateAllRenderOf:_multiResource];
    return YES;
    
}

- (void)onUserListView:(TCShowMultiUserListView *)view clickUser:(id<AVMultiUserAble>)user
{
    // TODO: 检查是否是互动观众，如果不是，发送邀请，是的话断开
    if ([_interactUserDic objectForKey:[user imUserId]])
    {
        
        
        BOOL succ = [self forcedCancelInteractUser:user];
        if (succ)
        {
            [TCILiveManager sharedInstance] sendGroupCustomMsg:AVIMCMD_Multi_CancelInteract actionParam:[user imUserId] succ:^{
                DebugLog(@"发送消息取消与(%@)互动消息成功", [user imUserId]);
            } fail:^(int code, NSString *msg) {
                DebugLog(@"发送消息取消与(%@)互动消息失败", [user imUserId]);
            }];
        }

    }
    else
    {
        __weak typeof(_interactUserDic) dic = _interactUserDic;
        __weak typeof(self) ws = self;
        [[TCILiveManager sharedInstance] sendC2CCustomMsg:[user imUserId] action:AVIMCMD_Multi_Host_Invite actionParam:nil succ:^{
            [dic setObject:user forKey:[user imUserId]];
            [ws requestVideoOf:user];
        } fail:^(int code, NSString *msg) {
            [[HUDHelper sharedInstance] tipMessage:@"邀请上麦失败"];
        }];
    }
}

- (BOOL)onUserListView:(TCShowMultiUserListView *)view isInteratcUser:(id<AVMultiUserAble>)user
{
    return [_interactUserDic objectForKey:[user imUserId]] != nil;
}

//@optional
- (void)onTopView:(TCShowLiveTopView *)topView clickPAR:(UIButton *)par
{
    par.selected = !par.selected;
    _parTextView.hidden = !par.selected;
}

- (void)onTopView:(TCShowLiveTopView *)topView clickPush:(UIButton *)par
{
    if (par.selected)
    {
        
        [[TCILiveManager sharedInstance] asyncStopAllPushStreamWithSucc:^{
            par.selected = !par.selected;
        } fail:^(int code, NSString *err) {
            par.selected = !par.selected;
        }];
    }
    else
    {
        //        __weak TCAVLiveRoomEngine *wr = (TCAVLiveRoomEngine *)_roomEngine;
        __weak typeof(self) ws = self;
        __weak typeof(TCShowLiveListItem *) wroom = (TCShowLiveListItem *)_roomInfo;
        
        UIActionSheet *testSheet = [[UIActionSheet alloc] init];//[UIActionSheet bk_actionSheetWithTitle:@"请选择照片源"];
        [testSheet bk_addButtonWithTitle:@"HLS推流" handler:^{
            [[TCILiveManager sharedInstance] asyncStartPushStream:wroom.liveTitle channelDesc:wroom.liveTitle type:AV_ENCODE_HLS succ:^(TCILivePushRequest *req) {
                par.selected = YES;
                [ws showPush:AV_ENCODE_HLS succ:YES request:req];
            } fail:^(int code, NSString *err) {
                par.selected = NO;
                [ws showPush:AV_ENCODE_HLS succ:NO request:nil];
            }];
        }];
        [testSheet bk_addButtonWithTitle:@"RTMP推流" handler:^{
            
            [[TCILiveManager sharedInstance] asyncStartPushStream:wroom.liveTitle channelDesc:wroom.liveTitle type:AV_ENCODE_RTMP succ:^(TCILivePushRequest *req) {
                par.selected = YES;
                [ws showPush:AV_ENCODE_HLS succ:YES request:req];
            } fail:^(int code, NSString *err) {
                par.selected = NO;
                [ws showPush:AV_ENCODE_HLS succ:NO request:nil];
            }];
        }];
        [testSheet bk_setCancelButtonWithTitle:@"取消" handler:nil];
        [testSheet showInView:self.view];
    }
}

- (void)showPush:(AVEncodeType)type succ:(BOOL)succ request:(TCILivePushRequest *)req
{
    NSString *pushUrl = [req getPushUrl:type];
    if (succ && pushUrl.length > 0)
    {
        UIAlertView *alert = [UIAlertView bk_showAlertViewWithTitle:@"推流地址" message:pushUrl cancelButtonTitle:@"拷至粘切板" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            [pasteboard setString:pushUrl];
        }];
        [alert show];
    }
    else
    {
        [[HUDHelper sharedInstance] tipMessage:@"推流不成功"];
    }
    
}

- (void)onStopRecordIMCallBack:(NSArray *)fileids succ:(BOOL)succ
{
    if (succ)
    {
        if (fileids.count)
        {
            NSString *fileId = @"";
            if(fileids != nil)
            {
                for(int index = 0; index < fileids.count; index++)
                {
                    fileId = [fileId stringByAppendingString:[NSString stringWithFormat:@"%@\n", fileids[index]]];
                }
            }
            DebugLog(@"停止录制时的fileId = %@", fileId);
            
            UIAlertView *alert = [UIAlertView bk_showAlertViewWithTitle:nil message:fileId cancelButtonTitle:@"确定" otherButtonTitles:nil handler:nil];
            [alert show];
        }
        else
        {
            [[HUDHelper sharedInstance] tipMessage:@"停止录制成功"];
        }
    }
    else
    {
        [[HUDHelper sharedInstance] tipMessage:@"停止录制失败"];
    }
}

- (void)onTopView:(TCShowLiveTopView *)topView clickREC:(UIButton *)rec
{
    if (rec.selected)
    {
        __weak typeof(self) ws = self;
        [[TCILiveManager sharedInstance] asyncStopRecordWithCompletion:^(NSArray *fileids) {
            rec.selected = !rec.selected;
            [ws onStopRecordIMCallBack:fileids succ:YES];
        } errBlock:^(int code, NSString *err) {
            rec.selected = !rec.selected;
            [ws onStopRecordIMCallBack:nil succ:NO];
        }];
    }
    else
    {
        
        UIActionSheet *sheet = [[UIActionSheet alloc] init];
        [sheet bk_addButtonWithTitle:@"音频录制" handler:^{
            
            
            NSString *tag = @"8921";
            AVRecordInfo *avRecordinfo = [[AVRecordInfo alloc] init];
            avRecordinfo.fileName = [_roomInfo liveTitle];
            avRecordinfo.tags = @[tag];
            avRecordinfo.classId = [tag intValue];
            avRecordinfo.isTransCode = NO;
            avRecordinfo.isScreenShot = NO;
            avRecordinfo.isWaterMark = NO;
            avRecordinfo.recordType = AV_RECORD_TYPE_AUDIO;
            
            rec.enabled = NO;
            [[TCILiveManager sharedInstance] asyncStartRecord:avRecordinfo succ:^{
                rec.enabled = YES;
                rec.selected = YES;
            } errBlock:^(int code, NSString *err) {
                rec.enabled = YES;
                rec.selected = NO;
            }];
        }];
        
        [sheet bk_addButtonWithTitle:@"视频录制" handler:^{
            
            NSString *tag = @"8921";
            AVRecordInfo *avRecordinfo = [[AVRecordInfo alloc] init];
            avRecordinfo.fileName = [_roomInfo liveTitle];
            avRecordinfo.tags = @[tag];
            avRecordinfo.classId = [tag intValue];
            avRecordinfo.isTransCode = NO;
            avRecordinfo.isScreenShot = NO;
            avRecordinfo.isWaterMark = NO;
            avRecordinfo.recordType = AV_RECORD_TYPE_VIDEO;
            
            rec.enabled = NO;
            [[TCILiveManager sharedInstance] asyncStartRecord:avRecordinfo succ:^{
                rec.enabled = YES;
                rec.selected = YES;
            } errBlock:^(int code, NSString *err) {
                rec.enabled = YES;
                rec.selected = NO;
            }];
        }];
        
        
        [sheet bk_setCancelButtonWithTitle:@"取消" handler:nil];
        [sheet showInView:self.view];
    }
    
}
- (void)onTopView:(TCShowLiveTopView *)topView clickSpeed:(UIButton *)speed
{
#if kIsMeasureSpeed
    [[IMAPlatform sharedInstance] requestTestSpeed];
#endif
}




- (void)onTimViewTimeRefresh:(TCShowLiveTimeView *)topView
{
    if (!_parTextView.hidden)
    {
        QAVContext *avContext = [TCILiveManager sharedInstance].avContext;
        NSString *videoParam = [avContext.videoCtrl getQualityTips];
        NSString *audioParam = [avContext.audioCtrl getQualityTips];
        NSString *commonParam = [avContext.room getQualityTips];
        _parTextView.text = [NSString stringWithFormat:@"Video:\n%@Audio:\n%@Common:\n%@", videoParam, audioParam, commonParam];
    }
    
}

///////////////////////////////////////////////////////////

- (void)onBottomViewSwitchToPureMode:(TCShowLiveBottomView *)bottomView
{
    if (_inputView && !_inputView.hidden)
    {
        if (_inputView.isInputViewActive)
        {
            [_inputView resignFirstResponder];
        }
        
        [_inputView slideOutTo:kFTAnimationBottom duration:0.25 delegate:nil];
        
    }
    _isPureMode = YES;
    [_topView slideOutTo:kFTAnimationTop duration:0.25 delegate:nil];
    [_msgView changeToMode:YES];
    //    _msgHandler.isPureMode = YES;
    [_msgView slideOutTo:kFTAnimationLeft duration:0.25 delegate:nil];
}
- (void)onBottomViewSwitchToNonPureMode:(TCShowLiveBottomView *)bottomView
{
    _isPureMode = NO;
    [_topView slideInFrom:kFTAnimationTop duration:0.25 delegate:nil];
    [_msgView changeToMode:NO];
    //    _msgHandler.isPureMode = NO;
    [_msgView slideInFrom:kFTAnimationLeft duration:0.25 delegate:nil];
}
- (void)onBottomViewSwitchToMessage:(TCShowLiveBottomView *)bottomView fromButton:(UIButton *)button
{
    if (_inputViewShowing)
    {
        return;
    }
    _inputViewShowing = YES;
    
    button.enabled = NO;
    [self.view animation:^(id selfPtr) {
        [_inputView becomeFirstResponder];
        [_bottomView fadeOut:0.25 delegate:nil];
        [_inputView fadeIn:0.25 delegate:nil];
    } duration:1 completion:^(id selfPtr) {
        button.enabled = YES;
        _inputViewShowing = NO;
    }];
    
}

- (void)onBottomViewSendPraise:(TCShowLiveBottomView *)bottomView fromButton:(UIButton *)button
{
    [[TCILiveManager sharedInstance] sendGroupCustomMsg:TCILiveCMD_Praise actionParam:nil succ:nil fail:nil];
    [_bottomView showLikeHeart];
    
    [_roomInfo setLivePraise:[_roomInfo livePraise] + 1];
    [_topView onRefrshPraiseAndAudience];
}
///////////////////////////////////////////////////////////

- (void)onBottomView:(TCShowLiveBottomView *)bottomView operateCameraOf:(id<AVMultiUserAble>)user fromButton:(UIButton *)button
{
    //    NSInteger cmd = button.selected ? AVIMCMD_Multi_Host_DisableInteractCamera : AVIMCMD_Multi_Host_EnableInteractCamera;
    //    NSInteger cmd = AVIMCMD_Multi_Host_ControlCamera;
    //    [(MultiAVIMMsgHandler *)_msgHandler sendC2CAction:cmd to:user succ:^{
    //        button.selected = !button.selected;
    //
    //        NSInteger curState = [user avCtrlState];
    //        if (button.selected)
    //        {
    //            curState = curState | EAVCtrlState_Camera;
    //        }
    //        else
    //        {
    //            curState = curState & ~EAVCtrlState_Camera;
    //        }
    //
    //        [user setAvCtrlState:curState];
    //
    //    } fail:nil];
}
- (void)onBottomView:(TCShowLiveBottomView *)bottomView operateMicOf:(id<AVMultiUserAble>)user fromButton:(UIButton *)button
{
    //    NSInteger cmd = button.selected ? AVIMCMD_Multi_Host_DisableInteractMic : AVIMCMD_Multi_Host_EnableInteractMic;
    //    NSInteger cmd = AVIMCMD_Multi_Host_ControlMic;
    //    [(MultiAVIMMsgHandler *)_msgHandler sendC2CAction:cmd to:user succ:^{
    //
    //        button.selected = !button.selected;
    //
    //        NSInteger curState = [user avCtrlState];
    //        if (button.selected)
    //        {
    //            curState = curState | EAVCtrlState_Mic;
    //        }
    //        else
    //        {
    //            curState = curState & ~EAVCtrlState_Mic;
    //        }
    //
    //        [user setAvCtrlState:curState];
    //
    //    } fail:nil];
    
}
- (void)onBottomView:(TCShowLiveBottomView *)bottomView switchToMain:(id<AVMultiUserAble>)user fromButton:(UIButton *)button
{
    //    __weak TCAVMultiLiveViewController *controller = (TCAVMultiLiveViewController *)_liveController;
    //
    //    __weak TCShowMultiView *wm = [(TCShowMultiLiveView *)_liveView multiView];
    //    [controller switchToMainInPreview:user completion:^(BOOL succ, NSString *tip) {
    //        if (succ)
    //        {
    //            // 交换TCShowMultiView上的资源信息
    //            id<AVMultiUserAble> main = [controller.multiManager mainUser];
    //            [wm replaceViewOf:user with:main];
    //
    //        }
    //    }];
}
- (void)onBottomView:(TCShowLiveBottomView *)bottomView cancelInteractWith:(id<AVMultiUserAble>)user fromButton:(UIButton *)button
{
    //    TCAVMultiLiveViewController *controller = (TCAVMultiLiveViewController *)_liveController;
    //    BOOL isClickLeave = [controller.livePreview isRenderUserLeave];
    //    if (isClickLeave)
    //    {
    //        DebugLog(@"只是隐藏掉，并不是真正意义上的回来了");
    //        [controller.livePreview onUserBack:user];
    //    }
    //
    //    [controller.multiManager initiativeCancelInteractUser:user];
}

///////////////////////////////////////////////////////////

// 返回没有自动处理(registerRenderMemo外部用户可在每次enterRoom之前，添加要渲染的画面的identifier以及对应的无域，详见registerRenderMemo的法)的无程视频处理流程identifier
// 当内部收到AVSDK- (void)OnSemiAutoRecvCameraVideo:(NSArray *)identifierList回调时
- (void)onRecvSemiAutoCameraVideo:(NSArray *)identifierList
{
    
}

- (void)onRecvReplyInteractJoinRequestView:(BOOL)succ ofSender:(id<IMUserAble>)sender
{
    [_multiView onRequestViewOf:(id<AVMultiUserAble>)sender complete:succ];
}


// 将AVSDK抛出的-(void)OnEndpointsUpdateInfo:(QAVUpdateEvent)eventID endpointlist:(NSArray *)endpoints，在内部记录状态后，原样抛出给上层处理，详见AVSDK回调说明
// endpoints : 为QAVEndpoint类型，用户此在回调中注意，不要做长时或异步处理
- (void)onEndpointsUpdateInfo:(QAVUpdateEvent)eventID endpointlist:(NSArray *)endpoints
{
    switch (eventID)
    {
        case  QAV_EVENT_ID_ENDPOINT_HAS_CAMERA_VIDEO:// = 3,  ///< 有发摄像头视频事件。
        {
            for (QAVEndpoint *point in endpoints)
            {
                [self onRecvReplyInteractJoinRequestView:YES ofSender:point];
            }
        }
            break;
            //            QAV_EVENT_ID_ENDPOINT_NO_CAMERA_VIDEO = 4,  ///< 无发摄像头视频事件。
            //            QAV_EVENT_ID_ENDPOINT_HAS_AUDIO = 5,        ///< 有发语音事件。
            //            QAV_EVENT_ID_ENDPOINT_NO_AUDIO = 6,         ///< 无发语音事件。
        case QAV_EVENT_ID_ENDPOINT_HAS_SCREEN_VIDEO:// = 7,  ///< 有发屏幕视频事件。
        {
            
        }
            //            QAV_EVENT_ID_ENDPOINT_NO_SCREEN_VIDEO = 8,   ///< 无发屏幕视频事件。:
            
            break;
            
        default:
            break;
    }
}

// 将AVSDK内部异常退房回调抛出给外部处理，ILiveSDK内部在收到AVSDK的-(void)OnRoomDisconnect:(int)reason回调时，内部已释放相关资源，外部不需要再调用exitRoom进行退房
// result为异常断开的错误码
- (void)onRoomDisconnected:(int)result
{
    
}

//===============================================

// 收到群聊天消息: (主要是文本类型)
- (void)onIMHandler:(TCILiveMsgHandler *)handler recvGroupMsg:(TCILiveMsg *)amsg
{
    DebugLog(@"msg = %@", amsg);
    TCShowLiveMsg *msg = [[TCShowLiveMsg alloc] initWith:amsg.sender message:amsg.msgText];
    [_msgView insertMsg:msg];
}

// 收到自定义C2C消息
// 用户自行解析
- (void)onIMHandler:(TCILiveMsgHandler *)handler recvCustomC2C:(TCILiveCMD *)msg
{
    DebugLog(@"msg = %@", msg);
    // do nothing
    // overwrite by the subclass
}

- (void)onRecvCustomLeave:(TCILiveCMD *)msg
{
    DebugLog(@"主播离开");
    
    //        AVIMCMD *cmd = (AVIMCMD *)msg;
    //        id<IMUserAble> sender = [cmd sender];
    //        NSArray *array = @[sender];
    //
    //        if ([[lvc.multiManager.mainUser imUserId] isEqualToString:[sender imUserId]])
    //        {
    //            [lvc.livePreview onUserLeave:lvc.multiManager.mainUser];
    //        }
    //        [_liveView onUserLeave:array];
    
}

- (void)onRecvCustomBack:(TCILiveCMD *)msg
{
    DebugLog(@"主播回来了");
    //    AVIMCMD *cmd = (AVIMCMD *)msg;
    //    TCAVMultiLiveViewController *lvc = (TCAVMultiLiveViewController *)_liveController;
    //
    //    id<IMUserAble> sender = [cmd sender];
    //    NSArray *array = @[[cmd sender]];
    //
    //    if ([[lvc.multiManager.mainUser imUserId] isEqualToString:[sender imUserId]])
    //    {
    //        [lvc.livePreview onUserBack:lvc.multiManager.mainUser];
    //    }
    //    [_liveView onUserBack:array];
    //
    //    [lvc.multiManager requestMultipleViewOf:array];
}




// 收到自定义的Group消息
// 用户自行解析
- (void)onIMHandler:(TCILiveMsgHandler *)handler recvCustomGroup:(TCILiveCMD *)msg
{
    DebugLog(@"msg = %@", msg);
    switch ([msg msgType])
    {
        case AVIMCMD_Praise:
        {
            NSInteger praise = [_roomInfo livePraise];
            [_roomInfo setLivePraise:praise + 1];
            [_bottomView showLikeHeart];
            [_topView onRefrshPraiseAndAudience];
            
        }
            break;
        case AVIMCMD_Host_Leave:
        {
            [self onRecvCustomLeave:msg];
        }
            break;
        case AVIMCMD_Host_Back:
        {
            [self onRecvCustomBack:msg];
            
        }
            break;
        default:
            break;
    }
}

// 群主解散群消息，或后台自动解散
- (void)onIMHandler:(TCILiveMsgHandler *)handler deleteGroup:(TIMUserProfile *)sender
{
    DebugLog(@"sender = %@", sender);
    if (!_isExiting)
    {
        _isExiting = YES;
        // 说明主播退出
        UIAlertView *alert =  [UIAlertView bk_showAlertViewWithTitle:nil message:@"直播群已解散" cancelButtonTitle:@"确定" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            [self exitLive];
        }];
        [alert show];
    }
    
}

// 有新用户进入
// senders是TIMUserProfile类型
- (void)onIMHandler:(TCILiveMsgHandler *)handler joinGroup:(NSArray *)senders
{
    DebugLog(@"sender = %@", senders);
    [_topView onImUsersEnterLive:senders];
}

// 有用户退出
// senders是TIMUserProfile类型
- (void)onIMHandler:(TCILiveMsgHandler *)handler exitGroup:(NSArray *)senders
{
    DebugLog(@"sender = %@", senders);
    [_topView onImUsersExitLive:senders];
}

- (void)requestVideoOf:(id<AVMultiUserAble>)user
{
    // 请求用户的画面
    [self assignWindowResourceTo:user isInvite:YES];
    [[TCILiveManager sharedInstance] addRenderFor:[user imUserId] atFrame:[user avInteractArea]];
}

- (void)assignWindowResourceTo:(id<AVMultiUserAble>)user isInvite:(BOOL)inviteOrAuto
{
    if (inviteOrAuto)
    {
        [_multiView inviteInteractWith:user];
    }
    else
    {
        [_multiView addWindowFor:user];
    }
    
    TCShowMultiSubView *subView = [_multiView overlayOf:user];
    
    // 后期作互动窗口切换使用
    [user setAvInvisibleInteractView:subView];
    
    // 相对于全屏的位置
    CGRect rect = [subView relativePositionTo:[UIApplication sharedApplication].keyWindow];
    [user setAvInteractArea:rect];
}

- (void)showSelfVideoToOther
{
    
    id<AVMultiUserAble> curentIMHost = (id<AVMultiUserAble>)[IMAPlatform sharedInstance].host;
    // 先检查本地是否已加
    [_interactUserDic setObject:curentIMHost forKey:[[_roomInfo liveHost] imUserId]];

    // 外部同步分配资源
    [self assignWindowResourceTo:curentIMHost isInvite:NO];
    [[TCILiveManager sharedInstance] addRenderFor:[curentIMHost imUserId] atFrame:[curentIMHost avInteractArea]];

    [[TCILiveManager sharedInstance] enableCamera:CameraPosFront isEnable:YES complete:^(BOOL succ, QAVResult result) {
        
    }];
}


- (void)onRecvHostInteractChangeAuthAndRole:(id<IMUserAble>)sender
{
    // 本地先修改权限
    //  controller.multiManager ;
    // 然后修改role
    // 再打开相机
    __weak typeof(self) ws = self;
    [[TCILiveManager sharedInstance] checkNoCameraAuth:^{
        [[TCILiveManager sharedInstance] sendC2CCustomMsg:[sender imUserId] action:TCILiveCMD_Multi_Interact_Refuse actionParam:nil succ:nil fail:nil];
    } micNotPermission:^{
        [[TCILiveManager sharedInstance] sendC2CCustomMsg:[sender imUserId] action:TCILiveCMD_Multi_Interact_Refuse actionParam:nil succ:nil fail:nil];
    } checkComplete:^{
        // TODO：添加上麦接口
        
        [[TCILiveManager sharedInstance] changeToRole:@"InteractUser" auth:QAV_AUTH_BITS_DEFAULT completion:^(BOOL isFinished) {
            if (isFinished)
            {
                // 同意
                [[TCILiveManager sharedInstance] sendC2CCustomMsg:[sender imUserId] action:TCILiveCMD_Multi_Interact_Join actionParam:nil succ:^{
                    // 进行连麦操作
                    [ws showSelfVideoToOther];
                } fail:^(int code, NSString *msg) {
                    [[TCILiveManager sharedInstance] sendC2CCustomMsg:[sender imUserId] action:TCILiveCMD_Multi_Interact_Refuse actionParam:nil succ:nil fail:nil];
                    DebugLog(@"code = %d, msg = %@", code, msg);
                }];
            }
            else
            {
                [[TCILiveManager sharedInstance] sendC2CCustomMsg:[sender imUserId] action:TCILiveCMD_Multi_Interact_Refuse actionParam:nil succ:nil fail:nil];
            }
        }];
    }];
    
}


//@required
static __weak UIAlertView *kInteractAlert = nil;
static BOOL kRectHostCancelInteract = NO;
- (void)onRecvHostInteract:(TCILiveCMD *)msg
{
    TIMUserProfile *sender = [msg sender];
    
    __weak typeof(self) ws = self;
    NSString *text = [NSString stringWithFormat:@"主播(%@)邀请您参加TA的互动直播", [sender imUserName]];
    UIAlertView *alert = [UIAlertView bk_showAlertViewWithTitle:@"互动直播邀请" message:text cancelButtonTitle:@"拒绝" otherButtonTitles:@[@"同意"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 0)
        {
            if (!kRectHostCancelInteract)
            {
                //  拒绝
                [[TCILiveManager sharedInstance] sendC2CCustomMsg:sender.identifier action:TCILiveCMD_Multi_Interact_Refuse actionParam:nil succ:nil fail:nil];
            }
            
        }
        else if (buttonIndex == 1)
        {
            // 同意
            if (!kRectHostCancelInteract)
            {
                [ws onRecvHostInteractChangeAuthAndRole:sender];
            }
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            kInteractAlert = nil;
            kRectHostCancelInteract = NO;
        });
    }];
    alert.tag = 2000;
    [alert show];
    kInteractAlert = alert;
}

- (void)onRecvReplyInteractJoin:(TCILiveCMD *)msg
{
    TIMUserProfile *sender = msg.sender;
    [_multiView requestViewOf:sender];

}
// 收到自定义的TIMAdapter内的多人互动消息
- (void)onIMHandler:(TCILiveMsgHandler *)receiver recvCustomC2CMultiMsg:(TCILiveCMD *)msg
{
    NSInteger type = [msg msgType];
    switch (type)
    {
        case AVIMCMD_Multi_Host_Invite:
        {
            // 收到主播邀请消息
            [self onRecvHostInteract:msg];
        }
            break;
//            case AVIMCMD_Multi_CancelInteract:
//            {
//                [self onRecvHostCancelInteract:msg];
//            }
//                break;
            case AVIMCMD_Multi_Interact_Join:
            {
                [self onRecvReplyInteractJoin:msg];
            }
                break;
            //        case AVIMCMD_Multi_Interact_Refuse:
            //        {
            //            [self onRecvReplyInteractRefuse:msg];
            //        }
            //            break;
            //        case AVIMCMD_Multi_Host_EnableInteractMic:
            //        {
            //            [self onRecvHostEnableMic:msg];
            //        }
            //            break;
            //        case AVIMCMD_Multi_Host_DisableInteractMic:
            //        {
            //            [self onRecvHostDisableMic:msg];
            //        }
            //            break;
            //        case AVIMCMD_Multi_Host_EnableInteractCamera:
            //        {
            //            [self onRecvHostEnableCamera:msg];
            //        }
            //            break;
            //        case AVIMCMD_Multi_Host_DisableInteractCamera:
            //        {
            //            [self onRecvHostDisableCamera:msg];
            //        }
            //            break;
            //        case AVIMCMD_Multi_Host_CancelInvite:
            //        {
            //            [self onRecvCancelInteract:msg];
            //        }
            //            break;
            //        case AVIMCMD_Multi_Host_ControlCamera:
            //        {
            //            [self onRecvHostControlCamera:msg];
            //        }
            //            break;
            //        case AVIMCMD_Multi_Host_ControlMic:
            //        {
            //            [self onRecvHostControlMic:msg];
            //        }
            break;
            
        default:
            break;
    }
}

- (void)onIMHandler:(TCILiveMsgHandler *)receiver recvCustomGroupMultiMsg:(TCILiveCMD *)msg
{
    DebugLog(@"msg = %@", msg);
}

//@required

// 在子线程中预先计算消息渲染
- (void)onIMHandler:(TCILiveMsgHandler *)handler preRenderLiveMsg:(TCILiveMsg *)msg
{
    TCShowLiveMsg *tmsg = (TCShowLiveMsg *)msg;
    [tmsg prepareForRender];
}

- (void)onIMHandler:(TCILiveMsgHandler *)handler preRenderLiveCMD:(TCILiveCMD *)msg
{
    DebugLog(@"msg = %@", msg);
    // do nothing
}


//@required
// 定时刷新消息回调
- (void)onIMHandler:(TCILiveMsgHandler *)handler timedRefresh:(NSDictionary *)cacheDic
{
    //    DebugLog(@"cacheDic = %@", cacheDic);
    TCILAVIMCache *msgcache = cacheDic[@(TCILiveCMD_Text)];
    if (msgcache.count)
    {
        [_msgView insertCachedMsg:msgcache];
    }
    
    
    TCILAVIMCache *praisecache = cacheDic[@(TCILiveCMD_Praise)];
    
    if (praisecache.count)
    {
        NSInteger praise = [_roomInfo livePraise];
        [_roomInfo setLivePraise:praise + praisecache.enCacheCount];
        [_bottomView showLikeHeart:praisecache];
        [_topView onRefrshPraiseAndAudience];
    }
}


- (void)onMultiView:(TCShowMultiView *)render inviteTimeOut:(id<AVMultiUserAble>)user
{
    
}

- (void)onMultiView:(TCShowMultiView *)render hangUp:(id<AVMultiUserAble>)user
{
    
}

- (void)onMultiView:(TCShowMultiView *)render clickSub:(id<AVMultiUserAble>)user
{
    
}

@end
