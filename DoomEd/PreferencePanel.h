
#import <appkit/appkit.h>
#import "NXConvert.h"

extern	id	prefpanel_i;

#define	APPDEFAULTS	"ID_doomed"
//	#define NUMCOLORS	9
#define	PREFNAME		@"PrefPanel"

typedef enum
{
	BACK_C = 0,
	GRID_C,
	TILE_C,
	SELECTED_C,
	POINT_C,
	ONESIDED_C,
	TWOSIDED_C,
	AREA_C,
	THING_C,
	SPECIAL_C,
	NUMCOLORS
} ucolor_e;

typedef enum
{
	texturePalette,
	lineInspector,
	lineSpecials,
	errorLog,
	sectorEditor,
	thingPanel,
	sectorSpecials,
	textureEditor,
	NUMOPENUP
} openup_e;

@interface PreferencePanel:Object
{
    id	backcolor_i;
    id	gridcolor_i;
    id	tilecolor_i;
    id	selectedcolor_i;
    id	pointcolor_i;
    id	onesidedcolor_i;
    id	twosidedcolor_i;
    id	areacolor_i;
    id	thingcolor_i;
	id	specialcolor_i;
	
	id	launchThingType_i;		// text field
	id	projectDefaultPath_i;	// textfield
	id	openupDefaults_i;		// grid of check boxes
	
	id  window_i;
	
	NSMutableArray		*colorwell;	// array of nscolorwells
	NSMutableArray		*color;		// array of nscolor
	int		launchThingType;
	//char	projectPath[128];
	NSString *projectPath;
}

- menuTarget:sender;
- colorChanged:sender;
- launchThingTypeChanged:sender;
- projectPathChanged:sender;
- openupChanged:sender;

- appWillTerminate: sender;

//
//	DoomEd accessor methods
//
- (NXColor *)colorFor: (int)ucolor;
- (int)getLaunchThingType;
- (NSString *)getProjectPath;
- (BOOL)openUponLaunch:(openup_e)type;

@end
