//
// UIScrollView+KTPullToRefresh.m
//
//  Created by Jayden Zhao on 15/6/12.
//  Copyright (c) 2015年 jayden. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+KTPullToRefresh.h"
#import "KTActivityIndicatorView.h"

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static CGFloat const KTPullToRefreshViewHeight = 60;

@interface KTPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

@property (nonatomic, strong) KTActivityIndicatorView *activityIndicatorView;
@property (nonatomic, readwrite) KTPullToRefreshState state;
@property (nonatomic, readwrite) KTPullToRefreshPosition position;

@property (nonatomic, strong) NSMutableArray *viewForState;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;

@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property(nonatomic, assign) BOOL isObserving;
@property(nonatomic, assign) CGRect arrowRect;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;
- (void)scaleArrow:(float)degrees opacity:(float)opacity;

@end

#pragma mark - KTPullToRefresh
@implementation KTPullToRefreshView

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = KTPullToRefreshStateStopped;
        
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
        self.wasTriggeredByUser = YES;
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "KTPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for(id otherView in self.viewForState) {
        if([otherView isKindOfClass:[UIView class]])
            [otherView removeFromSuperview];
    }
    
    id customView = [self.viewForState objectAtIndex:self.state];
    BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
    
    self.activityIndicatorView.hidden = hasCustomView;
    
    if(hasCustomView) {
        [self addSubview:customView];
        CGRect viewBounds = [customView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    }
    else {
        switch (self.state) {
            case KTPullToRefreshStateAll:
            case KTPullToRefreshStateStopped:
                [self.activityIndicatorView stopAnimating];
                break;
            case KTPullToRefreshStateBeginDrag:
                 [self.activityIndicatorView startAnimating];
                break;
            case KTPullToRefreshStateTriggered:
                break;
                
            case KTPullToRefreshStateLoading:
                [self.activityIndicatorView startAnimating];
                break;
        }
        
        CGFloat arrowX = (self.bounds.size.width / 2) -  self.activityIndicatorView.bounds.size.width/ 2;
        self.activityIndicatorView.frame = CGRectMake(arrowX,
                                                      (self.bounds.size.height / 2) - (self.activityIndicatorView.bounds.size.height / 2),
                                                      self.activityIndicatorView.bounds.size.width,
                                                      self.activityIndicatorView.bounds.size.height);
    }
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case KTPullToRefreshPositionTop:
            currentInsets.top = self.originalTopInset;
            break;
        case KTPullToRefreshPositionBottom:
            currentInsets.bottom = self.originalBottomInset;
            currentInsets.top = self.originalTopInset;
            break;
    }
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case KTPullToRefreshPositionTop:
            currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
            break;
        case KTPullToRefreshPositionBottom:
            currentInsets.bottom = MIN(offset, self.originalBottomInset + self.bounds.size.height);
            break;
    }
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
        
        CGFloat yOrigin;
        switch (self.position) {
            case KTPullToRefreshPositionTop:
                yOrigin = -KTPullToRefreshViewHeight;
                break;
            case KTPullToRefreshPositionBottom:
                yOrigin = MAX(self.scrollView.contentSize.height, self.scrollView.bounds.size.height);
                break;
        }
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, KTPullToRefreshViewHeight);
    }
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];
    
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != KTPullToRefreshStateLoading) {
        CGFloat scrollOffsetThreshold = 0;
        switch (self.position) {
            case KTPullToRefreshPositionTop:
                scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
                break;
            case KTPullToRefreshPositionBottom:
                scrollOffsetThreshold = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.bounds.size.height + self.originalBottomInset;
                break;
        }
        if (self.state != KTPullToRefreshStateTriggered) {
//            CGFloat v = fabs(contentOffset.y);
//            CGFloat abs = fabs(v - KTPullToRefreshViewHeight)/KTPullToRefreshViewHeight;
//            CGFloat bili = abs > 0.2?abs:0.2;
//            [self scaleArrow:bili opacity:abs > 0.5?abs:1];
        }
       
        if(!self.scrollView.isDragging
           && self.state == KTPullToRefreshStateTriggered){
            
            self.state = KTPullToRefreshStateLoading;
            
        }
    
        if (self.position == KTPullToRefreshPositionTop) {
             if(contentOffset.y < scrollOffsetThreshold
                     && self.scrollView.isDragging
                     && self.state == KTPullToRefreshStateBeginDrag){
                
                self.state = KTPullToRefreshStateTriggered;
                
             }else if(contentOffset.y >= scrollOffsetThreshold
                      && self.state == KTPullToRefreshStateStopped && self.scrollView.isDragging){
                 
                 self.state = KTPullToRefreshStateBeginDrag;
                 
             }else if(contentOffset.y >= scrollOffsetThreshold
                     && self.state != KTPullToRefreshStateStopped){
                
//                self.state = KTPullToRefreshStateStopped;
                
            }
        }else{
            if(contentOffset.y > scrollOffsetThreshold
               && self.scrollView.isDragging
               && self.state == KTPullToRefreshStateStopped){
                
                self.state = KTPullToRefreshStateTriggered;
            }else if(contentOffset.y <= scrollOffsetThreshold
                     && self.state != KTPullToRefreshStateStopped){
                
                self.state = KTPullToRefreshStateStopped;
            }
        }
        
    } else {
        CGFloat offset;
        UIEdgeInsets contentInset;
        switch (self.position) {
            case KTPullToRefreshPositionTop:
                offset = MAX(self.scrollView.contentOffset.y * -1, 0.0f);
                offset = MIN(offset, self.originalTopInset + self.bounds.size.height);
                contentInset = self.scrollView.contentInset;
                self.scrollView.contentInset = UIEdgeInsetsMake(offset, contentInset.left, contentInset.bottom, contentInset.right);
                break;
            case KTPullToRefreshPositionBottom:
                if (self.scrollView.contentSize.height >= self.scrollView.bounds.size.height) {
                    offset = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.bounds.size.height, 0.0f);
                    offset = MIN(offset, self.originalBottomInset + self.bounds.size.height);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(contentInset.top, contentInset.left, offset, contentInset.right);
                } else if (self.wasTriggeredByUser) {
                    offset = MIN(self.bounds.size.height, self.originalBottomInset + self.bounds.size.height);
                    contentInset = self.scrollView.contentInset;
                    self.scrollView.contentInset = UIEdgeInsetsMake(-offset, contentInset.left, contentInset.bottom, contentInset.right);
                }
                break;
        }
    }
}

