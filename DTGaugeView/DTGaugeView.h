//
//  DTGaugeView.h
//  DTGaugeView
//
//  Created by André Reinecke on 19.06.15.
//  Copyright (c) 2015 André Reinecke. All rights reserved.
// --> inspired by SFGaugeView --> see: https://github.com/simpliflow/SFGaugeView (is distributed under the MIT License.)

#import <UIKit/UIKit.h>

//! Project version number for DTGaugeView.
FOUNDATION_EXPORT double DTGaugeViewVersionNumber;

//! Project version string for DTGaugeView.
FOUNDATION_EXPORT const unsigned char DTGaugeViewVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DTGaugeView/PublicHeader.h>

IB_DESIGNABLE
@interface DTGaugeView : UIView

// Min/Max labels
@property (nonatomic) IBInspectable CGFloat             maxlevel;
@property (nonatomic) IBInspectable CGFloat             minlevel;
@property (nonatomic) IBInspectable BOOL                hideMinMaxLabels;
@property (nonatomic) IBInspectable CGFloat             minMaxTextSize;
@property (nonatomic) IBInspectable UIColor             *minimumTextColor;
@property (nonatomic) IBInspectable UIColor             *maximumTextColor;
@property (nonatomic) IBInspectable BOOL                showMinMaxLabelsAsCircle;
@property (nonatomic) IBInspectable UIColor             *minBackgroundColor;
@property (nonatomic) IBInspectable UIColor             *maxBackgroundColor;
@property (nonatomic) IBInspectable CGFloat             minMaxLabelAlpha;

// Needle label
@property (nonatomic) IBInspectable CGFloat             needleTextSize;
@property (nonatomic) IBInspectable UIColor             *needleTextColor;

// Needle
@property (nonatomic) IBInspectable CGFloat             needleWidth;
@property (nonatomic) IBInspectable UIColor             *needleColor;
@property (nonatomic) IBInspectable UIColor             *needleStrokeColor;
@property (nonatomic) IBInspectable CGFloat             currentNeedleLevel;
@property (nonatomic) IBInspectable CGFloat             needleOpacity;

// Unit label
@property (nonatomic) IBInspectable NSString            *unit;
@property (nonatomic) IBInspectable BOOL                hideUnitLabel;
@property (nonatomic) IBInspectable UIColor             *unitTextColor;
@property (nonatomic) IBInspectable UIColor             *unitBackgroundColor;
@property (nonatomic) IBInspectable CGFloat             unitTextSize;
@property (nonatomic) IBInspectable BOOL                showUnitLabelAsCircle;

// Arc
@property (nonatomic) IBInspectable UIColor             *arcBackgroundColor;
@property (nonatomic) IBInspectable NSArray             *arcGradientColors;
@property (nonatomic) IBInspectable CGFloat               arcWidth;

// Border of needle view
@property (nonatomic) IBInspectable CGFloat             needleViewBorderWidth;
@property (nonatomic) IBInspectable UIColor             *needleViewBorderColor;

// etc
@property (nonatomic) IBInspectable BOOL                isGivenInDegrees;
//@property (nonatomic) IBInspectable BOOL                shouldHanldeTouches;

@end

