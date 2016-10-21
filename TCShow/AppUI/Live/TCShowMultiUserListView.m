//
//  TCShowMultiUserListView.m
//  TCShow
//
//  Created by AlexiChen on 16/9/28.
//  Copyright © 2016年 AlexiChen. All rights reserved.
//

#import "TCShowMultiUserListView.h"

@interface TCShowMultiUserListViewCell : UITableViewCell

@end

@implementation TCShowMultiUserListViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.imageView.layer.cornerRadius = 20;
        self.imageView.layer.masksToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.imageView sizeWith:CGSizeMake(40, 40)];
    [self.imageView layoutParentVerticalCenter];
    [self.imageView alignParentLeftWithMargin:kDefaultMargin];
}

@end


@implementation TCShowMultiUserListView

- (instancetype)initWith:(NSArray *)array
{
    if (self = [super initWithFrame:CGRectZero])
    {
        _userList = array;
        [self addOwnViews];
        [self configOwnViews];
    }
    
    return self;
}

- (void)addOwnViews
{
    _backView = [[UIView alloc] init];
    _backView.backgroundColor = [kBlackColor colorWithAlphaComponent:0.4];
    [self addSubview:_backView];
    
    _tipLabel = [[InsetLabel alloc] init];
    _tipLabel.contentInset = UIEdgeInsetsMake(0, kDefaultMargin, 0, kDefaultMargin);
    _tipLabel.backgroundColor = kWhiteColor;
    NSString *tip = @"邀请互动连线";
    NSString *t = [NSString stringWithFormat:@"%@(最多可与三个观众进行互动直播)", tip];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:t];
    
    [text addAttribute:NSFontAttributeName value:kAppMiddleTextFont range:NSMakeRange(0, tip.length)];
    [text addAttribute:NSForegroundColorAttributeName value:kBlackColor range:NSMakeRange(0, tip.length)];
    [text addAttribute:NSFontAttributeName value:kAppMiddleTextFont range:NSMakeRange(tip.length, t.length - tip.length)];
    [text addAttribute:NSForegroundColorAttributeName value:kGrayColor range:NSMakeRange(tip.length, t.length - tip.length)];
    _tipLabel.attributedText = text;
    [self addSubview:_tipLabel];
    
    _tableView = [[UITableView alloc] init];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self addSubview:_tableView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBack:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [_backView addGestureRecognizer:tap];
}

- (void)show
{
#if kSupportFTAnimation
    [self animation:^(id selfPtr) {
        [_tipLabel slideInFrom:kFTAnimationTop duration:0.25 delegate:nil];
        [_tableView slideInFrom:kFTAnimationTop duration:0.25 delegate:nil];
        [_backView fadeIn:0.25 delegate:nil];
    } duration:0.3 completion:nil];
#else
    _tipLabel.hidden = NO;
    _tableView.hidden = NO;
    _backView.hidden = NO;
#endif
}

- (void)onTapBack:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded)
    {
        [self hide];
    }
}

- (void)hide
{
#if kSupportFTAnimation
    [self animation:^(id selfPtr) {
        [_tipLabel slideOutTo:kFTAnimationTop duration:0.25 delegate:nil];
        [_tableView slideOutTo:kFTAnimationTop duration:0.25 delegate:nil];
        [_backView fadeOut:0.25 delegate:nil];
    } duration:0.3 completion:^(id selfPtr) {
        [self removeFromSuperview];
    }];
#else
    [self removeFromSuperview];
#endif
}

- (void)relayoutFrameOfSubViews
{
    _backView.frame = self.bounds;
    
    [_tipLabel sizeWith:CGSizeMake(self.bounds.size.width, 40)];
    
    NSInteger rows = _userList.count > 7 ? 7 : _userList.count;
    [_tableView sizeWith:CGSizeMake(self.bounds.size.width, rows * kDefaultCellHeight)];
    [_tableView layoutBelow:_tipLabel];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _userList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MultiUserCell"];
    if (!cell)
    {
        cell = [[TCShowMultiUserListViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MultiUserCell"];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 65, 20)];
        [btn addTarget:self action:@selector(onClickConnect:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = btn;
    }
    
    id<AVMultiUserAble> iu = _userList[indexPath.row];
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[iu imUserIconUrl]] placeholderImage:kDefaultUserIcon];
    cell.textLabel.text = [iu imUserName];
    UIButton *btn = (UIButton *)cell.accessoryView;
    btn.tag = 1000 + indexPath.row;
    BOOL conn = [_delegate onUserListView:self isInteratcUser:iu];
    if (conn)
    {
        [btn setBackgroundImage:[UIImage imageNamed:@"disconnect"] forState:UIControlStateNormal];
    }
    else
    {
        [btn setBackgroundImage:[UIImage imageNamed:@"connection"] forState:UIControlStateNormal];
    }
    return cell;
}

- (void)onClickConnect:(UIButton *)btn
{
    NSInteger idx = btn.tag - 1000;
    id<AVMultiUserAble> user = _userList[idx];
    if ([_delegate respondsToSelector:@selector(onUserListView:clickUser:)])
    {
        [_delegate onUserListView:self clickUser:user];
    }
    
    [self hide];
}



@end
