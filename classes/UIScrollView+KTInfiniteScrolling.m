//
// UIScrollView+KTInfiniteScrolling.m
//
//  Created by Jayden Zhao on 15/6/12.
//  Copyright (c) 2015年 jayden. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+KTInfiniteScrolling.h"
#import "KTActivityIndicatorView.h"


static CGFloat const KTInfiniteScrollingViewHeight = 60;

@interface KTInfiniteScrollingDotView : UIView

@property (nonatomic, strong) UIColor *arrowColor;

@end



@interface KTInfiniteScrollingView ()

@property (nonatomic, copy) void (^infiniteScrollingHandler)(void);

@property (nonatomic, strong) KTActivityIndicatorView *activityIndicatorView;
@property (nonatomic, readwrite) KTInfiniteScrollingState state;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForInfiniteScrolling;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end



#pragma mark - UIScrollView (KTInfiniteScrollingView)
#import <objc/runtime.h>

static char UIScrollViewInfiniteScrollingView;
UIEdgeInsets scrollViewOriginalContentInsets;

@implementation UIScrollView (KTInfiniteScrolling)

@dynamic infiniteScrollingView;

- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler {
    
    if(!self.infiniteScrollingView) {
        KTInfiniteScrollingView *view = [[KTInfiniteScrollingView alloc] initWithFrame:CGRectMake(0, self.contentSize.height, self.bounds.size.width, KTInfiniteScrollingViewHeight)];
        view.infiniteScrollingHandler = actionHandler;
        view.scrollView = self;
        [self addSubview:view];
        
        view.originalBottomInset = self.contentInset.bottom;
        self.infiniteScrollingView = view;
        self.showsInfiniteScrolling = YES;
    }
}

-(void)removeInfiniteViewAndAction{
    if(self.infiniteScrollingView) {
        self.showsInfiniteScrolling = NO;
        [self.infiniteScrollingView removeFromSuperview];
        self.infiniteScrollingView = nil;
    }
}

- (void)triggerInfiniteScrolling {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.infiniteScrollingView.state = KTInfiniteScrollingStateTriggered;
        [self.infiniteScrollingView startAnimating];
    });
}

- (void)stopInfiniteToRefresh{
    [self.infiniteScrollingView stopAnimating];
}

- (void)setInfiniteScrollingView:(KTInfiniteScrollingView *)infiniteScrollingView {
    [self willChangeValueForKey:@"UIScrollViewInfiniteScrollingView"];
    objc_setAssociatedObject(self, &UIScrollViewInfiniteScrollingView,
                             infiniteScrollingView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"UIScrollViewInfiniteScrollingView"];
}

- (KTInfiniteScrollingView *)infiniteScrollingView {
    return objc_getAssociatedObject(self, &UIScrollViewInfiniteScrollingView);
}

