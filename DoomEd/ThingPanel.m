#import "PreferencePanel.h"
#import "MapWindow.h"
#import "EditWorld.h"
#import "ThingPanel.h"
#import	"ThingPalette.h"
#import	"ThingWindow.h"
#import	"TextureEdit.h"		// for strupr()

#import "Storage.h"

id	thingpanel_i;

@implementation ThingPanel

/*
=====================
=
= init
=
=====================
*/

- init
{
	self = [super init];
	thingpanel_i = self;
	window_i = NULL;		// until nib is loaded
	masterList_i = [[Storage	alloc]
			initCount:		0
			elementSize:	sizeof(thinglist_t)
			description:	NULL];
			
	diffDisplay = DIFF_ALL;
	
	return self;
}

- emptyThingList
{
	[masterList_i	empty];
	return self;
}

/*
==============
=
= menuTarget:
=
==============
*/

- menuTarget:sender
{
	if (!window_i)
	{
//		[NXApp
//			loadNibSection:	"thing.nib"
//			owner:			self
//			withNames:		NO
//		];
		[NSBundle loadNibNamed:@"thing2" owner:self];
		[window_i	setFrameUsingName:THINGNAME];
		[window_i	setDelegate:self];
		[thingBrowser_i	reloadColumn:0];
		[diffDisplay_i selectCellAtRow:diffDisplay column:0];
		//[diffDisplay_i	selectCellAt:diffDisplay :0];
		[count_i	setStringValue:@" "];
		[window_i	setParent:self];
		
		// (TF) Set wrapping button title
//		const char *ctitle = "Suggest New\nType";
//		NSString *str1 = @"Suggest New";
//		NSString *str2 = @"Type";
//		NSString *title = [[NSString alloc] initWithFormat:@"%@\r%@", str1,str2];
//		NSString *title = [[NSString alloc] initWithCString:ctitle encoding:NSUTF8StringEncoding];
//		NSAttributedString *attrTitle = [[NSAttributedString alloc]
//										 initWithString:title
//										 attributes:@{
//													  NSFontAttributeName : @"Helvetica-Bold",
//													  NSFontSizeAttribute : @14
//													  }];
//		[suggestButton_i setAttributedTitle:attrTitle];
	}

	[window_i makeKeyAndOrderFront:self];

	return self;
}

//- windowDidMiniaturize:sender
- (void)windowDidMiniaturize:(NSNotification *)notification
{
	NSWindow *win = [notification object];
	NSImage *img = [NSImage imageNamed:@"DoomEd"];
//	[sender	setMiniwindowIcon:"DoomEd"];
//	[sender	setMiniwindowTitle:"Things"];
	[win setMiniwindowImage:img];
	[win setMiniwindowTitle:@"Things"];
	//return self;
}


- saveFrame
{
	if (window_i)
		[window_i	saveFrameUsingName:THINGNAME];
	return self;
}

- pgmTarget
{
	if (!window_i)
		[self	menuTarget:NULL];
	else
		[window_i	orderFront:NULL];
	return self;
}

- (thinglist_t *)getCurrentThingData
{
	thinglist_t		thing;
	id				cell;
	
	if (!fields_i)
	{
		NXBeep();
		return NULL;
	}
	
//	cell = [fields_i cellAtRow:1 column:0];
	cell = [[fields_i cellAtIndex:1] contentView];
	//thing.value = [fields_i		intValueAt:1];
	thing.value = [cell intValue];
	strcpy(thing.name,[[nameField_i stringValue] UTF8String]);
	strcpy(thing.iconname,[[iconField_i	stringValue] UTF8String]);

	return &thing;	// TODO check this
}

//===================================================================
//
//	Report the difficulty of Things to view
//
//===================================================================
- (int)getDifficultyDisplay
{
	return diffDisplay;
}

//===================================================================
//
//	Change the difficulty of Things to view
//
//===================================================================
- (IBAction)changeDifficultyDisplay:sender
{
	id				cell;
	
	//
	//	Handle redrawing Edit windows for diff. change
	//
	cell = [sender selectedCell];
	diffDisplay = [cell tag];
	[editworld_i	redrawWindows];
	[self	currentThingCount];
	
	//return self;
}

