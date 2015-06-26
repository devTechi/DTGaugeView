//
//  DTTGaugeView.m
//  DTTGaugeView
//
//  Created by André Reinecke on 19.06.15.
//  Copyright (c) 2015 André Reinecke. All rights reserved.
// --> inspired by SFGaugeView --> see: https://github.com/simpliflow/SFGaugeView (is distributed under the MIT License.)

#import "DTGaugeView.h"
#import <QuartzCore/QuartzCore.h>

@interface DTGaugeView()

@property (nonatomic) CGFloat needleRadius;
@property (nonatomic) CGFloat arcRadius;
@property (nonatomic) CGFloat currentRadian;
@property (nonatomic) CGFloat oldLevel;

@property (nonatomic) UIView *needleView;   // view on which the needle is drawn --> this view will be animated
@property (nonatomic) CAShapeLayer *needleLayer;    // needle ShapeLayer

@property (nonatomic) UILabel *lblNeedleValue;
@property (nonatomic) UILabel *lblMinimum;
@property (nonatomic) UILabel *lblMaximum;

@property (nonatomic) UILabel *lblUnit;

//@property (nonatomic) BOOL isFirstStart;

@end

// Degrees to radians
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
// Radians to degrees
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
static const CGFloat CUTOFF                 = 0.5;
static const CGFloat starttime              = M_PI + CUTOFF;
static const CGFloat endtime                = 2 * M_PI - CUTOFF;
static const CGFloat zeroNeedleValue        = starttime + DEGREES_TO_RADIANS(90);
static const CGFloat highestNeedleValue     = endtime + DEGREES_TO_RADIANS(90);
static const CGFloat divisorNeedleValue     = highestNeedleValue - zeroNeedleValue;
#define kScalaAnimation @"ScalaAnimation"
#define kNeedleAnimation @"needleAnimation"

NSNumberFormatter *formatter;
// TODO: delete
//NSDictionary* stringAttrs;

#pragma mark - Begin of implementation
@implementation DTGaugeView

//@synthesize needleTextFontSize = _needleTextFontSize;
//@synthesize lblMinMaxTextFontSize = _lblMinMaxTextFontSize;

- (id) init
{
    self = [super init];
    // TODO: delete
    //self.isFirstStart = YES;
    [self setup];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.userInteractionEnabled = NO;
    self.opaque = NO;
    self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor clearColor];
    
    // init the NumberFormatter for the labels
    formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:2];
    [formatter setRoundingMode: NSNumberFormatterRoundDown];
    
    // TODO: delete
    /*UIFont* font = [UIFont fontWithName:@"Arial" size:self.needleTextFontSize];
    UIColor* textColor = [UIColor whiteColor];
    stringAttrs = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : textColor };*/
    
    if (self.arcWidth < 10) {
        self.arcWidth = 10;
    }
    
    self.oldLevel = self.currentRadian = zeroNeedleValue;
    self.needleOpacity = self.minMaxLabelAlpha = 1.0f;
    // TODO: delete
    //[self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];
}

- (void) awakeFromNib
{
    [self setup];
}

#pragma mark - drawing

- (void)drawRect:(CGRect)rect
{
    [self drawBg];
    [self drawNeedle];
    [self drawNeedleLabel];
    [self drawMinMaxLabels];
    [self drawUnitLabel];
}

- (void) drawBg
{
    CGFloat bgEndAngle = (3 * M_PI_2) + self.currentRadian;
    
    if (bgEndAngle > starttime) {
        CAShapeLayer *arc = [CAShapeLayer layer];
        
        //self.clipsToBounds = YES;
        UIBezierPath *bgPath = [UIBezierPath bezierPath];
        
        [bgPath addArcWithCenter:[self center]
                          radius:self.arcRadius
                      startAngle:endtime
                        endAngle:starttime
                       clockwise:NO];
        arc.path = [bgPath CGPath];
        
        arc.fillColor = [UIColor clearColor].CGColor;
        arc.strokeColor = [UIColor purpleColor].CGColor;
        arc.lineWidth = self.arcWidth;
        
        /*if (!self.isFirstStart) {
            CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            drawAnimation.duration            = 2.5; // "animate over 10 seconds or so.."
            drawAnimation.repeatCount         = 1.0;  // Animate only once..
            drawAnimation.removedOnCompletion = NO;   // Remain stroked after the animation..
            ///////////////////
            drawAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
            drawAnimation.toValue   = [NSNumber numberWithFloat:5.0f];
            ///////////////////
            drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
            [arc addAnimation:drawAnimation forKey:kScalaAnimation];
        }*/
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = self.bounds;
        // set colors to the arc
        if (self.arcBackgroundColor) {
            gradientLayer.backgroundColor = self.arcBackgroundColor.CGColor;
        }
        
        if (self.arcGradientColors) {
            gradientLayer.colors = self.arcGradientColors;
        }
        
        gradientLayer.startPoint = CGPointMake(0,0.5);
        gradientLayer.endPoint = CGPointMake(1,0.5);
        
        gradientLayer.mask = arc;
        // bring this layer to background, so that the needle is above it
        gradientLayer.zPosition = -5;
        [self.layer addSublayer:gradientLayer];
    }
}

