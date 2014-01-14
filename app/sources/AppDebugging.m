//
//  AppDebugging.m
//  HexFiend_2
//
//  Copyright 2011 ridiculous_fish. All rights reserved.
//

#import "AppDebugging.h"
#import "AppUtilities.h"

@implementation GenericPrompt

- (IBAction)genericPromptOKClicked:sender {
    USE(sender);
    [NSApp stopModalWithCode:NSRunStoppedResponse];
}

- (IBAction)genericPromptCancelClicked:sender {
    USE(sender);
    [NSApp stopModalWithCode:NSRunAbortedResponse];
}

- (id)initWithPromptText:(NSString *)text {
    self = [super initWithWindowNibName:@"GenericPrompt"];
    promptText = [text copy];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [promptField setStringValue:promptText];
}

- (void)dealloc {
    [promptText release];
    [super dealloc];
}

+ (NSString *)promptForValueWithText:(NSString *)text {
    NSString *textResult = nil;
    GenericPrompt *pmpt = [[self alloc] initWithPromptText:text];
    NSInteger modalResult = [NSApp runModalForWindow:[pmpt window]];
    if (modalResult == NSRunStoppedResponse) {
        textResult = [[[pmpt->valueField stringValue] copy] autorelease];
    }
    [pmpt close];
    [pmpt release];
    return textResult;
    
}

@end

static unsigned long long unsignedLongLongValue(NSString *s) {
    unsigned long long result = 0;
    parseNumericStringWithSuffix(s, &result, NULL);
    return result;
}

@interface HFRandomDataByteSlice : HFByteSlice
- (HFRandomDataByteSlice *)initWithRandomDataLength:(unsigned long long)length;
@end


@implementation BaseDataDocument (AppDebugging)

- (void)installDebuggingMenuItems:(NSMenu *)menu {
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:NSLocalizedString(@"Show ByteArray", @"显示字节数组") action:@selector(_showByteArray:) keyEquivalent:@"k"];
    [[[menu itemArray] lastObject] setKeyEquivalentModifierMask:NSCommandKeyMask];
    [menu addItemWithTitle:NSLocalizedString(@"Randomly Tweak ByteArray", @"随机修改字节数组") action:@selector(_tweakByteArray:) keyEquivalent:@""];
    [menu addItemWithTitle:NSLocalizedString(@"Random ByteArray", @"随机字节数组") action:@selector(_randomByteArray:) keyEquivalent:@""];
    
}

static NSString *promptForValue(NSString *promptText) {
    return [GenericPrompt promptForValueWithText:promptText];
}

- (void)_showByteArray:sender {
    USE(sender);
    NSLog(@"%@", [controller byteArray]);
}

- (void)_randomByteArray:sender {
    USE(sender);
    unsigned long long length = unsignedLongLongValue(promptForValue(NSLocalizedString(@"How long?", @"多长？")));
    Class clsHFRandomDataByteSlice = NSClassFromString(@"HFRandomDataByteSlice");
    HFByteSlice *slice = [[clsHFRandomDataByteSlice alloc] initWithRandomDataLength:length];
    HFByteArray *array = [[HFBTreeByteArray alloc] init];
    [array insertByteSlice:slice inRange:HFRangeMake(0, 0)];
    [slice release];
    [controller insertByteArray:array replacingPreviousBytes:0 allowUndoCoalescing:NO];
    [array release];
}

- (void)_tweakByteArray:sender {
    USE(sender);
    
    unsigned tweakCount = [promptForValue(NSLocalizedString(@"How many tweaks?", @"修改多少？")) intValue];
    
    HFByteArray *byteArray = [[controller byteArray] mutableCopy];
    unsigned i;
    Class clsHFRandomDataByteSlice = NSClassFromString(@"HFRandomDataByteSlice");
    for (i=1; i <= tweakCount; i++) {
	NSAutoreleasePool* pool=[[NSAutoreleasePool alloc] init];
	NSUInteger op;
	const unsigned long long length = [byteArray length];
	unsigned long long offset;
	unsigned long long number;
	switch ((op = (random()%2))) {
	    case 0: { //insert
		offset = random() % (1 + length);
		HFByteSlice* slice = [[clsHFRandomDataByteSlice alloc] initWithRandomDataLength: 1 + random() % 1000];
		[byteArray insertByteSlice:slice inRange:HFRangeMake(offset, 0)];
		[slice release];
		break;
	    }
	    case 1: { //delete
		if (length > 0) {
                    number = (NSUInteger)sqrt(random() % length);
                    offset = 1 + random() % (length - number);
		    [byteArray deleteBytesInRange:HFRangeMake(offset, number)];
		}
		break;
	    }
	}
	[pool drain];
    }
    [controller replaceByteArray:byteArray];
    [byteArray release];
}

@end
