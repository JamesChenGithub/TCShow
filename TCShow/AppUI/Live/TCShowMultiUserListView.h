//
//  TCShowMultiUserListView.h
//  TCShow
//
//  Created by AlexiChen on 16/9/28.
//  Copyright © 2016年 AlexiChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCShowMultiUserListView;

@protocol TCShowMultiUserListViewDelegate <NSObject>

@required

- (BOOL)onUserListView:(TCShowMultiUserListView *)view isInteratcUser:(id<AVMultiUserAble>)user;
- (void)onUserListView:(TCShowMultiUserListView *)view clickUser:(id<AVMultiUserAble>)user;

@end

@interface TCShowMultiUserListView : UIView<UITableViewDataSource, UITableViewDelegate>
{
@protected
    UIView          *_backView;
    InsetLabel      *_tipLabel;
    UITableView     *_tableView;
@protected
    NSArray         *_userList;
}

@property (nonatomic, weak) id<TCShowMultiUserListViewDelegate> delegate;

- (instancetype)initWith:(NSArray *)array;

- (void)show;

@end
