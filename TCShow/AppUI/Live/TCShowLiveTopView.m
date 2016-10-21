//
//  TCShowLiveTopView.m
//  TCShow
//
//  Created by AlexiChen on 16/4/14.
//  Copyright © 2016年 AlexiChen. All rights reserved.
//

#import "TCShowLiveTopView.h"


@implementation TCShowLiveTimeView

- (instancetype)initWith:(id<TCShowLiveRoomAble>)room
{
    if (self = [super initWithFrame:CGRectZero])
    {
        _room = room;
        
        [self addOwnViews];
        [self configOwnViews];
        
        self.backgroundColor = [kBlackColor colorWithAlphaComponent:0.3];
        self.layer.cornerRadius = 25;
        self.layer.masksToBounds = YES;
        
        [_liveStatusTimer invalidate];
        _liveStatusTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshNetAndLiveStatus) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_liveStatusTimer forMode:NSRunLoopCommonModes];
        
    }
    return self;
}

//- (void)setRoomEngine:(TCAVBaseRoomEngine *)engine
//{
//    _roomEngine = engine;
//}

- (BOOL)isHost
{
    return [[IMAPlatform sharedInstance].host isCurrentLiveHost:_room];
}

- (void)addOwnViews
{
    _liveHost = [[MenuButton alloc] init];
    _liveHost.layer.cornerRadius = 22;
    _liveHost.layer.masksToBounds = YES;
    [self addSubview:_liveHost];
    
    _netStatus = [[ImageTitleButton alloc] initWithStyle:EImageLeftTitleRightCenter];
    [_netStatus setBackgroundImage:[[UIImage imageNamed:@"net3"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self addSubview:_netStatus];
    
    _liveStatus = [[ImageTitleButton alloc] initWithStyle:EImageLeftTitleRightCenter];
    _liveStatus.layer.cornerRadius = 5;
    _liveStatus.backgroundColor = kGreenColor;
    
    [self addSubview:_liveStatus];
    
    if ([self isHost])
    {
        _liveTime = [[ImageTitleButton alloc] initWithStyle:EImageLeftTitleRightCenter];
        [_liveTime setTitleColor:kWhiteColor forState:UIControlStateNormal];
        [self addSubview:_liveTime];
    }
    else
    {
        _liveTime = [[ImageTitleButton alloc] initWithStyle:EImageLeftTitleRightLeft];
        [_liveTime setTitleColor:kWhiteColor forState:UIControlStateNormal];
        _liveTime.titleLabel.adjustsFontSizeToFitWidth = YES;
        _liveTime.titleLabel.textAlignment = NSTextAlignmentLeft;
        _liveTime.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_liveTime];
    }
    
    _liveAudience = [[ImageTitleButton alloc] initWithStyle:EImageLeftTitleRightCenter];
    [_liveAudience setImage:[UIImage imageNamed:@"visitor_white"] forState:UIControlStateNormal];
    _liveAudience.titleLabel.adjustsFontSizeToFitWidth = YES;
    _liveAudience.titleLabel.font = kAppSmallTextFont;
    [_liveAudience setTitleColor:kWhiteColor forState:UIControlStateNormal];
    [self addSubview:_liveAudience];
    
    _livePraise = [[ImageTitleButton alloc] initWithStyle:EImageLeftTitleRightCenter];
    [_livePraise setImage:[UIImage imageNamed:@"like_white"] forState:UIControlStateNormal];
    _livePraise.titleLabel.adjustsFontSizeToFitWidth = YES;
    _livePraise.titleLabel.font = kAppSmallTextFont;
    [_livePraise setTitleColor:kWhiteColor forState:UIControlStateNormal];
    [self addSubview:_livePraise];
    
}

- (void)onClickHost
{
    
}

- (void)changeRoomInfo:(id<TCShowLiveRoomAble>)room
{
    _room = room;
    [self configOwnViews];
}
- (void)configOwnViews
{
    NSString *url = [[_room liveHost] imUserIconUrl];
    [_liveHost sd_setImageWithURL:[NSURL URLWithString:url] forState:UIControlStateNormal placeholderImage:kDefaultUserIcon];
    
    if ([self isHost])
    {
        [_liveTime setTitle:@"00:00" forState:UIControlStateNormal];
    }
    else
    {
        [_liveTime setTitle:[[_room liveHost] imUserName] forState:UIControlStateNormal];
    }
    
    [_liveAudience setTitle:[NSString stringWithFormat:@"%d", (int)[_room liveAudience]] forState:UIControlStateNormal];
    [_livePraise setTitle:[NSString stringWithFormat:@"%d", (int)[_room livePraise]] forState:UIControlStateNormal];
    
}

- (void)relayoutFrameOfSubViews
{
    [_liveHost sizeWith:CGSizeMake(44, 44)];
    [_liveHost layoutParentVerticalCenter];
    [_liveHost alignParentLeftWithMargin:3];
    
    [_netStatus sizeWith:CGSizeMake(20, 20)];
    [_netStatus layoutToRightOf:_liveHost margin:5];
    [_netStatus alignParentTopWithMargin:kDefaultMargin];
    
    [_liveStatus sizeWith:CGSizeMake(22, 10)];
    [_liveStatus layoutToRightOf:_liveHost margin:5];
    [_liveStatus alignParentBottomWithMargin:kDefaultMargin];
    
    [_liveTime sizeWith:CGSizeMake(15, 15)];
    [_liveTime alignTop:_liveHost];
    [_liveTime layoutToRightOf:_netStatus margin:3];
    [_liveTime scaleToParentRightWithMargin:10];
    
    [_liveAudience sizeWith:CGSizeMake(_liveTime.bounds.size.width/2, _liveTime.bounds.size.height)];
    [_liveAudience alignLeft:_liveTime];
    [_liveAudience alignBottom:_liveHost];
    
    [_livePraise sameWith:_liveAudience];
    [_livePraise layoutToRightOf:_liveAudience];
    
    
}

- (void)startLive
{
    [_liveTimer invalidate];
    _liveTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onLiveTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_liveTimer forMode:NSRunLoopCommonModes];
    
    
}

