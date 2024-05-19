//
//  WKWebView+File.m
//  Code
//
//  Created by Huima on 2024/5/18.
//

#import <objc/runtime.h>
#import <WebKit/WebKit.h>
//
//@interface WKWebView (SchemeHandle)
//
//@end
//
//
//
//
//@implementation WKWebView (SchemeHandle)
//
//+ (void)load {
//  static dispatch_once_t onceToken;
//  dispatch_once(&onceToken, ^{
//    Method originalMethod1 = class_getClassMethod(self, @selector(handlesURLScheme:));
//    Method swizzledMethod1 = class_getClassMethod(self, @selector(yyhandlesURLScheme:));
//    method_exchangeImplementations(originalMethod1, swizzledMethod1);
//  });
//}
//
//+ (BOOL)yyhandlesURLScheme:(NSString *)urlScheme {
//  if ([urlScheme isEqualToString:@"http"] || [urlScheme isEqualToString:@"https"] || [urlScheme isEqualToString:@"file"]) {
//    return NO; //这里让返回NO,应该是默认不走系统断言或者其他判断啥的
//  } else {
//    return [self yyhandlesURLScheme:urlScheme];
//  }
//}
//@end