#pragma mark - Getters
-(KTActivityIndicatorView *)activityIndicatorView{
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[KTActivityIndicatorView alloc] initWithType:KTActivityIndicatorAnimationTypeDoubleBounce tintColor:[UIColor colorWithRed:41/255.0f green:182/255.0f blue:246/255.0f alpha:1]];
        [self addSubview:_activityIndicatorView];
//        _activityIndicatorView.frame = CGRectMake(10,10 ,self.bounds.size.height/3, self.bounds.size.height/3);
    }
    return _activityIndicatorView;
}

-(UIColor *)activityIndicatorViewTinColor{
    return self.activityIndicatorView.tintColor;
}

#pragma mark - Setters
-(void)setActivityIndicatorViewTinColor:(UIColor *)activityIndicatorViewTinColor{
    self.activityIndicatorView.tintColor = activityIndicatorViewTinColor;
}

- (void)setCustomView:(UIView *)view forState:(KTPullToRefreshState)state {
    id viewPlaceholder = view;
    
    if(!viewPlaceholder)
        viewPlaceholder = @"";
    
    if(state == KTPullToRefreshStateAll)
        [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
    else
        [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    
    [self setNeedsLayout];
}

#pragma mark -

- (void)triggerRefresh {
    [self.scrollView triggerPullToRefresh];
}

- (void)startAnimating{
    switch (self.position) {
        case KTPullToRefreshPositionTop:
            
            if(fequalzero(self.scrollView.contentOffset.y)) {
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.frame.size.height) animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
        case KTPullToRefreshPositionBottom:
            
            if((fequalzero(self.scrollView.contentOffset.y) && self.scrollView.contentSize.height < self.scrollView.bounds.size.height)
               || fequal(self.scrollView.contentOffset.y, self.scrollView.contentSize.height - self.scrollView.bounds.size.height)) {
                [self.scrollView setContentOffset:(CGPoint){.y = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height, 0.0f) + self.frame.size.height} animated:YES];
                self.wasTriggeredByUser = NO;
            }
            else
                self.wasTriggeredByUser = YES;
            
            break;
    }
    
    self.state = KTPullToRefreshStateLoading;
}

- (void)stopAnimating {
    self.state = KTPullToRefreshStateStopped;
    
    switch (self.position) {
        case KTPullToRefreshPositionTop:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalTopInset) animated:YES];
            break;
        case KTPullToRefreshPositionBottom:
            if(!self.wasTriggeredByUser)
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.originalBottomInset) animated:YES];
            break;
    }
}