//===================================================================
//
//	Display # of Things that match currently selected type
//
//===================================================================
- currentThingCount
{
	int				max;
	int				j;
	thinglist_t		*t;
	worldthing_t	*thing;
	int				count;

	//
	//	Count up how many of currently selected Thing there is
	//
	if (diffDisplay == DIFF_ALL)
	{
		[count_i	setStringValue:@"-"];
		return self;
	}
		
	max = [masterList_i	count];
	t = [self	getCurrentThingData];
	count = 0;
	thing = &things[0];

	for (j = 0;j < numthings; j++,thing++)
		if (t->value == thing->type)
		{
			if ((thing->options&1)-1 == diffDisplay)
				count++;
			else
			if (((thing->options&2)-1) == diffDisplay )
				count++;
			else
			if (((thing->options&4)-2) == diffDisplay )
				count++;
		}

	[count_i	setIntValue:count];
	
	return self;
}

//===================================================================
//
//	Select the Thing that has icon "name"
//
//===================================================================
- selectThingWithIcon:(char *)name
{
	int				max;
	int				i;
	thinglist_t		*t;
	id				matrix;
	
	max = [masterList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [masterList_i	elementAt:i];
		if (!strcasecmp(t->iconname,name))
		{
			[self	fillDataFromThing:t];
			matrix = [thingBrowser_i	matrixInColumn:0];
			//[matrix	selectCellAt:i :0];
			[matrix selectCellAtRow:i column:0];
			//[matrix	scrollCellToVisible:i :0];
			[matrix scrollCellToVisibleAtRow:i column:0];
			return self;
		}
	}
	
	return self;
}

//===================================================================
//
//	Unlink icon from this Thing
//
//===================================================================
- (IBAction)unlinkIcon:sender
{
	[iconField_i	setStringValue:@"NOICON"];
	[updateButton_i	performClick:self];
	//return self;
}

//===================================================================
//
//	Assign icon selected in Thing Palette to current thing data
//
//===================================================================
- (IBAction)assignIcon:sender
{
	int		iconnum;
	icon_t	*icon;
	
	iconnum = [thingPalette_i	getCurrentIcon];
	if (iconnum < 0)
	{
		NXBeep();
		return;// self;
	}
	icon = [thingPalette_i	getIcon:iconnum];
	NSString *iconname = [[NSString alloc] initWithCString:icon->name encoding:NSUTF8StringEncoding];
	[iconField_i	setStringValue:iconname];
	[updateButton_i	performClick:self];
	
	//return self;
}

//===================================================================
//
//	Verify a correct icon name input
//
//===================================================================
- (IBAction)verifyIconName:sender
{
	char	name[10];
	int		which;
	
	strcpy(name,[[iconField_i	stringValue] UTF8String]);
	strupr(name);
	which = [thingPalette_i	findIcon:name];
	if (which < 0)
	{
		NXBeep();
		[iconField_i	setStringValue:@"NOICON"];
		return;// self;
	}
	NSString *name_ns = [[NSString alloc] initWithCString:name encoding:NSUTF8StringEncoding];
	[iconField_i	setStringValue:name_ns];
	
	//return self;
}

//===================================================================
//
//	Suggest a new type for a new Thing
//
//===================================================================
- (IBAction)suggestNewType:sender
{
	int	num,i,found,max;
	id cell;
	
	max = [masterList_i	count];
	for (num = 1;num < 10000;num++)
	{
		found = 0;
		for (i = 0;i < max;i++)
			if (((thinglist_t *)[masterList_i	elementAt:i])->value == num)
			{
				found = 1;
				break;
			}
		if (!found)
		{
			//cell = [fields_i cellAtRow:1 column:0];
			cell = [[fields_i cellAtIndex:1] contentView];
			//[fields_i	setIntValue:num	at:1];
			[cell setIntValue:num];
			return;// self;
		}
	}
	//return self;
}

//
// delegate method called by "thingBrowser_i"
//
//- (int)browser:sender  fillMatrix:matrix  inColumn:(int)column
- (void)browser:(NSBrowser *)sender createRowsForColumn:(NSInteger)column inMatrix:(NSMatrix *)matrix
{
	int	max, i;
	id	cell;
	thinglist_t		*t;
	
	if (column > 0)
		return; //0;
		
	[self	sortThings];
	max = [masterList_i	count];
	for (i = 0; i < max; i++)
	{
		t = [masterList_i	elementAt:i];
		NSString *name = [[NSString alloc] initWithCString:t->name encoding:NSUTF8StringEncoding];
		//[matrix	insertRowAt:i];
		[matrix insertRow:i];
		//cell = [matrix	cellAt:i	:0];
		cell = [matrix cellAtRow:i column:0];
		[cell	setStringValue:name];
		[cell setLeaf: YES];
		[cell setLoaded: YES];
		[cell setEnabled: YES];
	}
	//return max;
}

