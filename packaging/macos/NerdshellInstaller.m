#import <Cocoa/Cocoa.h>

@interface NerdshellAppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) NSTextField *statusLabel;
@property(nonatomic, strong) NSButton *installButton;
@end

@implementation NerdshellAppDelegate

- (NSTextField *)labelWithFrame:(NSRect)frame
                           text:(NSString *)text
                           font:(NSFont *)font
                          color:(NSColor *)color {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = text;
    label.font = font;
    label.textColor = color;
    label.alignment = NSTextAlignmentCenter;
    label.editable = NO;
    label.selectable = NO;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.usesSingleLineMode = NO;
    return label;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSRect frame = NSMakeRect(0, 0, 660, 430);
    self.window = [[NSWindow alloc]
        initWithContentRect:frame
                  styleMask:(NSWindowStyleMaskTitled |
                             NSWindowStyleMaskClosable |
                             NSWindowStyleMaskMiniaturizable)
                    backing:NSBackingStoreBuffered
                      defer:NO];
    self.window.title = @"Nerdshell Installer";
    self.window.releasedWhenClosed = NO;
    [self.window center];

    NSVisualEffectView *background = [[NSVisualEffectView alloc] initWithFrame:frame];
    background.material = NSVisualEffectMaterialUnderWindowBackground;
    background.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    background.state = NSVisualEffectStateActive;
    self.window.contentView = background;

    NSImageView *iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(276, 296, 108, 108)];
    iconView.image = NSApp.applicationIconImage;
    iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [background addSubview:iconView];

    NSTextField *title = [self labelWithFrame:NSMakeRect(40, 246, 580, 38)
                                         text:@"Convierte tu terminal en Nerdshell"
                                         font:[NSFont systemFontOfSize:26 weight:NSFontWeightBold]
                                        color:NSColor.labelColor];
    [background addSubview:title];

    NSTextField *description = [self labelWithFrame:NSMakeRect(55, 174, 550, 58)
                                               text:@"Instala y configura Zsh, Starship, eza, Ghostty, fuentes Nerd Font y herramientas para desarrollo. Antes de cambiar nada, Nerdshell crea una copia de seguridad de tu configuración actual."
                                               font:[NSFont systemFontOfSize:14]
                                              color:NSColor.secondaryLabelColor];
    [background addSubview:description];

    self.installButton = [[NSButton alloc] initWithFrame:NSMakeRect(220, 118, 220, 42)];
    self.installButton.title = @"Instalar Nerdshell";
    self.installButton.bezelStyle = NSBezelStyleRounded;
    self.installButton.controlSize = NSControlSizeLarge;
    self.installButton.target = self;
    self.installButton.action = @selector(startInstallation:);
    self.installButton.keyEquivalent = @"\r";
    [background addSubview:self.installButton];

    NSTextField *note = [self labelWithFrame:NSMakeRect(45, 73, 570, 32)
                                        text:@"Se abrirá Terminal para mostrar el progreso y solicitar permisos cuando sean necesarios."
                                        font:[NSFont systemFontOfSize:12]
                                       color:NSColor.tertiaryLabelColor];
    [background addSubview:note];

    self.statusLabel = [self labelWithFrame:NSMakeRect(45, 35, 570, 22)
                                       text:@"Listo para instalar"
                                       font:[NSFont systemFontOfSize:12 weight:NSFontWeightMedium]
                                      color:NSColor.secondaryLabelColor];
    [background addSubview:self.statusLabel];

    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)startInstallation:(id)sender {
    NSURL *resources = NSBundle.mainBundle.resourceURL;
    NSURL *installer = [[[resources URLByAppendingPathComponent:@"nerdshell" isDirectory:YES]
        URLByAppendingPathComponent:@"macos" isDirectory:YES]
        URLByAppendingPathComponent:@"install.command"];

    if (![NSFileManager.defaultManager isExecutableFileAtPath:installer.path]) {
        [self showError:@"El instalador interno no está disponible o no tiene permisos de ejecución."];
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/open"];
    task.arguments = @[@"-a", @"Terminal", installer.path];

    NSError *error = nil;
    if (![task launchAndReturnError:&error]) {
        [self showError:[NSString stringWithFormat:@"No se pudo abrir Terminal: %@", error.localizedDescription]];
        return;
    }

    self.statusLabel.stringValue = @"Instalación abierta en Terminal";
    self.statusLabel.textColor = NSColor.systemGreenColor;
    self.installButton.title = @"Abrir de nuevo";
}

- (void)showError:(NSString *)message {
    self.statusLabel.stringValue = message;
    self.statusLabel.textColor = NSColor.systemRedColor;

    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    alert.messageText = @"Nerdshell no pudo iniciar la instalación";
    alert.informativeText = message;
    [alert runModal];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        NerdshellAppDelegate *delegate = [[NerdshellAppDelegate alloc] init];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        [application run];
    }
    return 0;
}
