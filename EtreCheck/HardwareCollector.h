/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect hardware information.
@interface HardwareCollector : Collector
  {
  NSDictionary * myProperties;
  NSString * myMachineCode;
  NSImage * myMachineIcon;
  NSDictionary * myMachineImageLookup;
  }

// Machine properties.
@property (retain) NSDictionary * properties;

// The machine code.
@property (retain) NSString * machineCode;

// The machine icon.
@property (retain) NSImage * machineIcon;

// Find a machine icon.
- (NSImage *) findMachineIcon: (NSString *) code;

@end
