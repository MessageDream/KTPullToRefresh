//
// UIScrollView+KTPullToRefresh.h
//
//  Created by Jayden Zhao on 15/6/12.
//  Copyright (c) 2015年 jayden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>


@class KTPullToRefreshView;

@interface UIScrollView (KTPullToRefresh)

typedef NS_ENUM(NSUInteger, KTPullToRefreshPosition) {
    KTPullToRefreshPositionTop = 0,
    KTPullToRefreshPositionBottom,
};

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler position:(KTPullToRefreshPosition)position;
- (void)removePullRefreshView;
- (void)triggerPullToRefresh;
- (void)stopPullToRefresh;

@property (nonatomic, strong, readonly) KTPullToRefreshView *pullToRefreshView;
@property (nonatomic, assign) BOOL showsPullToRefresh;

@end


typedef NS_ENUM(NSUInteger, KTPullToRefreshState) {
    KTPullToRefreshStateStopped = 0,
    KTPullToRefreshStateBeginDrag,
    KTPullToRefreshStateTriggered,
    KTPullToRefreshStateLoading,
    KTPullToRefreshStateAll = 10
};

@interface KTPullToRefreshView : UIView

@property (nonatomic, strong) UIColor *activityIndicatorViewTinColor;

@property (nonatomic, readonly) KTPullToRefreshState state;
@property (nonatomic, readonly) KTPullToRefreshPosition position;

- (void)setCustomView:(UIView *)view forState:(KTPullToRefreshState)state;

- (void)startAnimating;
- (void)stopAnimating;

@end
