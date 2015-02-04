//
//  LPJSONUtils.m
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPJSONUtils.h"
#import "LPCJSONSerializer.h"
#import "LPCJSONDeserializer.h"
#import "LPTouchUtils.h"
#import "LPDevice.h"
#import "LPOrientationOperation.h"
#import "LPInvoker.h"

@interface LPJSONUtils ()

+ (void) dictionary:(NSMutableDictionary *) dictionary
    setObjectforKey:(NSString *) key
         whenTarget:(id) target
         respondsTo:(SEL) selector;
@end

@implementation LPJSONUtils

+ (void) dictionary:(NSMutableDictionary *) dictionary
    setObjectforKey:(NSString *) key
         whenTarget:(id) target
         respondsTo:(SEL) selector {
  if ([target respondsToSelector:selector]) {
    id value = [LPInvoker invokeSelector:selector withTarget:target];
    [dictionary setObject:value forKey:key];
  }
}

+ (NSString *) serializeDictionary:(NSDictionary *) dictionary {
  LPCJSONSerializer *s = [LPCJSONSerializer serializer];
  NSError *error = nil;
  NSData *d = [s serializeDictionary:dictionary error:&error];
  if (error) {
    NSLog(@"Unable to serialize dictionary (%@), %@", error, dictionary);
  }
  NSString *res = [[NSString alloc] initWithBytes:[d bytes] length:[d length]
                                         encoding:NSUTF8StringEncoding];
  return [res autorelease];
}

+ (NSDictionary *) deserializeDictionary:(NSString *) string {
  LPCJSONDeserializer *ds = [LPCJSONDeserializer deserializer];
  NSError *error = nil;
  NSDictionary *res = [ds deserializeAsDictionary:[string dataUsingEncoding:NSUTF8StringEncoding]
                                            error:&error];
  if (error) {
    NSLog(@"Unable to deserialize  %@", string);
  }
  return res;
}

+ (NSString *) serializeArray:(NSArray *) array {
  LPCJSONSerializer *s = [LPCJSONSerializer serializer];
  NSError *error = nil;
  NSData *d = [s serializeArray:array error:&error];
  if (error) {
    NSLog(@"Unable to serialize arrayy (%@), %@", error, array);
  }
  NSString *res = [[NSString alloc] initWithBytes:[d bytes] length:[d length]
                                         encoding:NSUTF8StringEncoding];
  return [res autorelease];
}


+ (NSArray *) deserializeArray:(NSString *) string {
  LPCJSONDeserializer *ds = [LPCJSONDeserializer deserializer];
  NSError *error = nil;
  NSArray *res = [ds deserializeAsArray:[string dataUsingEncoding:NSUTF8StringEncoding]
                                  error:&error];
  if (error) {
    NSLog(@"Unable to deserialize  %@", string);
  }
  return res;
}


+ (NSString *) serializeObject:(id) obj {
  LPCJSONSerializer *s = [LPCJSONSerializer serializer];
  NSError *error = nil;
  NSData *d = [s serializeObject:obj error:&error];
  if (error) {
    NSLog(@"Unable to serialize object (%@), %@", error, [obj description]);
  }
  NSString *res = [[NSString alloc] initWithBytes:[d bytes] length:[d length]
                                         encoding:NSUTF8StringEncoding];
  return [res autorelease];
}


+ (id) jsonifyObject:(id) object {
  return [self jsonifyObject:object fullDump:NO];
}

+(id)jsonifyObject:(id)object fullDump:(BOOL)dump {
  if (!object) {return nil;}
  if ([object isKindOfClass:[UIColor class]]) {
    UIColor *color = (UIColor*)object;
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return @{@"red": @(red), @"green": @(green), @"blue": @(blue), @"alpha": @(alpha), @"type": NSStringFromClass([object class])};
  }
  else if ([object isKindOfClass:[UIView class]]) {
    NSMutableDictionary *viewJson = [self jsonifyView:(UIView*) object];
    if (dump) {
      [self dumpView: object toDictionary:viewJson];
      if (viewJson[@"class"]) {
        viewJson[@"type"] = viewJson[@"class"];
        [viewJson removeObjectForKey:@"class"];
      }
    }
    return viewJson;
  }
  else if ([object respondsToSelector:@selector(isAccessibilityElement)] && [object isAccessibilityElement]) {
    NSMutableDictionary *viewJson = [self jsonifyAccessibilityElement:object];
    if (dump) {
      [self dumpAccessibilityElement:object toDictionary:viewJson];
      if (viewJson[@"class"]) {
        viewJson[@"type"] = viewJson[@"class"];
        [viewJson removeObjectForKey:@"class"];
      }

    }
    return viewJson;
  } else if ([object respondsToSelector:@selector(accessibilityElementCount)] &&
             [object respondsToSelector:@selector(accessibilityElementAtIndex:)] &&
             [object accessibilityElementCount] != NSNotFound &&
             [object accessibilityElementCount] > 0 ) {
    NSMutableDictionary *viewJson = [self jsonifyAccessibilityElement: object];
    if (dump) {
      [self dumpAccessibilityElement: object toDictionary:viewJson];
      if (viewJson[@"class"]) {
        viewJson[@"type"] = viewJson[@"class"];
        [viewJson removeObjectForKey:@"class"];
      }

    }
    return viewJson;
  }

  LPCJSONSerializer *s = [LPCJSONSerializer serializer];
  NSError *error = nil;
  if (![s serializeObject:object error:&error] || error) {
    return [object description];
  }
  return object;
}