- (void)onLiveTimer
{
    if ([self isHost])
    {
        
        NSInteger dur = [_room liveDuration] + 1;
        [_room setLiveDuration:dur];
        
        NSString *durStr = nil;
        if (dur > 3600)
        {
            int h = (int)dur/3600;
            int m = (int)(dur - h *3600)/60;
            int s = (int)dur%60;
            durStr = [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
        }
        else
        {
            int m = (int)dur/60;
            int s = (int)dur%60;
            durStr = [NSString stringWithFormat:@"%02d:%02d", m, s];
        }
        
        
        [_liveTime setTitle:durStr forState:UIControlStateNormal];
        [_delegate onTimViewTimeRefresh:self];
        
#if kSupportIMMsgCache
#else
        [self onRefrshPraiseAndAudience];
#endif
        
    }
}

//刷新网络状态和直播状态
- (void)refreshNetAndLiveStatus
{
//    if (!_roomEngine)
//    {
//        return;
//    }
    
    NSDictionary *paramDic = [[TCILiveManager sharedInstance].avContext.room GetQualityParam];
//    NSLog(@"%@", @"+++++++++++++++++++++++++++++++++++++++++");
//    NSLog(@"往返延时--------->%@",[paramDic objectForKey:@"rtt"]);
//    NSLog(@"下行丢包率-------->%@",[paramDic objectForKey:@"loss_rate_recv"]);
//    NSLog(@"上行丢包率-------->%@",[paramDic objectForKey:@"loss_rate_send"]);
//    NSLog(@"udt下行丢包率---->%@",[paramDic objectForKey:@"loss_rate_recv_udt"]);
//    NSLog(@"udt上行丢包率---->%@",[paramDic objectForKey:@"loss_rate_send_udt"]);
//    NSLog(@"%@", @"----------------------------------------");
    
    static NSInteger time = 0;
    if (time % 3 == 0)
    {
        int recvRate = [[paramDic objectForKey:@"loss_rate_recv"] intValue];
        int sendRate = [[paramDic objectForKey:@"loss_rate_send"] intValue];
        int udtRecvRate = [[paramDic objectForKey:@"loss_rate_recv_udt"] intValue];
        int udtSendRate = [[paramDic objectForKey:@"loss_rate_send_udt"] intValue];
        
        //直播质量
        //红色示警(值为预估值，不精确)
        if (recvRate > 4000 || sendRate > 4000 || udtRecvRate > 2000 || udtSendRate > 500)
        {
            _liveStatus.backgroundColor = kRedColor;
        }
        //黄色示警
        else if (recvRate > 2000 || sendRate > 2000 || udtRecvRate > 1000 || udtSendRate > 300)
        {
            _liveStatus.backgroundColor = kYellowColor;
        }
        else//正常
        {
//            [_liveStatus setBackgroundImage:[[UIImage imageNamed:@"liveStatusRed"] imageWithRenderingMode:UIImageRenderingModeAutomatic] forState:UIControlStateNormal];
//            [_liveStatus setImage:[UIImage imageNamed:@"liveStatusRed"] forState:UIControlStateNormal];
            _liveStatus.backgroundColor = kGreenColor;
        }
        
        //网络质量(暂时用丢包率表示)
        int status = 0;
        // 如果下行为0，证明有可能是主播端，没有下行视频，那么要看上行视频
        if (recvRate == 0)
        {
            if (sendRate > 4000)
            {
                status = 3;//红色警告
            }
            else if (sendRate > 2000)
            {
                status = 2;//黄色警告
            }
            else
            {
                status = 0;//正常
            }
        }
        else
        {
            if (recvRate > 4000)
            {
                status = 3;//红色警告
            }
            else if (recvRate > 2000)
            {
                status = 2;//黄色警告
            }
            else
            {
                status = 0;//正常
            }
        }
        
        if (status == 0)
        {
            [_netStatus setBackgroundImage:[[UIImage imageNamed:@"net3"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        }
        else if (status == 1)
        {
            [_netStatus setBackgroundImage:[[UIImage imageNamed:@"net2"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        }
        else
        {
            [_netStatus setBackgroundImage:[[UIImage imageNamed:@"net1"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        }
    }
    time++;
}

- (void)onRefrshPraiseAndAudience
{
    [_liveAudience setTitle:[NSString stringWithFormat:@"%d", (int)[_room liveAudience]] forState:UIControlStateNormal];
    [_livePraise setTitle:[NSString stringWithFormat:@"%d", (int)[_room livePraise]] forState:UIControlStateNormal];
}


- (void)pauseLive
{
    if ([self isHost])
    {
        [_liveTimer invalidate];
        _liveTimer = nil;
    }
}


- (void)resumeLive
{
    
    [self startLive];
}

- (void)onImUsersEnterLive:(NSArray *)array
{
    [_room setLiveAudience:[_room liveAudience] + array.count];
    [_liveAudience setTitle:[NSString stringWithFormat:@"%d", (int)[_room liveAudience]] forState:UIControlStateNormal];
}
- (void)onImUsersExitLive:(NSArray *)array
{
    [_room setLiveAudience:[_room liveAudience] - array.count];
    [_liveAudience setTitle:[NSString stringWithFormat:@"%d", (int)[_room liveAudience]] forState:UIControlStateNormal];
}


@end

@interface LiveUserViewCell : UICollectionViewCell
{
    UIImageView         *_userIcon;
}

@property (nonatomic, readonly) UIImageView *userIcon;

@end

@implementation LiveUserViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    
    if (self = [super initWithFrame:frame])
    {
        _userIcon = [[UIImageView alloc] init];
        _userIcon.image = kDefaultUserIcon;
        _userIcon.layer.cornerRadius = 16;
        _userIcon.layer.masksToBounds = YES;
        [self.contentView addSubview:_userIcon];
    }
    return self;
}

- (void)layoutSubviews
{
    
    [super layoutSubviews];
    CGRect rect = self.contentView.bounds;
    _userIcon.frame = CGRectInset(rect, (rect.size.width - 32)/2, (rect.size.height - 32)/2);
}


@end

@implementation TCShowLiveTopView


- (instancetype)initWith:(id<TCShowLiveRoomAble>)room
{
    if (self = [super initWithFrame:CGRectZero])
    {
        _room = room;
        [self addOwnViewsWith:room];
        [self configOwnViewsWith:room];
    }
    return self;
}

- (void)onImUsersEnterLive:(NSArray *)array
{
    [_timeView onImUsersEnterLive:array];
}
- (void)onImUsersExitLive:(NSArray *)array
{
    [_timeView onImUsersExitLive:array];
}

- (void)onClickClose
{
    
    if (_delegate && [_delegate respondsToSelector:@selector(onTopViewCloseLive:)])
    {
        [_delegate onTopViewCloseLive:self];
    }
}

- (void)startLive
{
    [_timeView startLive];
#if kBetaVersion
    _roomTip.text = [NSString stringWithFormat:@"AV:%d\nIM:%@", [_room liveAVRoomId], [_room liveIMChatRoomId]];
#endif
}
- (void)pauseLive
{
    
    [_timeView pauseLive];
}
- (void)resumeLive
{
    
    [_timeView resumeLive];
}

- (void)onRefrshPraiseAndAudience
{
    [_timeView onRefrshPraiseAndAudience];
}

- (void)onClickHost
{
    
    if (_delegate && [_delegate respondsToSelector:@selector(onTopViewClickHost:host:)])
    {
        [_delegate onTopViewClickHost:self host:[_room liveHost]];
    }
}

- (void)addOwnViewsWith:(id<TCShowLiveRoomAble>)room
{
    
    _timeView = [[TCShowLiveTimeView alloc] initWith:room];
    
    if (![[[IMAPlatform sharedInstance].host imUserId] isEqualToString:[[room liveHost] imUserId]]) {
        __weak TCShowLiveTopView *ws = self;
        
        [_timeView.liveHost setClickAction:^(id<MenuAbleItem> menu) {
            [ws onClickHost];
        }];
    }
    
    [self addSubview:_timeView];
    
    _close = [[UIButton alloc] init];
    [_close setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    [_close addTarget:self action:@selector(onClickClose) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_close];
    
#if kBetaVersion
    _roomTip = [[UILabel alloc] init];
    _roomTip.backgroundColor = [kLightGrayColor colorWithAlphaComponent:0.2];
    _roomTip.textColor = kWhiteColor;
    _roomTip.numberOfLines = 0;
    _roomTip.lineBreakMode = NSLineBreakByWordWrapping;
    _roomTip.adjustsFontSizeToFitWidth = YES;
    _roomTip.font = kAppSmallTextFont;
    [self addSubview:_roomTip];
#endif
    
    //    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    //    layout.itemSize = CGSizeMake(40, 40);
    //    layout.sectionInset = UIEdgeInsetsMake(2, 2, 2, 2);
    //    layout.minimumInteritemSpacing = 1;
    //    layout.minimumLineSpacing = 1;
    //    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    //
    //    _userlist = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
    //    _userlist.backgroundColor = [UIColor clearColor];
    //    [_userlist registerClass:[LiveUserViewCell class] forCellWithReuseIdentifier:@"LiveUserViewCell"];
    //    _userlist.delegate = self;
    //    _userlist.dataSource = self;
    //    _userlist.backgroundColor = [kLightGrayColor colorWithAlphaComponent:0.3];
    //    [self addSubview:_userlist];
//    if ([[IMAPlatform sharedInstance].host isCurrentLiveHost:room])
//    {
        _parView = [[TCShowAVParView alloc] init];
        _parView.delegate = self;
        _parView.isHostPar = [[[room liveHost] imUserId] isEqualToString:[[IMAPlatform sharedInstance].host imUserId]];
        [self addSubview:_parView];
//    }
}


- (void)relayoutFrameOfSubViews
{
    
    CGRect rect = self.bounds;
    [_timeView sizeWith:CGSizeMake(rect.size.width/2, 50)];
    [_timeView alignParentTopWithMargin:15];
    [_timeView alignParentLeftWithMargin:15];
    [_timeView relayoutFrameOfSubViews];
    
    [_close sizeWith:CGSizeMake(30, 30)];
    [_close alignParentTopWithMargin:15];
    [_close alignParentRightWithMargin:15];
    
    //    rect.origin.y += 15 + 50;
    //    rect.size.height -= 15 + 50;
    //    rect = CGRectInset(rect, 0, kDefaultMargin);
    //    _userlist.frame = rect;
    
    
#if kBetaVersion
    [_roomTip sameWith:_timeView];
    [_roomTip layoutToRightOf:_timeView margin:kDefaultMargin];
    [_roomTip scaleToLeftOf:_close margin:kDefaultMargin];
#endif
    
    [self relayoutPARView];
    
}

- (void)onAVParView:(TCShowAVParView *)par clickPar:(UIButton *)button
{
    if ([_delegate respondsToSelector:@selector(onTopView:clickPAR:)])
    {
        [_delegate onTopView:self clickPAR:button];
    }
}

- (void)onAVParView:(TCShowAVParView *)par clickPush:(UIButton *)button
{
    if ([_delegate respondsToSelector:@selector(onTopView:clickPush:)])
    {
        [_delegate onTopView:self clickPush:button];
    }
}

- (void)onAVParView:(TCShowAVParView *)par clickRec:(UIButton *)button
{
    if ([_delegate respondsToSelector:@selector(onTopView:clickREC:)])
    {
        [_delegate onTopView:self clickREC:button];
    }
}

- (void)onAVParView:(TCShowAVParView *)par clickSpeed:(UIButton *)button
{
    if ([_delegate respondsToSelector:@selector(onTopView:clickSpeed:)])
    {
        [_delegate onTopView:self clickSpeed:button];
    }
}

- (void)relayoutPARView
{
    if (_parView)
    {
        [_parView sizeWith:CGSizeMake(45, 25)];
        [_parView alignLeft:_timeView];
        [_parView layoutBelow:_timeView margin:kDefaultMargin];
        [_parView scaleToParentRightWithMargin:kDefaultMargin];
        [_parView relayoutFrameOfSubViews];
    }
}

- (void)configOwnViewsWith:(id<TCShowLiveRoomAble>)room
{
    
#if kBetaVersion
    _roomTip.text = [NSString stringWithFormat:@"AV:%d\nIM:%@", [room liveAVRoomId], [room liveIMChatRoomId]];
#endif
}

//- (void)onRefrshPARView:(TCAVLiveRoomEngine *)engine
//{
//    [_parView onRefrshPARView:engine];
//    
//    _roomEngine = engine;
//    
//    [_timeView setRoomEngine:engine];
//}

- (void)changeRoomInfo:(id<TCShowLiveRoomAble>)room
{
    _room = room;
    [_timeView changeRoomInfo:room];
    [self configOwnViewsWith:room];
}
@end

@implementation TCShowMultiLiveTopView

- (instancetype)initWith:(id<TCShowLiveRoomAble>)room
{
    if (self = [super initWith:room])
    {
        if ([[IMAPlatform sharedInstance].host isCurrentLiveHost:room])
        {
            _interactButton = [[ImageTitleButton alloc] initWithStyle:EImageLeftTitleRightCenter];
            [_interactButton setBackgroundImage:[UIImage imageNamed:@"interactive"] forState:UIControlStateNormal];
            [_interactButton addTarget:self action:@selector(onClickInteract) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_interactButton];
        }
    }
    return self;
}

- (void)onClickInteract
{
    if ([self.delegate respondsToSelector:@selector(onTopViewClickInteract:)])
    {
        [self.delegate onTopViewClickInteract:self];
    }
}

- (void)relayoutPARView
{
    if (_interactButton)
    {
        [_interactButton sizeWith:CGSizeMake(45, 25)];
        [_interactButton alignLeft:_timeView];
        [_interactButton layoutBelow:_timeView margin:kDefaultMargin];
        
        [_parView sameWith:_interactButton];
        [_parView layoutToRightOf:_interactButton margin:kDefaultMargin];
        [_parView scaleToParentRightWithMargin:kDefaultMargin];
        [_parView relayoutFrameOfSubViews];
    }
    else
    {
        [super relayoutPARView];
    }
}

@end