- (void) drawNeedle
{
    if (!self.needleLayer) {
        // setup the view on which the needle is drawn
        if (!self.needleView) {
            self.needleView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       self.frame.size.width,
                                                                       self.frame.size.height)];
            self.needleView.backgroundColor = [UIColor clearColor];
            
            self.lblNeedleValue = [[UILabel alloc]initWithFrame:CGRectMake(self.center.x - (self.arcRadius/4),
                                                                       self.center.y - (self.arcRadius/4),
                                                                       self.arcRadius/2, self.arcRadius/2)];
            self.lblNeedleValue.backgroundColor = [UIColor clearColor];
            self.lblNeedleValue.textAlignment = NSTextAlignmentCenter;
            [self.needleView addSubview:self.lblNeedleValue];
            [self.needleView bringSubviewToFront:self.lblNeedleValue];
        }
        
        CGPoint center = [self center]; //CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        
        //self.needleRadius = self.bounds.size.height * 0.08;
        self.needleRadius = self.needleWidth;
        CGFloat bgRadius = center.x - (center.x * 0.1);
        CGFloat distance = bgRadius - (bgRadius * 0.05);//+ (bgRadius * 0.1);
        CGFloat nStarttime = 0;
        CGFloat nEndtime = M_PI;
        CGFloat topSpace = (distance * 0.1)/6;
        
        CGPoint topPoint = CGPointMake(center.x, center.y - distance);
        CGPoint topPoint1 = CGPointMake(center.x - topSpace, center.y - distance + (distance * 0.1));
        CGPoint topPoint2 = CGPointMake(center.x + topSpace, center.y - distance + (distance * 0.1));
        
        CGPoint finishPoint = CGPointMake(center.x + self.needleRadius, center.y);
        
        UIBezierPath *needlePath = [UIBezierPath bezierPath]; //empty path
        //[needlePath moveToPoint:CGPointMake(0, 0)];//center];
        CGPoint next;
        next.x = center.x + self.needleRadius * cos(nStarttime);
        next.y = center.y + self.needleRadius * sin(nStarttime);
        [needlePath addLineToPoint:next]; //go one end of arc
        [needlePath addArcWithCenter:center radius:self.needleRadius startAngle:nStarttime endAngle:nEndtime clockwise:YES]; //add the arc
        
        [needlePath addLineToPoint:topPoint1];
        
        [needlePath addQuadCurveToPoint:topPoint2 controlPoint:topPoint];
        
        [needlePath addLineToPoint:finishPoint];
        
        CGAffineTransform translate = CGAffineTransformMakeTranslation(-1 * (self.needleView.bounds.origin.x + [self.needleView center].x), -1 * (self.needleView.bounds.origin.y + [self.needleView center].y));
        [needlePath applyTransform:translate];
        
        translate = CGAffineTransformMakeTranslation((self.needleView.bounds.origin.x + [self.needleView center].x), (self.needleView.bounds.origin.y + [self.needleView center].y));
        [needlePath applyTransform:translate];
        
        [[UIColor colorWithRed:76/255.0 green:177/255.0 blue:88/255.0 alpha:1] set];
        //[needlePath fill];
        
        self.needleLayer = [CAShapeLayer layer];
        self.needleLayer.path = [needlePath CGPath];
        
        self.needleLayer.strokeColor = [self needleStrokeColor].CGColor;//[[UIColor colorWithRed:76/255.0 green:177/255.0 blue:88/255.0 alpha:1] CGColor];
        self.needleLayer.fillColor = [self needleColor].CGColor; //[[UIColor colorWithRed:76/255.0 green:177/255.0 blue:88/255.0 alpha:1] CGColor];
        self.needleLayer.lineWidth = 1.5f;
        self.needleLayer.lineJoin = kCALineJoinBevel;
        self.needleLayer.opacity = self.needleOpacity;
        
        [self.needleView.layer addSublayer:self.needleLayer];
        ///////////////
        self.needleView.layer.borderColor = self.needleViewBorderColor.CGColor;
        self.needleView.layer.borderWidth = self.needleViewBorderWidth;  //5.0f;
        ///////////////
        
        [self addSubview:self.needleView];
    }
    else {
        // bring layer in front of the arc/bow, which is drawn at the top of the view
        self.needleLayer.zPosition = 0;
    }
    
    CABasicAnimation *needleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    //spinAnimation.byValue = [NSNumber numberWithFloat:2.0f*M_PI];
    needleAnimation.duration = 0.7f;
    needleAnimation.removedOnCompletion = NO;
    needleAnimation.fillMode = kCAFillModeForwards;
    
    NSLog(@"%.8f - %.8f - %.8f - %.8f", zeroNeedleValue, highestNeedleValue, divisorNeedleValue, self.currentRadian);
    
    needleAnimation.fromValue = [NSNumber numberWithFloat:self.oldLevel];
    needleAnimation.toValue = [NSNumber numberWithFloat:self.currentRadian];
    
    [self.needleView.layer addAnimation:needleAnimation forKey:kNeedleAnimation];
}