+ (NSMutableDictionary*) jsonifyView:(id) v {
  NSMutableDictionary *result = [@{} mutableCopy];
  result[@"class"] = NSStringFromClass([v class]);

  NSNumber *viewVisible = [LPTouchUtils isViewVisible:(UIView*)v] ? @(1) : @(0);
  [result setObject:viewVisible forKey:@"visible"];

  // Be defensive: user *might* have a view with a 'nil' description.
  [LPJSONUtils dictionary:result
          setObjectforKey:@"description"
               whenTarget:v
               respondsTo:@selector(description)];

  // Selector is defined for NSObject(UIKit), but better to be safe than sorry.
  [LPJSONUtils dictionary:result
          setObjectforKey:@"accessibilityElement"
          whenTarget:v
          respondsTo:@selector(isAccessibilityElement)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"label"
               whenTarget:v
               respondsTo:@selector(accessibilityLabel)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"id"
               whenTarget:v
               respondsTo:@selector(accessibilityIdentifier)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"text"
               whenTarget:v
               respondsTo:@selector(text)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"selected"
               whenTarget:v
               respondsTo:@selector(isSelected)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"enabled"
               whenTarget:v
               respondsTo:@selector(isEnabled)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"alpha"
               whenTarget:v
               respondsTo:@selector(alpha)];

  // Setting value.
  NSString *valueKey = @"value";
  if ([v respondsToSelector:@selector(value)]) { // value
    [LPJSONUtils dictionary:result
            setObjectforKey:valueKey
                 whenTarget:v
                 respondsTo:@selector(value)];
  } else if ([v respondsToSelector:@selector(text)]) { // text
    [LPJSONUtils dictionary:result
            setObjectforKey:valueKey
                 whenTarget:v
                 respondsTo:@selector(text)];
  } else if ([v respondsToSelector:@selector(accessibilityValue)]) { // accessibilityValue
    [LPJSONUtils dictionary:result
            setObjectforKey:@"value"
                 whenTarget:v
                 respondsTo:@selector(accessibilityValue)];
  }

  CGRect frame = [v frame];
  result[@"frame"] = @{@"x" : @(frame.origin.x),
                       @"y" : @(frame.origin.y),
                       @"width" : @(frame.size.width),
                       @"height" : @(frame.size.height)};

  UIWindow *window = [LPTouchUtils windowForView:v];
  if (window) {

    CGPoint center = [LPTouchUtils centerOfView:v];

    CGRect rect = [window convertRect:((UIView*)v).bounds fromView:v];

    UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([frontWindow respondsToSelector:@selector(convertRect:toCoordinateSpace:)]) {
      rect = [frontWindow convertRect:rect toCoordinateSpace:frontWindow];
    } else {
      rect = [frontWindow convertRect:rect fromWindow:window];
    }
#else
    rect = [frontWindow convertRect:rect fromWindow:window];
#endif

    result[@"rect"] = @{@"center_x" : @(center.x),
                        @"center_y" : @(center.y),
                        @"x" : @(rect.origin.x),
                        @"y" : @(rect.origin.y),
                        @"width" : @(rect.size.width),
                        @"height" : @(rect.size.height)};
  }
  return result;
}

