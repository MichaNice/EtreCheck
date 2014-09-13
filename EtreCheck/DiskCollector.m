/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "DiskCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "SystemInformation.h"
#import "Utilities.h"

// Some keys for an internal dictionary.
#define kVolumeType @"volumetype"
#define kVolumeStatus @"volumestatus"
#define kAttributes @"attributes"

// Collect information about disks.
@implementation DiskCollector

@dynamic volumes;

// Provide easy access to volumes.
- (NSMutableDictionary *) volumes
  {
  return [[SystemInformation sharedInformation] volumes];
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.progressEstimate = 0.4;
    self.name = @"diskinformation";
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking disk information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPSerialATADataType"
    ];
  
  NSData * result =
    [Utilities execute: @"/usr/sbin/system_profiler" arguments: args];
  
  if(result)
    {
    NSArray * plist = [Utilities readPropertyListData: result];
  
    if(plist && [plist count])
      {
      [self.result
        appendAttributedString: [self buildTitle: @"Disk Information:"]];
      
      NSDictionary * controllers =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * controller in controllers)
        [self printController: controller];
      }
    }
  else
    [self.result appendCR];
  }

// Print disks attached to a single controller.
- (void) printController: (NSDictionary *) controller
  {
  NSDictionary * disks = [controller objectForKey: @"_items"];
  
  for(NSDictionary * disk in disks)
    {
    NSString * diskName = [disk objectForKey: @"_name"];
    NSString * diskDevice = [disk objectForKey: @"bsd_name"];
    NSString * diskSize = [disk objectForKey: @"size"];
    NSString * UUID = [disk objectForKey: @"volume_uuid"];
    
    if(!diskDevice)
      diskDevice = @"";
      
    if(!diskSize)
      diskSize = @"";
    else
      diskSize = [NSString stringWithFormat: @": (%@)", diskSize];

    if(UUID)
      [self.volumes setObject: disk forKey: UUID];

    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"\t%@ %@ %@\n",
            diskName ? diskName : @"-", diskDevice, diskSize]];
    
    [self collectSMARTStatus: disk indent: @"\t"];
    
    NSArray * volumes = [disk objectForKey: @"volumes"];

    if(volumes && [volumes count])
      for(NSDictionary * volume in volumes)
        [self printVolume: volume indent: @"\t\t"];
    else
      [self.result appendCR];

    if([volumes count])
      [self.result appendCR];
    }
  }

// Get the SMART status for this disk.
- (void) collectSMARTStatus: (NSDictionary *) disk
  indent: (NSString *) indent
  {
  NSString * smart_status = [disk objectForKey: @"smart_status"];

  if(!smart_status)
    return;
    
  BOOL smart_not_supported =
    [smart_status isEqualToString: @"Not Supported"];
  
  BOOL smart_verified =
    [smart_status isEqualToString: @"Verified"];

  if(!smart_not_supported && !smart_verified)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"%@S.M.A.R.T. Status: %@\n", NULL),
            indent, smart_status]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"%@S.M.A.R.T. Status: Verified\n", NULL),
            indent]];
  }

// Print information about a volume.
// TODO: Shorten this.
- (void) printVolume: (NSDictionary *) volume indent: (NSString *) indent
  {
  NSString * volumeName = [volume objectForKey: @"_name"];
  NSString * volumeMountPoint = [volume objectForKey: @"mount_point"];
  NSString * volumeDevice = [volume objectForKey: @"bsd_name"];
  NSString * volumeSize = [volume objectForKey: @"size"];
  NSString * volumeFree = [volume objectForKey: @"free_space"];
  NSNumber * free = [volume objectForKey: @"free_space_in_bytes"];
  NSString * UUID = [volume objectForKey: @"volume_uuid"];

  if(!volumeMountPoint)
    volumeMountPoint = NSLocalizedString(@"<not mounted>", NULL);
    
  if(!volumeFree)
    volumeFree = @"";
  else
    volumeFree =
      [NSString
        stringWithFormat:
          NSLocalizedString(@"(%@ free)", NULL), volumeFree];

  if(UUID)
    [self.volumes setObject: volume forKey: UUID];

  NSDictionary * stats =
    [self
      volumeStatsFor: volumeName
      at: volumeMountPoint
      available: [free unsignedIntegerValue]];

  NSString * volumeInfo =
    [NSString
      stringWithFormat:
        NSLocalizedString(@"%@%@ (%@) %@ %@: %@ %@%@\n", NULL),
        indent,
        volumeName ? volumeName : @"-",
        volumeDevice,
        volumeMountPoint,
        [stats objectForKey: kVolumeType],
        volumeSize,
        volumeFree,
        [stats objectForKey: kVolumeStatus]];
    
  if([stats objectForKey: kAttributes])
    [self.result
      appendString: volumeInfo
      attributes: [stats objectForKey: kAttributes]];
  else
    [self.result appendString: volumeInfo];
  }

// Get more information about a volume.
// TODO: Shorten this.
- (NSDictionary *) volumeStatsFor: (NSString *) name
  at: (NSString *) mountPoint available: (NSUInteger) free
  {
  if([mountPoint isEqualToString: @"/"])
    {
    NSUInteger GB = 1024 * 1024 * 1024;

    if(free < (GB * 15))
      return
        @{
          kVolumeType : NSLocalizedString(@" [Startup]", NULL),
          kVolumeStatus : NSLocalizedString(@" (Low!)", NULL),
          kAttributes :
            @{
              NSForegroundColorAttributeName : [[Utilities shared] red],
              NSFontAttributeName : [[Utilities shared] boldFont]
            }
        };
      
    return
      @{
        kVolumeType : NSLocalizedString(@" [Startup]", NULL),
        kVolumeStatus : NSLocalizedString(@"", NULL),
        kAttributes :
          @{
            NSFontAttributeName : [[Utilities shared] boldFont]
          }
      };
    }
    
  else if([name isEqualToString: @"Recovery HD"])
    return
      @{
        kVolumeType : NSLocalizedString(@" [Recovery]", NULL),
        kVolumeStatus : NSLocalizedString(@"", NULL),
        kAttributes :
          @{
            NSForegroundColorAttributeName : [[Utilities shared] gray]
          }
      };
    
  return
    @{
      kVolumeType : NSLocalizedString(@"", NULL),
      kVolumeStatus : NSLocalizedString(@"", NULL),
      kAttributes : @{}
    };
  }

@end