- (void)setShowsInfiniteScrolling:(BOOL)showsInfiniteScrolling {
    self.infiniteScrollingView.hidden = !showsInfiniteScrolling;
    
    if(!showsInfiniteScrolling) {
      if (self.infiniteScrollingView.isObserving) {
        [self removeObserver:self.infiniteScrollingView forKeyPath:@"contentOffset"];
        [self removeObserver:self.infiniteScrollingView forKeyPath:@"contentSize"];
        [self.infiniteScrollingView resetScrollViewContentInset];
        self.infiniteScrollingView.isObserving = NO;
      }
    }
    else {
      if (!self.infiniteScrollingView.isObserving) {
        [self addObserver:self.infiniteScrollingView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self.infiniteScrollingView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
        [self.infiniteScrollingView setScrollViewContentInsetForInfiniteScrolling];
        self.infiniteScrollingView.isObserving = YES;
          
        [self.infiniteScrollingView setNeedsLayout];
        self.infiniteScrollingView.frame = CGRectMake(0, self.contentSize.height, self.infiniteScrollingView.bounds.size.width, KTInfiniteScrollingViewHeight);
      }
    }
}

- (BOOL)showsInfiniteScrolling {
    return !self.infiniteScrollingView.hidden;
}

@end


#pragma mark - KTInfiniteScrollingView
@implementation KTInfiniteScrollingView

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = KTInfiniteScrollingStateStopped;
        self.enabled = YES;
        
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsInfiniteScrolling) {
          if (self.isObserving) {
            [scrollView removeObserver:self forKeyPath:@"contentOffset"];
            [scrollView removeObserver:self forKeyPath:@"contentSize"];
            self.isObserving = NO;
          }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.activityIndicatorView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalBottomInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForInfiniteScrolling {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalBottomInset + KTInfiniteScrollingViewHeight;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {    
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, self.scrollView.contentSize.height, self.bounds.size.width, KTInfiniteScrollingViewHeight);
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != KTInfiniteScrollingStateLoading && self.enabled) {
        CGFloat scrollViewContentHeight = self.scrollView.contentSize.height;
        CGFloat scrollOffsetThreshold = scrollViewContentHeight-self.scrollView.bounds.size.height;
        
        if(!self.scrollView.isDragging && self.state == KTInfiniteScrollingStateTriggered)
            self.state = KTInfiniteScrollingStateLoading;
        else if(contentOffset.y > scrollOffsetThreshold && self.state == KTInfiniteScrollingStateStopped && self.scrollView.isDragging)
            self.state = KTInfiniteScrollingStateTriggered;
        else if(contentOffset.y < scrollOffsetThreshold  && self.state != KTInfiniteScrollingStateStopped)
            self.state = KTInfiniteScrollingStateStopped;
    }
}

#pragma mark - Getters

- (KTActivityIndicatorView *)activityIndicatorView {
    if(!_activityIndicatorView) {
        _activityIndicatorView = [[KTActivityIndicatorView alloc] initWithType:KTActivityIndicatorAnimationTypeBallBeat tintColor:[UIColor colorWithRed:41/255.0f green:182/255.0f blue:246/255.0f alpha:1]];
        [self addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}

#pragma mark - Setters

- (void)setCustomView:(UIView *)view forState:(KTInfiniteScrollingState)state {
    id viewPlaceholder = view;
    
    if(!viewPlaceholder)
        viewPlaceholder = @"";
    
    if(state == KTInfiniteScrollingStateAll)
        [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
    else
        [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    
    self.state = self.state;
}

#pragma mark -

- (void)triggerRefresh {
    self.state = KTInfiniteScrollingStateTriggered;
    self.state = KTInfiniteScrollingStateLoading;
}

- (void)startAnimating{
    self.state = KTInfiniteScrollingStateLoading;
}

- (void)stopAnimating {
    self.state = KTInfiniteScrollingStateStopped;
}

- (void)setState:(KTInfiniteScrollingState)newState {
    
    if(_state == newState)
        return;
    
    KTInfiniteScrollingState previousState = _state;
    _state = newState;
    
    for(id otherView in self.viewForState) {
        if([otherView isKindOfClass:[UIView class]])
            [otherView removeFromSuperview];
    }
    
    id customView = [self.viewForState objectAtIndex:newState];
    BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
    
    if(hasCustomView) {
        [self addSubview:customView];
        CGRect viewBounds = [customView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    }
    else {
        CGRect viewBounds = [self.activityIndicatorView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [self.activityIndicatorView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
        
        switch (newState) {
            case KTInfiniteScrollingStateStopped:
                [self.activityIndicatorView stopAnimating];
                self.activityIndicatorView.hidden = YES;
                break;
                
            case KTInfiniteScrollingStateTriggered:
                self.activityIndicatorView.hidden = NO;
                [self.activityIndicatorView startAnimating];
                break;
                
            case KTInfiniteScrollingStateLoading:
                self.activityIndicatorView.hidden = NO;
                [self.activityIndicatorView startAnimating];
                break;
        }
    }
    
    if(previousState == KTInfiniteScrollingStateTriggered && newState == KTInfiniteScrollingStateLoading && self.infiniteScrollingHandler && self.enabled)
        self.infiniteScrollingHandler();
}

@end
