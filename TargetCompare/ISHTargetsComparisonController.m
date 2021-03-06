//
//  ISHTargetsComparisonController.m
//  TargetCompare
//
//  Created by Felix Lamouroux on 09.08.12.
//  Copyright (c) 2012 iosphere GmbH. All rights reserved.
//

#import "ISHTargetsComparisonController.h"
#import <XcodeEditor/XCProject.h>
#import <XcodeEditor/XCSourceFile.h>

@interface ISHTargetsComparisonController ()
@property (strong) NSArray *membersMissingInTargetLeft;
@property (strong) NSArray *membersMissingInTargetRight;
@end


@implementation ISHTargetsComparisonController

- (void)showResults {
    
    BOOL showTables = (self.membersMissingInTargetRight.count + self.membersMissingInTargetLeft.count > 0);
    [self.imageView setHidden:showTables];
    [self.tableContainerView setHidden:!showTables];
    
    [[self window] makeKeyAndOrderFront:nil];
}

- (void)checkSanityForProject:(XCProject *)aProject {
    NSArray *filesWithAbsolutePath = [aProject.files filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary * bindings) {
                return [[(XCSourceFile *) evaluatedObject pathRelativeToProjectRoot] isAbsolutePath];
            }]];

    NSArray *fileNames = nil;

    if ([XCSourceFile instancesRespondToSelector:@selector(name)]) {
        fileNames = [filesWithAbsolutePath valueForKey:@"name"];
    }

    NSAlert *myAlert = nil;

    if (filesWithAbsolutePath.count) {
        myAlert = [NSAlert alertWithMessageText:@"Absolute paths in project" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There are %lu files with absolute paths:\n%@", fileNames.count, [fileNames componentsJoinedByString:@"\n"]];
    } else {
        myAlert = [NSAlert alertWithMessageText:@"no absolute paths!" defaultButton:@"Cool" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Yeehaa, looks good!"];
    }

    [myAlert runModal];
}


- (void)compareLeftTarget:(XCTarget *)targetLeft withRightTarget:(XCTarget *)targetRight {
    [[self leftTargetTitle] setTitleWithMnemonic:targetLeft.name];
    [[self rightTargetTitle] setTitleWithMnemonic:targetRight.name];
    
    // create set of paths of target members
    NSArray *leftPathsArray = [targetLeft.members valueForKeyPath:@"pathRelativeToProjectRoot"];
    NSArray *rightPathsArray = [targetRight.members valueForKeyPath:@"pathRelativeToProjectRoot"];
    
    // add paths to targets' resources
    leftPathsArray = [leftPathsArray arrayByAddingObjectsFromArray:[targetLeft.resources valueForKeyPath:@"pathRelativeToProjectRoot"]];
    rightPathsArray = [rightPathsArray arrayByAddingObjectsFromArray:[targetRight.resources valueForKeyPath:@"pathRelativeToProjectRoot"]];
    
    // create set from arrays
    NSSet *leftPaths = [NSSet setWithArray:leftPathsArray];
    NSSet *rightPaths = [NSSet setWithArray:rightPathsArray];
    
    // substract the to set from each other to identify missing elements
    NSMutableSet *membersMissingInLeft = [NSMutableSet setWithSet:rightPaths];
    [membersMissingInLeft minusSet:leftPaths];
    NSMutableSet *membersMissingInRight = [NSMutableSet setWithSet:leftPaths];
    [membersMissingInRight minusSet:rightPaths];
    
    [self setMembersMissingInTargetLeft:[membersMissingInLeft.allObjects sortedArrayUsingSelector:@selector(compare:)]];
    [self setMembersMissingInTargetRight:[membersMissingInRight.allObjects sortedArrayUsingSelector:@selector(compare:)]];
    
    [self.tableViewLeft reloadData];
    [self.tableViewRight reloadData];
    
    [self showResults];
}
#pragma mark - NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.tableViewLeft) {
        return self.membersMissingInTargetLeft.count;
    }
    
    return self.membersMissingInTargetRight.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSArray *data = self.membersMissingInTargetLeft;
    if (self.tableViewRight == aTableView) {
        data = self.membersMissingInTargetRight;
    }
    
    if ([[aTableColumn identifier] isEqualToString:@"file"]) {
        NSString *name = [data objectAtIndex:rowIndex];
        
        return name;
    }
    
    return @"Missing";
}

@end