- (void) drawNeedleLabel
{
    NSMutableAttributedString* levelStr = [[NSMutableAttributedString alloc] initWithString:[formatter stringFromNumber:[NSNumber numberWithFloat:(float)[self currentNeedleLevel]]]];
    
    if (self.isGivenInDegrees) {
        [levelStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"°"]];
    }
    
    self.lblNeedleValue.font = [self.lblNeedleValue.font fontWithSize:self.needleTextSize];
    self.lblNeedleValue.textColor = self.needleTextColor;
    [self.lblNeedleValue setAttributedText:levelStr];
    [self.needleView bringSubviewToFront:self.lblNeedleValue];
}

- (void) drawMinMaxLabels {
    NSDictionary *fontAttributes = [self getFontDictWithTextSize:self.minMaxTextSize];
    NSAttributedString *attributedMinString = [[NSAttributedString alloc] initWithString:[formatter stringFromNumber:[NSNumber numberWithFloat:(float)self.minlevel]] attributes:fontAttributes];
    NSAttributedString *attributedMaxString = [[NSAttributedString alloc] initWithString:[formatter stringFromNumber:[NSNumber numberWithFloat:(float)self.maxlevel]] attributes:fontAttributes];
    
    CGFloat minLabelWidth = attributedMinString.size.width;
    CGFloat minLabelHeigth = attributedMinString.size.height;
    CGFloat maxLabelWidth = attributedMaxString.size.width;
    CGFloat maxLabelHeigth = attributedMaxString.size.height;
    
    // init lblMinimum and lblMaximum
    if (!self.hideMinMaxLabels && !self.lblMinimum && !self.lblMaximum) {
        CGFloat biggestValue = [self getBiggestValueWithNumberArray:[NSArray arrayWithObjects:
                                                                     [NSNumber numberWithFloat:(float)minLabelWidth],
                                                                     [NSNumber numberWithFloat:(float)minLabelHeigth],
                                                                     [NSNumber numberWithFloat:(float)maxLabelWidth],
                                                                     [NSNumber numberWithFloat:(float)maxLabelHeigth],
                                                                     nil]];

        minLabelHeigth = minLabelWidth = maxLabelHeigth = maxLabelWidth = biggestValue + 8;
        
        CGFloat minX = (self.arcRadius) * cos(RADIANS_TO_DEGREES(zeroNeedleValue) - DEGREES_TO_RADIANS(-5)) + self.center.x - (minLabelWidth/2);
        CGFloat maxX = (self.arcRadius) * cos(RADIANS_TO_DEGREES(-highestNeedleValue) - DEGREES_TO_RADIANS(-5)) + self.center.x - (maxLabelWidth/2);
        CGFloat minMaxY = (self.arcRadius) * sin(RADIANS_TO_DEGREES(-highestNeedleValue) - DEGREES_TO_RADIANS(-5)) + self.center.y - (maxLabelHeigth/2);
        
        self.lblMinimum = [[UILabel alloc] initWithFrame:CGRectMake(minX,
                                                                    minMaxY,
                                                                    minLabelWidth,
                                                                    minLabelHeigth)];
        self.lblMaximum = [[UILabel alloc] initWithFrame:CGRectMake(maxX,
                                                                    minMaxY,
                                                                    maxLabelWidth,
                                                                    maxLabelHeigth)];
        
        // make label a circle
        if (self.showMinMaxLabelsAsCircle) {
            self.lblMinimum.clipsToBounds = self.lblMaximum.clipsToBounds = YES;
            self.lblMinimum.layer.cornerRadius = self.lblMaximum.layer.cornerRadius = minLabelWidth / 2;
        }
        
        self.lblMinimum.alpha = self.lblMaximum.alpha = self.minMaxLabelAlpha;
        self.lblMinimum.textAlignment = NSTextAlignmentCenter;
        self.lblMaximum.textAlignment = NSTextAlignmentCenter;
        self.lblMinimum.textColor = self.minimumTextColor;
        self.lblMaximum.textColor = self.maximumTextColor;
        self.lblMinimum.backgroundColor = self.minBackgroundColor;
        self.lblMaximum.backgroundColor = self.maxBackgroundColor;
        self.lblMinimum.layer.borderWidth = self.lblMaximum.layer.borderWidth = 0;
        self.lblMinimum.font = self.lblMaximum.font = [self.lblNeedleValue.font fontWithSize:self.minMaxTextSize];
        
        self.lblMinimum.attributedText = [[NSAttributedString alloc] initWithString:
                                          [formatter stringFromNumber:
                                           [NSNumber numberWithFloat:(float)self.minlevel]]];
        self.lblMaximum.attributedText = [[NSAttributedString alloc] initWithString:
                                          [formatter stringFromNumber:
                                           [NSNumber numberWithFloat:(float)self.maxlevel]]];
        [self addSubview:self.lblMinimum];
        [self addSubview:self.lblMaximum];
    }
}

