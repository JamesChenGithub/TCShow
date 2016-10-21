
//
//  LivingListViewController.m
//  JShow
//
//  Created by AlexiChen on 16/2/19.
//  Copyright © 2016年 AlexiChen. All rights reserved.
//

#import "LivingListViewController.h"

@implementation LivingListViewController

- (void)addOwnViews
{
    [super addOwnViews];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

}

- (BOOL)hasData
{
    BOOL has = _datas.count != 0;
    return has;
}

- (void)addRefreshScrollView
{
    [super addRefreshScrollView];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"最新直播";

}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self onRefreshLive];
}

- (void)onRefreshLive
{
    if (!_datas)
    {
        _datas = [NSMutableArray array];
    }
    [self pinHeaderView];
    [self refresh];
}


- (void)onLiveRequestSucc:(LiveListRequest *)req
{
    [_datas removeAllObjects];
    [self onLoadMoreLiveRequestSucc:req];
}


- (void)showNoDataView
{
    ImageTitleButton *btn = (ImageTitleButton *)_noDataView;
    [btn setTitle:@"很抱歉，暂时没有主播开启直播" forState:UIControlStateNormal];
}

- (void)onRefresh
{
    _pageItem.pageIndex = 0;
    
    __weak typeof(self) ws = self;

    LiveListRequest *req = [[LiveListRequest alloc] initWithHandler:^(BaseRequest *request) {
        LiveListRequest *wreq = (LiveListRequest *)request;
        [ws onLiveRequestSucc:wreq];
    } failHandler:^(BaseRequest *request) {
        [ws allLoadingCompleted];
    }];
    req.pageItem = _pageItem;
    [[WebServiceEngine sharedEngine] asyncRequest:req wait:NO];
}

- (void)onLoadMoreLiveRequestSucc:(LiveListRequest *)req
{
    TCShowLiveList *resp = (TCShowLiveList *)req.response.data;
    [_datas addObjectsFromArray:resp.recordList];
    self.canLoadMore = resp.recordList.count >= req.pageItem.pageSize;
    _pageItem.pageIndex++;
    [self reloadData];
}

- (void)onLoadMore
{
    __weak typeof(self) ws = self;
    LiveListRequest *req = [[LiveListRequest alloc] initWithHandler:^(BaseRequest *request) {
        LiveListRequest *wreq = (LiveListRequest *)request;
        [ws onLoadMoreLiveRequestSucc:wreq];
    } failHandler:^(BaseRequest *request) {
        [ws allLoadingCompleted];
    }];
    req.pageItem = _pageItem;
    [[WebServiceEngine sharedEngine] asyncRequest:req wait:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger height = (NSInteger) (0.618 * tableView.bounds.size.width + 54 + 10);
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    LiveListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LiveListTableViewCell"];
    if(cell == nil)
    {
        cell = [[LiveListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LiveListTableViewCell"];
    }
    
    id<TCShowLiveRoomAble> room = _datas[indexPath.row];
    
    [cell configWith:room];
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![IMAPlatform sharedInstance].isConnected)
    {
        [HUDHelper alert:@"当前无网络"];
        return;
    }
    
    TCShowLiveListItem *liveRoom = _datas[indexPath.row];
    
    
    TCShowHost *host = (TCShowHost *)[IMAPlatform sharedInstance].host;
    TCILiveRoom *room = [[TCILiveRoom alloc] initLiveWith:liveRoom.avRoomId liveHost:[[liveRoom liveHost] imUserId] chatRoomID:[liveRoom liveIMChatRoomId] curUserID:[host imUserId] roomControlRole:@"LiveHost"];
    room.config.autoMonitorForeBackgroundSwitch = NO;
//    room.config.enterRoomAuth = QAV_AUTH_BITS_DEFAULT;
//    room.config.autoEnableCamera = YES;
    
    [[HUDHelper sharedInstance] syncLoading:@"进入直播"];
    
    LiveViewController *pcvc = [[LiveViewController alloc] initWith:liveRoom user:host];
    __weak typeof(self) ws = self;
    [[TCILiveManager sharedInstance] enterRoom:room imChatRoomBlock:^(BOOL succ, NSString *groupID, NSError *err) {
        
        if (succ)
        {
            [liveRoom setLiveIMChatRoomId:groupID];
        }
        else
        {
            [[HUDHelper sharedInstance] syncStopLoadingMessage:[room isHostLive] ? @"创建直播聊天室出错" : @"加入直播随天室出错"];
        }
        
    } avRoomCallBack:^(BOOL succ, NSError *err) {
        if (succ)
        {
            [[HUDHelper sharedInstance] syncStopLoading];
            [ws presentViewController:pcvc animated:YES completion:nil];
        }
        else
        {
            [[HUDHelper sharedInstance] syncStopLoadingMessage:[room isHostLive] ? @"创建直播房间出错" : @"加入直播间出错"];
        }
    } managerListener:pcvc];
    
    // 进入直播间
//#if kSupportMultiLive
//    // 互动直播使用TCShowMultiLiveViewController
//    TCShowLiveListItem *item = _datas[indexPath.row];
//    TCShowMultiLiveViewController *vc = [[TCShowMultiLiveViewController alloc] initWith:item user:[IMAPlatform sharedInstance].host];
//    [[AppDelegate sharedAppDelegate] pushViewController:vc];
//#else
//    // 如果是直播TCShowLiveViewController
//    TCShowLiveListItem *item = _datas[indexPath.row];
//    TCShowLiveViewController *vc = [[TCShowLiveViewController alloc] initWith:item user:[IMAPlatform sharedInstance].host];
//    [[AppDelegate sharedAppDelegate] pushViewController:vc];
//#endif
}

@end
