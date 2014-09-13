/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "VideoCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

@implementation VideoCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.progressEstimate = 1.5;
    self.name = @"video";
    }
    
  return self;
  }

// Collect video information.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking video information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPDisplaysDataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [Utilities readPropertyListData: result];
  
    if(plist && [plist count])
      {
      NSArray * infos = [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        [self printVideoInformation: infos];
      }
    }
  }

// Print video information.
- (void) printVideoInformation: (NSArray *) infos
  {
  [self.result
    appendAttributedString: [self buildTitle: @"Video Information:"]];
  
  for(NSDictionary * info in infos)
    {
    NSString * name = [info objectForKey: @"sppci_model"];
    NSString * vram = [info objectForKey: @"spdisplays_vram"];

    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"\t%@%@VRAM: %@\n",
            name ? name : @"",
            name ? @" - " : @"",
            vram]];
      
    NSArray * displays = [info objectForKey: @"spdisplays_ndrvs"];
  
    for(NSDictionary * display in displays)
      [self printDisplayInfo: display];
    }
    
  [self.result appendCR];
  }

// Print information about a display.
- (void) printDisplayInfo: (NSDictionary *) display
  {
  NSString * name = [display objectForKey: @"_name"];
  NSString * resolution = [display objectForKey: @"spdisplays_resolution"];

  if(name || resolution)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"\t\t%@ %@\n",
            name ? name : @"Unknown",
            resolution ? resolution : @""]];
  }

@end