- (void)drawUnitLabel {
    NSAttributedString *attributedUnit = [[NSAttributedString alloc] initWithString:self.unit attributes:[self getFontDictWithTextSize:self.unitTextSize]];
    
    if (!self.hideUnitLabel && !self.lblUnit) {
        CGFloat unitLabelWidth = attributedUnit.size.width;
        CGFloat unitLabelHeight = attributedUnit.size.height;
        
        // if unitLabel as Circle make it a square
        if (self.showUnitLabelAsCircle) {
            CGFloat biggestValue = [self getBiggestValueWithNumberArray:[NSArray arrayWithObjects:
                                                                         [NSNumber numberWithFloat:(float)unitLabelWidth],
                                                                         [NSNumber numberWithFloat:(float)unitLabelHeight],
                                                                         nil]];
            unitLabelHeight = unitLabelWidth = biggestValue + 10;
            /*if (unitLabelHeight > unitLabelWidth) {
                unitLabelWidth = unitLabelHeight = unitLabelHeight + 2;
            }
            else {
                unitLabelHeight = unitLabelWidth = unitLabelWidth + 2;
            }*/
        }
        
        self.lblUnit = [[UILabel alloc] initWithFrame:CGRectMake(self.center.x - (unitLabelWidth / 2),
                                                                 self.center.y + self.needleRadius + 2,
                                                                 unitLabelWidth,
                                                                 unitLabelHeight)];
        
        // make label a circle
        if (self.showUnitLabelAsCircle) {
            self.lblUnit.alpha = 0.7;
            self.lblUnit.clipsToBounds = YES;
            self.lblUnit.layer.cornerRadius = unitLabelWidth / 2;
        }
        
        self.lblUnit.layer.borderWidth = 0;
        self.lblUnit.textAlignment = NSTextAlignmentCenter;
        self.lblUnit.textColor = self.unitTextColor;
        self.lblUnit.backgroundColor = self.unitBackgroundColor;
        self.lblUnit.font = [self.lblUnit.font fontWithSize:self.unitTextSize];
        self.lblUnit.attributedText = attributedUnit;
        [self addSubview:self.lblUnit];
    }
}

# pragma mark - current level

