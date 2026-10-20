#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSDictionary *gMap = nil;
static FILE *gLog = NULL;
static int gHits = 0;

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
            return;
        }
    }
    gMap = @{};
}

static void PZLogHit(NSString *en, NSString *zh) {
    if (!gLog) gLog = fopen("/var/mobile/psnzh.log", "a");
    if (gLog && gHits < 80) {
        gHits++;
        fprintf(gLog, "%s => %s\n", en.UTF8String ?: "?", zh.UTF8String ?: "?");
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
    NSString *v = gMap[s];
    if (v) {
        PZLogHit(s, v);
        return v;
    }
    if ([s rangeOfString:@"proxy" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSString *r = PZSubst(s);
        return [r isEqualToString:s] ? s : r;
    }
    return s;
}

%hook UILabel
- (void)setText:(NSString *)text {
    %orig(PZ(text));
}
%end

%hook UITextView
- (void)setText:(NSString *)text {
    %orig(PZ(text));
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
    PZLogHit(@"CTOR", @"loaded");
}
