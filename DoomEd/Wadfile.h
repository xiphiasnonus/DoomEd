#import <appkit/appkit.h>
#import "NXConvert.h"

#import "Storage.h"

@interface Wadfile : Object
{
	int		handle;
	char		*pathname;
	Storage		*info;
	BOOL	dirty;
}

- initFromFile: (char const *)path;
- initNew: (char const *)path;
- close;
- free;

- (int)numLumps;
- (int)lumpsize: (int)lump;
- (int)lumpstart: (int)lump;
- (char const *)lumpname: (int)lump;
- (int)lumpNamed: (char const *)name;
- (void *)loadLump: (int)lump;
- (void *)loadLumpNamed: (char const *)name;

- addName: (char const *)name data: (void *)data size: (int)size;
- writeDirectory; 

@end