- (void)setCurrentNeedleLevel:(CGFloat)currentNeedleLevel
{
    if (currentNeedleLevel >= self.minlevel && currentNeedleLevel <= self.maxlevel) {
        
        self.oldLevel = self.currentRadian;
        
        CGFloat diff = self.maxlevel - self.minlevel;
        
        self.currentRadian = ((divisorNeedleValue / diff) * currentNeedleLevel) + zeroNeedleValue;
        
        _currentNeedleLevel = currentNeedleLevel;
        [self setNeedsDisplay];
    }
}

#pragma mark - helpers

- (CGFloat)getBiggestValueWithNumberArray:(NSArray *)values {
    CGFloat biggestValue = 0.0f;
    for (NSNumber *value in values) {
        if ([value floatValue] > biggestValue) {
            biggestValue = [value floatValue];
        }
    }
    return biggestValue;
}

- (NSDictionary *)getFontDictWithTextSize:(CGFloat)textsize {
    UIFont *font = [UIFont systemFontOfSize:textsize];
    NSDictionary * fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, nil];
    
    return fontAttributes;
}

#pragma mark - custom getter/setter

- (CGPoint)center
{
    return CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    //return CGPointMake([self centerX], [self centerY]);
}

- (CGFloat)centerY
{
    return self.bounds.size.height - (self.bounds.size.height * 0.2);
}

- (CGFloat)centerX
{
    return self.bounds.size.width/2;
}

- (CGFloat) arcRadius
{
    if (_arcRadius <= 0) {
        //_arcRadius = [self centerX] - ([self centerX] * 0.1);
        _arcRadius = self.center.x - (self.center.x * 0.2);
    }
    
    return _arcRadius;
}

- (UIColor *) needleColor
{
    if (!_needleColor) {
        _needleColor = [UIColor colorWithRed:76/255.0 green:177/255.0 blue:88/255.0 alpha:1];
    }
    
    return _needleColor;
}

- (CGFloat) needleRadius
{
    if (_needleRadius <= 0) {
        _needleRadius = self.bounds.size.height * 0.08;
    }
    
    return _needleRadius;
}

- (void)setNeedleWidth:(CGFloat)needleWidth {
    if (needleWidth > 0) {
        _needleRadius = _needleWidth = needleWidth;
    }
}

- (CGFloat) maxlevel
{
    if (_maxlevel <= 0) {
        _maxlevel = 10;
    }
    
    return _maxlevel;
}

- (CGFloat)needleTextSize {
    if (_needleTextSize <= 0) {
        _needleTextSize = _needleRadius - 5;
    }
    
    return _needleTextSize;
}

- (UIColor *)needleTextColor {
    if (!_needleTextColor) {
        _needleTextColor = [UIColor whiteColor];
    }
    
    return _needleTextColor;
}

- (CGFloat)minMaxTextSize {
    if (_minMaxTextSize <= 0) {
        _minMaxTextSize = _needleTextSize;
    }
    
    return _minMaxTextSize;
}

- (NSArray *)arcGradientColors {
    if (!_arcGradientColors && !_arcBackgroundColor) {
        _arcGradientColors = [NSArray arrayWithObjects:
                              (id)[UIColor greenColor].CGColor,
                              (id)[UIColor yellowColor].CGColor,
                              (id)[UIColor redColor].CGColor,
                              nil];
    }
    
    return _arcGradientColors;
}

- (NSString *)unit {
    if (!_unit) {
        _unit = [NSString stringWithFormat:@"[mA]"];
    }
    
    return _unit;
}

- (UIColor *)minBackgroundColor {
    if (!_minBackgroundColor) {
        _minBackgroundColor = [UIColor clearColor];
    }
    
    return _minBackgroundColor;
}

- (UIColor *)maxBackgroundColor {
    if (!_maxBackgroundColor) {
        _maxBackgroundColor = [UIColor clearColor];
    }
    
    return _maxBackgroundColor;
}

- (UIColor *)unitBackgroundColor {
    if (!_unitBackgroundColor) {
        _unitBackgroundColor = [UIColor clearColor];
    }
    
    return _unitBackgroundColor;
}

- (CGFloat)minMaxLabelAlpha {
    if (_minMaxLabelAlpha < 0 || _minMaxLabelAlpha > 1) {
        _minMaxLabelAlpha = 1;
    }
    
    return _minMaxLabelAlpha;
}

- (CGFloat)needleOpacity {
    if (_needleOpacity < 0 || _needleOpacity > 1) {
        _needleOpacity = 1.0f;
    }
    
    return _needleOpacity;
}

@end
