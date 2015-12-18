//
// UIScrollView+KTInfiniteScrolling.h
//
//  Created by Jayden Zhao on 15/6/12.
//  Copyright (c) 2015年 jayden. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KTInfiniteScrollingView;

@interface UIScrollView (KTInfiniteScrolling)

- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler;
- (void)removeInfiniteViewAndAction;
- (void)triggerInfiniteScrolling;
- (void)stopInfiniteToRefresh;

@property (nonatomic, strong, readonly) KTInfiniteScrollingView *infiniteScrollingView;
@property (nonatomic, assign) BOOL showsInfiniteScrolling;

@end


enum {
	KTInfiniteScrollingStateStopped = 0,
    KTInfiniteScrollingStateTriggered,
    KTInfiniteScrollingStateLoading,
    KTInfiniteScrollingStateAll = 10
};

typedef NSUInteger KTInfiniteScrollingState;

@interface KTInfiniteScrollingView : UIView

@property (nonatomic, readonly) KTInfiniteScrollingState state;
@property (nonatomic, readwrite) BOOL enabled;

- (void)setCustomView:(UIView *)view forState:(KTInfiniteScrollingState)state;

- (void)startAnimating;
- (void)stopAnimating;

@end