- (void)setState:(KTPullToRefreshState)newState {
    
    if(_state == newState)
        return;
    
    KTPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case KTPullToRefreshStateAll:
        case KTPullToRefreshStateStopped:
            [self resetScrollViewContentInset];
            break;
            
        case KTPullToRefreshStateBeginDrag:
        case KTPullToRefreshStateTriggered:
            break;
            
        case KTPullToRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == KTPullToRefreshStateTriggered && _pullToRefreshActionHandler)
                _pullToRefreshActionHandler();
            
            break;
    }
}

- (void)scaleArrow:(float)degrees opacity:(float)opacity {
    if (degrees > 1) {
        degrees = 1;
    }
    
    degrees = ((1- degrees)== 0?1:(1- degrees));
    opacity = ((1- opacity)== 0?1:(1- opacity));
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction  animations:^{
        self.activityIndicatorView.layer.opacity = opacity;
        CGRect rect = self.activityIndicatorView.bounds;
        rect.size.width = rect.size.height = _arrowRect.size.width *degrees;
        self.activityIndicatorView.bounds = rect;
    } completion:nil];
}

@end

#pragma mark - UIScrollView (KTPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (KTPullToRefresh)

@dynamic pullToRefreshView, showsPullToRefresh;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler position:(KTPullToRefreshPosition)position {
    
    if(!self.pullToRefreshView) {
        CGFloat yOrigin;
        switch (position) {
            case KTPullToRefreshPositionTop:
                yOrigin = -KTPullToRefreshViewHeight;
                break;
            case KTPullToRefreshPositionBottom:
                yOrigin = self.contentSize.height;
                break;
            default:
                return;
        }
        KTPullToRefreshView *view = [[KTPullToRefreshView alloc] initWithFrame:CGRectMake(0, yOrigin, self.bounds.size.width, KTPullToRefreshViewHeight)];
//        view.backgroundColor = [UIColor redColor];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        view.originalBottomInset = self.contentInset.bottom;
        view.position = position;
        self.pullToRefreshView = view;
        self.showsPullToRefresh = YES;
    }
    
}

- (void)removePullRefreshView{
    if (self.pullToRefreshView) {
        self.showsPullToRefresh = NO;
        [self.pullToRefreshView removeFromSuperview];
        self.pullToRefreshView = nil;
    }
}

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler {
    [self addPullToRefreshWithActionHandler:actionHandler position:KTPullToRefreshPositionTop];
}

- (void)triggerPullToRefresh {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.pullToRefreshView.state = KTPullToRefreshStateTriggered;
        [self.pullToRefreshView startAnimating];
    });
}

- (void)stopPullToRefresh{
    [self.pullToRefreshView stopAnimating];
}

- (void)setPullToRefreshView:(KTPullToRefreshView *)pullToRefreshView {
    [self willChangeValueForKey:@"KTPullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"KTPullToRefreshView"];
}

- (KTPullToRefreshView *)pullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    self.pullToRefreshView.hidden = !showsPullToRefresh;
    
    if(!showsPullToRefresh) {
        if (self.pullToRefreshView.isObserving) {
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentSize"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
            [self.pullToRefreshView resetScrollViewContentInset];
            self.pullToRefreshView.isObserving = NO;
        }
    }
    else {
        if (!self.pullToRefreshView.isObserving) {
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.pullToRefreshView.isObserving = YES;
            
            CGFloat yOrigin = 0;
            switch (self.pullToRefreshView.position) {
                case KTPullToRefreshPositionTop:
                    yOrigin = -KTPullToRefreshViewHeight;
                    break;
                case KTPullToRefreshPositionBottom:
                    yOrigin = self.contentSize.height;
                    break;
            }
            
            self.pullToRefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, KTPullToRefreshViewHeight);
        }
    }
}

- (BOOL)showsPullToRefresh {
    return !self.pullToRefreshView.hidden;
}

@end


