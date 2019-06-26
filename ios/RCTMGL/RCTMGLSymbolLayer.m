//
//  RCTMGLSymbolLayer.m
//  RCTMGL
//
//  Created by Nick Italiano on 9/19/17.
//  Copyright © 2017 Mapbox Inc. All rights reserved.
//

#import "RCTMGLSymbolLayer.h"
#import "RCTMGLStyle.h"
#import "UIView+React.h"
#import <React/RCTLog.h>

@implementation RCTMGLSymbolLayer

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _reactSubviews = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)invalidate
{
    if (_snapshot == YES && self.style != nil) {
        [self.style removeImageForName:self.id];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)insertReactSubview:(id<RCTComponent>)subview atIndex:(NSInteger)atIndex {
    [_reactSubviews insertObject:(UIView *)subview atIndex:(NSUInteger) atIndex];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)removeReactSubview:(id<RCTComponent>)subview {
    [_reactSubviews removeObject:(UIView *)subview];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (NSArray<id<RCTComponent>> *)reactSubviews {
    return nil;
}
#pragma clang diagnostic pop

- (void)updateFilter:(NSPredicate *)predicate
{
    @try {
        ((MGLSymbolStyleLayer *) self.styleLayer).predicate = predicate;
    }
    @catch (NSException* exception) {
        RCTLogError(@"Invalid predicate: %@ on layer %@ - %@ reason: %@", predicate, self, exception.name, exception.reason);
    }
}

- (void)setSourceLayerID:(NSString *)sourceLayerID
{
    _sourceLayerID = sourceLayerID;
    
    if (self.styleLayer != nil) {
        ((MGLSymbolStyleLayer*) self.styleLayer).sourceLayerIdentifier = _sourceLayerID;
    }
}

- (void)setSnapshot:(BOOL)snapshot
{
    _snapshot = snapshot;
    
    if (self.style != nil) {
        UIImage *image;
        MGLSymbolStyleLayer *layer = (MGLSymbolStyleLayer *) self.styleLayer;
        
        if (_snapshot == YES) {
            image = [self _createViewSnapshot];
            [self.style setImage:image forName:self.id];
            layer.iconImageName = [NSExpression expressionWithFormat:self.id];
        } else {
            image = [self.style imageForName:self.id];
            
            if (image != nil) {
                [self.style removeImageForName:self.id];
                layer.iconImageName = nil;
            }
        }
    }
}

- (void)addedToMap
{
    NSPredicate *filter = [self buildFilters];
    if (filter != nil) {
        [self updateFilter:filter];
    }
    
    if (_snapshot == YES) {
        UIImage *image = [self _createViewSnapshot];
        
        if (image != nil) {
            [self.style setImage:image forName:self.id];
            
            MGLSymbolStyleLayer *layer = (MGLSymbolStyleLayer *)self.styleLayer;
            layer.iconImageName = [NSExpression expressionForConstantValue:self.id];
        }
    }
}

- (MGLSymbolStyleLayer*)makeLayer:(MGLStyle*)style
{
    MGLSource *source = [style sourceWithIdentifier:self.sourceID];
    MGLSymbolStyleLayer *layer = [[MGLSymbolStyleLayer alloc] initWithIdentifier:self.id source:source];
    layer.sourceLayerIdentifier = _sourceLayerID;
    return layer;
}

- (void)addStyles
{
    RCTMGLStyle *style = [[RCTMGLStyle alloc] initWithMGLStyle:self.style];
    style.bridge = self.bridge;
    [style symbolLayer:(MGLSymbolStyleLayer*)self.styleLayer withReactStyle:self.reactStyle];
}

- (UIImage *)_createViewSnapshot
{
    if (_reactSubviews.count == 0) {
        return nil;
    }
    UIView *view = (UIView *)_reactSubviews[0];
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.f);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshot;
}

@end