+(NSMutableDictionary*)jsonifyAccessibilityElement:(id)object {
  NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    NSStringFromClass([object class]), @"class", nil];

  [result setObject:@(1) forKey:@"visible"];
  result[@"accessibilityElement"] = @(1);
  NSString *lbl = [object accessibilityLabel];
  if (lbl) {
    [result setObject:lbl forKey:@"label"];
  } else {
    [result setObject:[NSNull null] forKey:@"label"];
  }

  if ([object respondsToSelector:@selector(accessibilityIdentifier)]) {

    NSString *aid = [object accessibilityIdentifier];
    if (aid) {
      [result setObject:aid forKey:@"id"];
    } else {
      [result setObject:[NSNull null] forKey:@"id"];
    }
  }

  if ([object respondsToSelector:@selector(accessibilityHint)]) {

    NSString *accHint = [object accessibilityHint];
    if (accHint) {
      [result setObject:accHint forKey:@"hint"];
    } else {
      [result setObject:[NSNull null] forKey:@"hint"];
    }
  }
  if ([object respondsToSelector:@selector(accessibilityValue)]) {
    NSString *accVal = [object accessibilityValue];
    if (accVal) {
      [result setObject:accVal forKey:@"value"];
    } else {
      [result setObject:[NSNull null] forKey:@"value"];
    }
  }
  if ([object respondsToSelector:@selector(text)]) {

    NSString *text = [object text];
    if (text) {
      [result setObject:text forKey:@"text"];
    } else {
      [result setObject:[NSNull null] forKey:@"text"];
    }
  }
  if ([object respondsToSelector:@selector(isSelected)]) {
    BOOL selected = [object isSelected];
    [result setObject:@(selected) forKey:@"selected"];
  }
  if ([object respondsToSelector:@selector(isEnabled)]) {
    BOOL enabled = [object isEnabled];
    [result setObject:@(enabled) forKey:@"enabled"];
  }
  if ([object respondsToSelector:@selector(alpha)]) {
    CGFloat alpha = [object alpha];
    [result setObject:@(alpha) forKey:@"alpha"];
  }


  CGRect frame = [object accessibilityFrame];
  CGPoint center = [LPTouchUtils centerOfFrame:frame shouldTranslate:YES];
  NSDictionary *frameDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:frame.origin.x], @"x",
                            [NSNumber numberWithFloat:frame.origin.y], @"y",
                            [NSNumber numberWithFloat:frame.size.width], @"width",
                            [NSNumber numberWithFloat:frame.size.height], @"height",
                            [NSNumber numberWithFloat:center.x], @"center_x",
                            [NSNumber numberWithFloat:center.y], @"center_y",
                            nil];

  [result setObject:frameDic forKey:@"rect"];

  [result setObject:[object description] forKey:@"description"];

  return result;
}

+(void)dumpView:(UIView*) view toDictionary:(NSMutableDictionary*)viewJson {
  NSDictionary *rect = viewJson[@"rect"];

  viewJson[@"hit-point"] = @{@"x": rect[@"center_x"], @"y": rect[@"center_y"]};
}

+(void)dumpAccessibilityElement:(id)object toDictionary:(NSMutableDictionary*)viewJson {
  NSDictionary *rect = viewJson[@"rect"];

  viewJson[@"hit-point"] = @{@"x": rect[@"center_x"], @"y": rect[@"center_y"]};

  viewJson[@"accessibilityTraits"] = [self accessibilityTraits:object];
}

+(NSArray*)accessibilityTraits:(id)view {
  if (![view respondsToSelector:@selector(accessibilityTraits)]) {
    return @[];
  }
  NSMutableArray *traitStrings = [[NSMutableArray alloc]initWithCapacity:8];
  UIAccessibilityTraits traits = [view accessibilityTraits];
  if ((traits & UIAccessibilityTraitButton)) {
    [traitStrings addObject:@"button"];
  }
  if ((traits & UIAccessibilityTraitLink)) {
    [traitStrings addObject:@"link"];
  }
  if ((traits & UIAccessibilityTraitSearchField)) {
    [traitStrings addObject:@"searchField"];
  }
  if ((traits & UIAccessibilityTraitImage)) {
    [traitStrings addObject:@"image"];
  }
  if ((traits & UIAccessibilityTraitSelected)) {
    [traitStrings addObject:@"selected"];
  }
  if ((traits & UIAccessibilityTraitPlaysSound)) {
    [traitStrings addObject:@"playsSound"];
  }
  if ((traits & UIAccessibilityTraitKeyboardKey)) {
    [traitStrings addObject:@"keyboardKey"];
  }
  if ((traits & UIAccessibilityTraitStaticText)) {
    [traitStrings addObject:@"staticText"];
  }
  if ((traits & UIAccessibilityTraitSummaryElement)) {
    [traitStrings addObject:@"summaryElement"];
  }
  if ((traits & UIAccessibilityTraitNotEnabled)) {
    [traitStrings addObject:@"notEnabled"];
  }
  if ((traits & UIAccessibilityTraitUpdatesFrequently)) {
    [traitStrings addObject:@"updatesFrequently"];
  }
  if ((traits & UIAccessibilityTraitStartsMediaSession)) {
    [traitStrings addObject:@"mediaSession"];
  }
  if ((traits & UIAccessibilityTraitAdjustable)) {
    [traitStrings addObject:@"adjustable"];
  }
  if ((traits & UIAccessibilityTraitAllowsDirectInteraction)) {
    [traitStrings addObject:@"allowsDirectInteraction"];
  }
  if ((traits & UIAccessibilityTraitCausesPageTurn)) {
    [traitStrings addObject:@"causesPageTurn"];
  }
  if ((traits & UIAccessibilityTraitHeader)) {
    [traitStrings addObject:@"header"];
  }
  return [traitStrings autorelease];
}

@end