//
// sort the thing list
//
- sortThings
{
	id	cell, matrix;
	int	max,i,j,flag, which;
	thinglist_t		*t1, *t2, tt1, tt2;
	char		name[32] = "\0";
	
	cell = [thingBrowser_i	selectedCell];
	if (cell)
		strcpy(name,[[cell	stringValue] UTF8String]);
	max = [masterList_i	count];
	
	do
	{
		flag = 0;
		for (i = 0;i < max; i++)
		{
			t1 = [masterList_i	elementAt:i];
			for (j = i + 1;j < max;j++)
			{
				t2 = [masterList_i	elementAt:j];
				if (strcasecmp(t2->name,t1->name) < 0)
				{
					tt1 = *t1;
					tt2 = *t2;
					[masterList_i	replaceElementAt:j  with:&tt1];
					[masterList_i	replaceElementAt:i  with:&tt2];
					flag = 1;
					break;
				}
			}
		}
	} while(flag);
	
	which = [self	findThing:name];
	if (which >= 0)
	{
		matrix = [thingBrowser_i	matrixInColumn:0];
//		[matrix	selectCellAt:which  :0];
//		[matrix	scrollCellToVisible:which :0];
		[matrix selectCellAtRow:which column:0];
		[matrix scrollCellToVisibleAtRow:which column:0];
	}
	
	return self;
}

//
// update current thing with current data
//
- (IBAction)updateThingData:sender
{
	id	cell;
	int	which;
	thinglist_t		*t;
	
	cell = [thingBrowser_i		selectedCell];
	if (!cell)
	{
		NXBeep();
		return;// self;
	}
	which = [self	findThing:(char *)[[cell	stringValue] UTF8String]];
	t = [masterList_i	elementAt:which];
	[self	fillThingData:t];
	[thingBrowser_i	reloadColumn:0];
//	[[thingBrowser_i	matrixInColumn:0]
//					selectCellAt:which  :0];
	[[thingBrowser_i	matrixInColumn:0] selectCellAtRow:which column:0];
	[doomproject_i	setDirtyProject:TRUE];
	
	//return self;
}

//
// take data from input fields and update thing data
//
- fillThingData:(thinglist_t *)thing
{
	id angleCell, valueCell;
	
//	angleCell = [fields_i cellAtRow:0 column:0];
//	valueCell = [fields_i cellAtRow:1 column:0];
	angleCell = [[fields_i cellAtIndex:0] contentView];
	valueCell = [[fields_i cellAtIndex:1] contentView];

//	thing->angle = [fields_i		intValueAt:0];
//	thing->value = [fields_i		intValueAt:1];
	thing->angle = [angleCell		intValue];
	thing->value = [valueCell		intValue];
	[self	confirmCorrectNameEntry:NULL];
	strcpy(thing->name,[[nameField_i	stringValue] UTF8String]);
	thing->option = [ambush_i	intValue]<<3;
	thing->option |= ([network_i	intValue]&1)<<4;
	thing->option |= [[difficulty_i cellAtRow:0 column:0] intValue]&1;
	thing->option |= ([[difficulty_i cellAtRow:1 column:0] intValue]&1)<<1;
	thing->option |= ([[difficulty_i cellAtRow:2 column:0] intValue]&1)<<2;
//	thing->color = [thingColor_i	color];		// TODO revert
	thing->color[0] = [[thingColor_i color] redComponent];
	thing->color[1] = [[thingColor_i color] greenComponent];
	thing->color[2] = [[thingColor_i color] blueComponent];

	strcpy(thing->iconname,[[iconField_i	stringValue] UTF8String]);
	if (!thing->iconname[0])
		strcpy(thing->iconname,"NOICON");
	return self;
}

//
// corrects any wrongness in namefield
//
- (IBAction)confirmCorrectNameEntry:sender
{
	char		name[32];
	int	i;

	bzero(name,32);
	if (strlen([[nameField_i	stringValue] UTF8String]) > 31)
		strncpy(name,[[nameField_i	stringValue] UTF8String],31);
	else
		strcpy(name,[[nameField_i	stringValue] UTF8String]);
		
	for (i = 0; i < strlen(name);i++)
		if (name[i] == ' ')
			name[i] = '_';
	NSString *name_ns = [[NSString alloc] initWithCString:name encoding:NSUTF8StringEncoding];
	[nameField_i	setStringValue:name_ns];
	//return self;
}

