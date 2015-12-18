//
//  KTActivityIndicatorView.h
//  buxuxiao
//
//  Created by Jayden Zhao on 15/8/26.
//  Copyright (c) 2015年 jayden. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, KTActivityIndicatorAnimationType) {
    KTActivityIndicatorAnimationTypeDoubleBounce,
    KTActivityIndicatorAnimationTypeBallBeat
};

@protocol KTActivityIndicatorAnimationProtocol <NSObject>

- (void)setupAnimationInLayer:(CALayer *)layer withSize:(CGSize)size tintColor:(UIColor *)tintColor;

@end

@interface KTActivityIndicatorView : UIView
- (id)initWithType:(KTActivityIndicatorAnimationType)type;
- (id)initWithType:(KTActivityIndicatorAnimationType)type tintColor:(UIColor *)tintColor;
- (id)initWithType:(KTActivityIndicatorAnimationType)type tintColor:(UIColor *)tintColor size:(CGFloat)size;

@property (nonatomic) KTActivityIndicatorAnimationType type;

@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic) CGFloat size;

@property (nonatomic, readonly) BOOL animating;

- (void)startAnimating;
- (void)stopAnimating;
@end
