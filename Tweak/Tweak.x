#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSDictionary *gMap = nil;

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

static UIViewController *PZTop(UIViewController *vc) {
    if (!vc) return nil;
    if (vc.presentedViewController) return PZTop(vc.presentedViewController);
    if ([vc isKindOfClass:[UINavigationController class]])
        return PZTop([(UINavigationController *)vc topViewController]);
    if ([vc isKindOfClass:[UITabBarController class]])
        return PZTop([(UITabBarController *)vc selectedViewController]);
    return vc;
}

static UIViewController *PZRoot(void) {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (w.isKeyWindow) return w.rootViewController;
        }
    }
    return nil;
}

static BOOL PZActive(void) {
    UIViewController *vc = PZTop(PZRoot());
    while (vc) {
        if ([NSStringFromClass([vc class]) hasPrefix:@"PSN"]) return YES;
        UIViewController *next = nil;
        if ([vc isKindOfClass:[UINavigationController class]])
            next = [(UINavigationController *)vc topViewController];
        else if (vc.presentedViewController)
            next = vc.presentedViewController;
        else if ([vc isKindOfClass:[UITabBarController class]])
            next = [(UITabBarController *)vc selectedViewController];
        if (!next || next == vc) break;
        vc = next;
    }
    return NO;
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
    if (v) return v;
    NSString *r = PZSubst(s);
    return [r isEqualToString:s] ? s : r;
}

static NSAttributedString *PZA(NSAttributedString *a) {
    if (!PZActive() || a.length == 0) return a;
    NSString *t = PZ(a.string);
    if ([t isEqualToString:a.string]) return a;
    NSMutableAttributedString *m = [a mutableCopy];
    [m replaceCharactersInRange:NSMakeRange(0, m.length) withString:t];
    return m;
}

%hook UILabel
- (void)setText:(NSString *)text {
    if (PZActive()) text = PZ(text);
    %orig(text);
}
- (void)setAttributedText:(NSAttributedString *)text {
    %orig(PZA(text));
}
%end

%hook UITextView
- (void)setText:(NSString *)text {
    if (PZActive()) text = PZ(text);
    %orig(text);
}
- (void)setAttributedText:(NSAttributedString *)text {
    %orig(PZA(text));
}
%end

%hook UIButton
- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    if (PZActive()) title = PZ(title);
    %orig(title, state);
}
%end

%hook UINavigationItem
- (void)setTitle:(NSString *)title {
    if (PZActive()) title = PZ(title);
    %orig(title);
}
%end

%hook UIViewController
- (void)setTitle:(NSString *)title {
    if (PZActive()) title = PZ(title);
    %orig(title);
}
%end

%hook UIBarButtonItem
- (void)setTitle:(NSString *)title {
    if (PZActive()) title = PZ(title);
    %orig(title);
}
- (instancetype)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    if (PZActive()) title = PZ(title);
    return %orig(title, style, target, action);
}
%end

%hook UISearchBar
- (void)setPlaceholder:(NSString *)text {
    if (PZActive()) text = PZ(text);
    %orig(text);
}
%end

%hook UITextField
- (void)setPlaceholder:(NSString *)text {
    if (PZActive()) text = PZ(text);
    %orig(text);
}
%end

%hook UISegmentedControl
- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment {
    if (PZActive()) title = PZ(title);
    %orig(title, segment);
}
%end

%hook UIAlertAction
+ (instancetype)actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *))handler {
    if (PZActive()) title = PZ(title);
    return %orig(title, style, handler);
}
%end

%hook UIAction
+ (instancetype)actionWithTitle:(NSString *)title image:(UIImage *)image identifier:(id)identifier handler:(void (^)(__kindof UIAction *))handler {
    if (PZActive()) title = PZ(title);
    return %orig(title, image, identifier, handler);
}
%end

%ctor {
    PZLoad();
}