//
// fill-in the information for a worldthing_t
//
- getThing:(worldthing_t	*)thing
{
	thing->angle = [[[fields_i cellAtIndex:0] contentView]	intValue];
	thing->type = [[[fields_i cellAtIndex:1] contentView]	intValue];
	thing->options = [ambush_i	intValue]<<3;
	thing->options |= ([network_i	intValue]&1)<<4;
	thing->options |= [[difficulty_i	cellAtRow:0 column:0] intValue]&1;
	thing->options |= ([[difficulty_i	cellAtRow:1 column:0] intValue]&1)<<1;
	thing->options |= ([[difficulty_i	cellAtRow:2 column:0] intValue]&1)<<2;
	
	return self;
}

//
// user selected a thing in the map; reflect the selection in the thingpanel
//
- setThing:(worldthing_t *)thing
{
	int	which;
	thinglist_t		*t;
	
	which = [self	searchForThingType:thing->type];
	if (which >= 0)
	{
		t = [masterList_i	elementAt:which];
		t->option = thing->options;
		t->angle = thing->angle;
		
		[self	fillAllDataFromThing:t];
		[self	scrollToItem:which];
		[thingPalette_i	setCurrentIcon:[thingPalette_i	findIcon:t->iconname]];
	}
	
	return self;
}

- getThingList
{
	return masterList_i;
}

- scrollToItem:(int)which
{
	id	matrix;
	
	matrix = [thingBrowser_i	matrixInColumn:0];
//	[matrix	selectCellAt:which :0];
//	[matrix	scrollCellToVisible:which :0];
	[matrix	selectCellAtRow:which column:0];
	[matrix	scrollCellToVisibleAtRow:which column:0];

	return self;
}

- (IBAction)setAngle:sender
{
	[[[fields_i cellAtIndex:0] contentView] setIntValue:[[sender selectedCell] tag]];
	//[fields_i setIntValue:[[sender	selectedCell]	tag] at:0];
	[self		formTarget:NULL];
	//return self;
}

- (NSColor *)getThingColor:(int)type
{
//	int	index;
//
//	index = [self  searchForThingType:type];
//	if (index < 0)
//		return [prefpanel_i colorFor: SELECTED_C];
//	return	((thinglist_t *)[masterList_i	elementAt:index])->color;
	
	int	index;
	float r,g,b;
	
	index = [self  searchForThingType:type];
	if (index < 0)
		return [prefpanel_i colorFor: SELECTED_C];
//	return	((thinglist_t *)[masterList_i	elementAt:index])->color;
	r = ((thinglist_t *)[masterList_i	elementAt:index])->color[0];
	g = ((thinglist_t *)[masterList_i	elementAt:index])->color[1];
	b = ((thinglist_t *)[masterList_i	elementAt:index])->color[2];
	
	return NXConvertRGBToColor(r, g, b);
}

//
// you know the thing's type, but don't know the name!
//
- (int)searchForThingType:(int)type
{
	int	max,i;
	thinglist_t		*t;
	
	max = [masterList_i	count];
	for (i = 0;i < max;i++)
	{
		t = [masterList_i	elementAt:i];
		if (t->value == type)
			return i;
	}
	return -1;
}

//
// fill data from thing
//
- fillDataFromThing:(thinglist_t *)thing
{
//	[fields_i	setIntValue:thing->value	at:1];
	[[[fields_i cellAtIndex:1] contentView] setIntValue:thing->value];

	NSString *thingname = [[NSString alloc] initWithCString:thing->name encoding:NSUTF8StringEncoding];
	[nameField_i	setStringValue:thingname];
	
//	[thingColor_i	setColor:thing->color];
	NSColor *color = [[NSColor alloc] init];
	color = [NSColor colorWithCalibratedRed:thing->color[0] green:thing->color[1] blue:thing->color[2] alpha:1];
	[thingColor_i	setColor:color];
	
	NSString *iconname = [[NSString alloc] initWithCString:thing->iconname encoding:NSUTF8StringEncoding];
	[iconField_i	setStringValue:iconname];
	
	basething.type = thing->value;
	
	return self;
}

