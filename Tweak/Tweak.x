#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSDictionary *gMap = nil;
static NSDictionary *gLower = nil;
static FILE *gLog = NULL;
static int gLogLines = 0;

static void PZLoad(void) {
    if (gMap) return;
    NSArray *paths = @[
        @"/var/jb/usr/share/proxyswitcherng-zh/zh.json",
        @"/usr/share/proxyswitcherng-zh/zh.json"
    ];
    for (NSString *p in paths) {
        NSData *d = [NSData dataWithContentsOfFile:p];
        if (!d) continue;
        id obj = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            gMap = obj;
            NSMutableDictionary *lower = [NSMutableDictionary dictionary];
            for (NSString *k in gMap) {
                if ([k isKindOfClass:[NSString class]]) lower[[k lowercaseString]] = gMap[k];
            }
            gLower = lower;
            return;
        }
    }
    gMap = @{};
    gLower = @{};
}

static void PZLog(NSString *tag, NSString *s) {
    if (!gLog) gLog = fopen("/var/mobile/psnzh.log", "a");
    if (gLog && gLogLines < 120) {
        gLogLines++;
        fprintf(gLog, "[%s] %s\n", tag.UTF8String ?: "?", s.UTF8String ?: "?");
        fflush(gLog);
    }
}

static NSString *PZSubst(NSString *s) {
    NSArray *pairs = @[
        @[@" could not reach ", @" 无法连接 "],
        @[@" reached ", @" 已连接 "],
        @[@" proxy ", @" 代理 "],
        @[@"connection refused", @"连接被拒绝"],
        @[@"connection failed", @"连接失败"],
        @[@"connection not allowed", @"连接不被允许"],
        @[@"network unreachable", @"网络不可达"],
        @[@"host unreachable", @"主机不可达"],
        @[@"address type not supported", @"不支持的地址类型"],
        @[@"command not supported", @"不支持的命令"],
        @[@"general SOCKS server failure", @"SOCKS 服务器常规错误"],
        @[@"TTL expired", @"TTL 已过期"],
        @[@"unknown error", @"未知错误"],
        @[@"HTTP proxy authentication failed (407)", @"HTTP 代理认证失败（407）"],
        @[@"no response (timeout?)", @"无响应（超时？）"]
    ];
    for (NSArray *p in pairs) {
        s = [s stringByReplacingOccurrencesOfString:p[0] withString:p[1]];
    }
    return s;
}

static NSString *PZ(NSString *s) {
    if (![s isKindOfClass:[NSString class]] || s.length == 0) return s;
    PZLoad();

    // exact match, then case-insensitive match (group headers render uppercase)
    NSString *v = gMap[s];
    if (!v) v = gLower[[s lowercaseString]];

    // "ProxySwitcher-ng 0.1-dev (build 30)" -> "ProxySwitcher-ng 0.1-dev（构建 30）"
    if (!v && [s hasPrefix:@"ProxySwitcher-ng "] &&
        [s rangeOfString:@"(build "].location != NSNotFound) {
        NSMutableString *m = [s mutableCopy];
        [m replaceOccurrencesOfString:@"(build " withString:@"（构建 "
                              options:0 range:NSMakeRange(0, m.length)];
        if ([m hasSuffix:@")"]) [m replaceCharactersInRange:NSMakeRange(m.length - 1, 1) withString:@"）"];
        v = m;
    }

    if (v) {
        PZLog(@"hit", [NSString stringWithFormat:@"%@ => %@", s, v]);
        return v;
    }

    if ([s rangeOfString:@"proxy" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSString *r = PZSubst(s);
        if (![r isEqualToString:s]) {
            PZLog(@"hit", [NSString stringWithFormat:@"%@ => %@", s, r]);
            return r;
        }
    }

    if ([s rangeOfString:@"PROXY SERVER" options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [s rangeOfString:@"PROFILES" options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [s rangeOfString:@"DIAGNOSTICS" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        PZLog(@"raw", s);
    }
    BOOL hasLower = NO, hasUpper = NO;
    for (NSUInteger i = 0; i < s.length; i++) {
        unichar c = [s characterAtIndex:i];
        if (c >= 'a' && c <= 'z') hasLower = YES;
        if (c >= 'A' && c <= 'Z') hasUpper = YES;
    }
    if (hasUpper && !hasLower && s.length > 3) PZLog(@"rawUpper", s);
    return s;
}

%hook UILabel
- (void)setText:(NSString *)text {
    %orig(PZ(text));
}
- (void)setAttributedText:(NSAttributedString *)text {
    NSAttributedString *out = text;
    if (text.length > 0) {
        NSString *t = PZ(text.string);
        if (![t isEqualToString:text.string]) {
            NSMutableAttributedString *m = [text mutableCopy];
            [m replaceCharactersInRange:NSMakeRange(0, m.length) withString:t];
            out = m;
        }
    }
    %orig(out);
}
%end

%hook PSTableCell
- (void)setTitle:(NSString *)title {
    %orig(PZ(title));
}
%end

%hook UITextView
- (void)setText:(NSString *)text {
    %orig(PZ(text));
}
- (void)setAttributedText:(NSAttributedString *)text {
    NSAttributedString *out = text;
    if (text.length > 0) {
        NSString *t = PZ(text.string);
        if (![t isEqualToString:text.string]) {
            NSMutableAttributedString *m = [text mutableCopy];
            [m replaceCharactersInRange:NSMakeRange(0, m.length) withString:t];
            out = m;
        }
    }
    %orig(out);
}
%end

%hook UIButton
- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    %orig(PZ(title), state);
}
%end

%hook UINavigationItem
- (void)setTitle:(NSString *)title {
    %orig(PZ(title));
}
%end

%hook UIViewController
- (void)setTitle:(NSString *)title {
    %orig(PZ(title));
}
%end

%hook UIBarButtonItem
- (void)setTitle:(NSString *)title {
    %orig(PZ(title));
}
- (instancetype)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    return %orig(PZ(title), style, target, action);
}
%end

%hook UISearchBar
- (void)setPlaceholder:(NSString *)text {
    %orig(PZ(text));
}
%end

%hook UITextField
- (void)setPlaceholder:(NSString *)text {
    %orig(PZ(text));
}
%end

%hook UISegmentedControl
- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment {
    %orig(PZ(title), segment);
}
%end

%hook UIAlertAction
+ (instancetype)actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *))handler {
    return %orig(PZ(title), style, handler);
}
%end

%hook UIAction
+ (instancetype)actionWithTitle:(NSString *)title image:(UIImage *)image identifier:(id)identifier handler:(void (^)(__kindof UIAction *))handler {
    return %orig(PZ(title), image, identifier, handler);
}
%end

%ctor {
    PZLoad();
}
