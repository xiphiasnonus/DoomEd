
#import <appkit/appkit.h>
#import "NXConvert.h"

@interface TextLog:Object
{
	id			text_i;
	NSWindow	*window_i;
}

- initTitle:(NSString *)title;
- msg:(char *)string;
- display:sender;
- clear:sender;

@end