//
// fill ALL data from thing
//
- fillAllDataFromThing:(thinglist_t *)thing
{
	[self	fillDataFromThing:thing];
	
	//[fields_i	setIntValue:thing->angle	at:0];
	[[[fields_i cellAtIndex:0] contentView] setIntValue:thing->angle];
	[ambush_i	setIntValue:((thing->option)>>3)&1];
	[network_i	setIntValue:((thing->option)>>4)&1];
	[[difficulty_i cellAtRow:0 column:0] setIntValue:(thing->option)&1];
	[[difficulty_i cellAtRow:1 column:0] setIntValue:((thing->option)>>1)&1];
	[[difficulty_i cellAtRow:2 column:0] setIntValue:((thing->option)>>2)&1];
	
	basething.angle = thing->angle;
	basething.options = thing->option;
	
	return self;
}

//
// Add "type" to thing list
//
- (IBAction)addThing:sender
{
	thinglist_t		t;
	int	which;
	id	matrix;

	[self	fillThingData:&t];
	
	//
	// check for duplicate name
	//
	if ([self	findThing:t.name] >= 0)
	{
		NXBeep();
		NXRunAlertPanel("Oops!",
			"You already have a THING by that name!","OK",NULL,NULL,NULL);
		return;// self;
	}
	
	[masterList_i	addElement:&t];
	[thingBrowser_i	reloadColumn:0];
	which = [self	findThing:t.name];
	matrix = [thingBrowser_i	matrixInColumn:0];
//	[matrix	selectCellAt:which :0];
//	[matrix	scrollCellToVisible:which :0];
	[matrix selectCellAtRow:which column:0];
	[matrix scrollCellToVisibleAtRow:which column:0];
	[doomproject_i	setDirtyProject:TRUE];
	
	//return self;
}

#if 0
//
// delete thing from list.
// Data in "name" and "type" must match element in list.
//
- delThing:sender
{
	int	which;
	
	if ((which = [self	findThing:(char *)[nameField_i  stringValue]]) != -1)
	{
		[masterList_i	removeElementAt:which];
		[thingBrowser_i	reloadColumn:0];
	}
	return self;
}
#endif

//
// return index of thing in masterList. "string" is used for search thru list.
//
- (int)findThing:(char *)string
{
	int	max, i;
	thinglist_t		*t;
	
	max = [masterList_i	count];
	for (i = 0;i < max; i++)
	{
		t = [masterList_i	elementAt:i];
		if (!strcasecmp(t->name,string))
			return i;
	}
	return -1;
}

- (thinglist_t *)getThingData:(int)index
{
	return [masterList_i	elementAt:index];		
}

//
// user chose an item in the thingBrowser_i.
// stick the info in the "name" and "type" fields.
//
- (IBAction)chooseThing:sender
{
	id		cell;
	int		which;
	thinglist_t		*t;
	
	cell = [sender	selectedCell];
	if (!cell)
		return;// self;
		
	which = [self	findThing:(char *)[[cell	stringValue] UTF8String]];
	if (which < 0)
	{
		NXBeep();
		printf("Whoa! Can't find that thing!\n");
		return;// self;
	}

	t = [masterList_i	elementAt:which];
	[self	fillDataFromThing:t];
	[self	formTarget:NULL];
	which = [thingPalette_i	findIcon:t->iconname];
	if (which >= 0)
		[thingPalette_i	setCurrentIcon:which];
	//return self;
}

- (BOOL) readThing:(thinglist_t *)thing	from:(FILE *)stream
{
	float	r,g,b;
	
	if (fscanf(stream,"%s = %d %d %d (%f %f %f) %s\n",
			thing->name,&thing->angle,&thing->value,&thing->option,
			&r,&g,&b,thing->iconname) != 8)
		return NO;
	//thing->color = NXConvertRGBToColor(r,g,b);		// TODO revert
	thing->color[0] = r;
	thing->color[1] = g;
	thing->color[1] = b;
	return YES;
}

- writeThing:(thinglist_t *)thing	from:(FILE *)stream
{
//	float	r,g,b;
//
//	NXConvertColorToRGB(thing->color,&r,&g,&b);
//	fprintf(stream,"%s = %d %d %d (%f %f %f) %s\n",thing->name,thing->angle,thing->value,
//			thing->option,r,g,b,thing->iconname);
//	return self;
	float	r,g,b;

//	NXConvertColorToRGB(thing->color,&r,&g,&b);
	r = thing->color[0];
	g = thing->color[1];
	b = thing->color[2];

	fprintf(stream,"%s = %d %d %d (%f %f %f) %s\n",thing->name,thing->angle,thing->value,
			thing->option,r,g,b,thing->iconname);
	return self;

}

