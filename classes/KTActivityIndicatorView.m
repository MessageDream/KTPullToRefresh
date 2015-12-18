//
//  KTActivityIndicatorView.m
//  buxuxiao
//
//  Created by Jayden Zhao on 15/8/26.
//  Copyright (c) 2015年 jayden. All rights reserved.
//

#import "KTActivityIndicatorView.h"

static const CGFloat kKTActivityIndicatorDefaultSize = 30.0f;

@interface KTActivityIndicatorDoubleBounceAnimation : NSObject <KTActivityIndicatorAnimationProtocol>

@end

@implementation KTActivityIndicatorDoubleBounceAnimation

#pragma mark -
#pragma mark KTActivityIndicatorAnimation Protocol

- (void)setupAnimationInLayer:(CALayer *)layer withSize:(CGSize)size tintColor:(UIColor *)tintColor {
    NSTimeInterval beginTime = CACurrentMediaTime();
    
    CGFloat oX = (layer.bounds.size.width - size.width) / 2.0f;
    CGFloat oY = (layer.bounds.size.height - size.height) / 2.0f;
    for (int i = 0; i < 2; i++) {
        CALayer *circle = [CALayer layer];
        circle.frame = CGRectMake(oX, oY, size.width, size.height);
        circle.anchorPoint = CGPointMake(0.5f, 0.5f);
        circle.opacity = 0.5f;
        circle.cornerRadius = size.height / 2.0f;
        circle.transform = CATransform3DMakeScale(0.0f, 0.0f, 0.0f);
        circle.backgroundColor = tintColor.CGColor;
        
        CAKeyframeAnimation *transformAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
        transformAnimation.removedOnCompletion = NO;
        transformAnimation.repeatCount = HUGE_VALF;
        transformAnimation.duration = 2.0f;
        transformAnimation.beginTime = beginTime - (1.0f * i);
        transformAnimation.keyTimes = @[@(0.0f), @(0.5f), @(1.0f)];
        
        transformAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                               [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                               [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        
        transformAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.0f, 0.0f, 0.0f)],
                                      [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 0.0f)],
                                      [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.0f, 0.0f, 0.0f)]];
        
        [layer addSublayer:circle];
        [circle addAnimation:transformAnimation forKey:@"animation"];
    }
    
}

@end


@interface KTActivityIndicatorBallBeatAnimation : NSObject <KTActivityIndicatorAnimationProtocol>

@end

@implementation KTActivityIndicatorBallBeatAnimation

- (void)setupAnimationInLayer:(CALayer *)layer withSize:(CGSize)size tintColor:(UIColor *)tintColor {
    CGFloat duration = 0.7f;
    NSArray *beginTimes = @[@0.35f, @0.0f, @0.35f];
    CGFloat circleSpacing = 2.0f;
    CGFloat circleSize = (size.width - circleSpacing * 2) / 3;
    CGFloat x = (layer.bounds.size.width - size.width) / 2;
    CGFloat y = (layer.bounds.size.height - circleSize) / 2;
    
    // Scale animation
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    scaleAnimation.duration = duration;
    scaleAnimation.keyTimes = @[@0.0f, @0.5f, @1.0f];
    scaleAnimation.values = @[@1.0f, @0.75f, @1.0f];
    
    // Opacity animation
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    
    opacityAnimation.duration = duration;
    opacityAnimation.keyTimes = @[@0.0f, @0.5f, @1.0f];
    opacityAnimation.values = @[@1.0f, @0.2f, @1.0f];
    
    // Aniamtion
    CAAnimationGroup *animation = [CAAnimationGroup animation];
    
    animation.duration = duration;
    animation.animations = @[scaleAnimation, opacityAnimation];
    animation.repeatCount = HUGE_VALF;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.removedOnCompletion = NO;

    // Draw circles
    for (int i = 0; i < 3; i++) {
        CAShapeLayer *circle = [CAShapeLayer layer];
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, circleSize, circleSize) cornerRadius:circleSize / 2];
        
        animation.beginTime = [beginTimes[i] floatValue];
        circle.fillColor = tintColor.CGColor;
        circle.path = circlePath.CGPath;
        [circle addAnimation:animation forKey:@"animation"];
        circle.frame = CGRectMake(x + circleSize * i + circleSpacing * i, y, circleSize, circleSize);
        [layer addSublayer:circle];
    }
}

@end


@implementation KTActivityIndicatorView

#pragma mark -
#pragma mark Constructors


- (id)initWithType:(KTActivityIndicatorAnimationType)type {
    return [self initWithType:type tintColor:[UIColor whiteColor] size:kKTActivityIndicatorDefaultSize];
}

- (id)initWithType:(KTActivityIndicatorAnimationType)type tintColor:(UIColor *)tintColor {
    return [self initWithType:type tintColor:tintColor size:kKTActivityIndicatorDefaultSize];
}

- (id)initWithType:(KTActivityIndicatorAnimationType)type tintColor:(UIColor *)tintColor size:(CGFloat)size {
    self = [super init];
    if (self) {
        _type = type;
        _size = size;
        _tintColor = tintColor;
    }
    return self;
}

#pragma mark -
#pragma mark Methods

- (void)setupAnimation {
    self.layer.sublayers = nil;
    
    id<KTActivityIndicatorAnimationProtocol> animation = [KTActivityIndicatorView activityIndicatorAnimationForAnimationType:_type];
    
    if ([animation respondsToSelector:@selector(setupAnimationInLayer:withSize:tintColor:)]) {
        [animation setupAnimationInLayer:self.layer withSize:CGSizeMake(_size, _size) tintColor:_tintColor];
        self.layer.speed = 0.0f;
    }
}

- (void)startAnimating {
    if (!self.layer.sublayers) {
        [self setupAnimation];
    }
    self.layer.speed = 1.0f;
    _animating = YES;
}

- (void)stopAnimating {
//    self.layer.speed = 0.0f;
    _animating = NO;
}

#pragma mark -
#pragma mark Setters
- (void)setType:(KTActivityIndicatorAnimationType)type {
    if (_type != type) {
        _type = type;
        
        [self setupAnimation];
    }
}

- (void)setSize:(CGFloat)size {
    if (_size != size) {
        _size = size;
        
        [self setupAnimation];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    if (![_tintColor isEqual:tintColor]) {
        _tintColor = tintColor;
        
        for (CALayer *sublayer in self.layer.sublayers) {
            sublayer.backgroundColor = tintColor.CGColor;
        }
    }
}



#pragma mark -
#pragma mark Getters

+ (id<KTActivityIndicatorAnimationProtocol>)activityIndicatorAnimationForAnimationType:(KTActivityIndicatorAnimationType)type {
    switch (type) {
        case KTActivityIndicatorAnimationTypeDoubleBounce:
            return [[KTActivityIndicatorDoubleBounceAnimation alloc] init];
        case KTActivityIndicatorAnimationTypeBallBeat:
            return [[KTActivityIndicatorBallBeatAnimation alloc] init];
    }
    return nil;
}
@end