//
// update the things.dsp file (when project is saved/loaded)
//
- updateThingsDSP:(FILE *)stream
{
	thinglist_t		t,*t2;
	int	count, i, found;
	
	//
	// read things out of the file, only adding new things to the current list
	//
	if (fscanf (stream, "numthings: %d\n", &count) == 1)
	{
		for (i = 0; i < count; i++)
		{
			[self	readThing:&t	from:stream];
			found = [self	findThing:t.name];
			if (found < 0)
			{
				[masterList_i	addElement:&t];
				[doomproject_i	setDirtyProject:TRUE];
			}
		}
		[thingBrowser_i	reloadColumn:0];

		//
		// now, write out the new file!
		//
		count = [masterList_i	count];
		fseek (stream, 0, SEEK_SET);
		fprintf (stream, "numthings: %d\n",count);
		for (i = 0; i < count; i++)
		{
			t2 = [masterList_i	elementAt:i];
			[self	writeThing:t2	from:stream];
		}
	}
	else
		fprintf(stream,"numthings: %d\n",0);
	
	return self;
}
	
/*
==============
=
= updateInspector
=
= call with force == YES to update into a window while it is off screen, otherwise
= no updating is done if not visible
=
==============
*/

- updateInspector: (BOOL)force
{
	if (!force && ![window_i isVisible])
		return self;

	[window_i disableFlushWindow];
	
//	[fields_i setIntValue: basething.angle at: 0];
//	[fields_i setIntValue: basething.type at: 1];
	[[[fields_i cellAtIndex:0] contentView] setIntValue:basething.angle];
	[[[fields_i cellAtIndex:1] contentView] setIntValue:basething.type];
	[ambush_i	setIntValue:((basething.options)>>3)&1];
	[network_i	setIntValue:((basething.options)>>4)&1];
	[[difficulty_i	cellAtRow:0 column:0] setIntValue:(basething.options)&1];
	[[difficulty_i	cellAtRow:1 column:0] setIntValue:((basething.options)>>1)&1];
	[[difficulty_i	cellAtRow:2 column:0] setIntValue:((basething.options)>>2)&1];
	
	//[window_i reenableFlushWindow];
	[window_i enableFlushWindow];
	[window_i flushWindow];
	
	return self;
}

/*
==============
=
= formTarget:
=
= The user has edited something in a form cell
=
==============
*/

- formTarget: sender
{
	int			i;
	worldthing_t	*thing;
	
//	basething.angle = [fields_i intValueAt: 0];
//	basething.type = [fields_i intValueAt: 1];
	basething.angle = [[[fields_i cellAtIndex:0] contentView] intValue];
	basething.type = [[[fields_i cellAtIndex:1] contentView] intValue];
	basething.options = [ambush_i	intValue]<<3;
	basething.options |= ([network_i	intValue]&1)<<4;
	basething.options |= [[difficulty_i cellAtRow:0 column:0] intValue]&1;
	basething.options |= ([[difficulty_i cellAtRow:1 column:0] intValue]&1)<<1;
	basething.options |= ([[difficulty_i cellAtRow:2 column:0] intValue]&1)<<2;
	
	thing = &things[0];
	for (i=0 ; i<numthings ; i++, thing++)
		if (thing->selected > 0)
		{
			thing->angle = basething.angle;
			thing->type = basething.type;
			thing->options = basething.options;
			[editworld_i changeThing: i to: thing];
			[doomproject_i	setDirtyMap:TRUE];
		}
		
	
	return self;
}


/*
==============
=
= updateThingInspector
=
==============
*/

- updateThingInspector
{
	int			i;
	worldthing_t	*thing;
	
	thing = &things[0];
	for (i=0 ; i<numthings ; i++, thing++)
		if (thing->selected > 0)
		{
			basething = *thing;
			break;
		}
		
	if (bcmp (&basething, &oldthing, sizeof(basething)) )
	{
		memcpy (&oldthing, &basething, sizeof(oldthing));
		[self updateInspector: NO];
	}
			
	return self;
}	


/*
===================
=
= windowDidUpdate:
=
===================
*/
- (void)windowDidUpdate:(NSNotification *)notification
//- windowDidUpdate:sender
{
	[self updateInspector: YES];
		
	//return self;
}


@end
