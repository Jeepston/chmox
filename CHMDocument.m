//
// Chmox a CHM file viewer for Mac OS X
// Copyright (c) 2004 Stéphane Boisson.
//
// Chmox is free software; you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
//
// Chmox is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Foobar; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// $Revision: 1.6 $
//

#import "CHMDocument.h"
#import "CHMWindowController.h"
#import "CHMContainer.h"
#import "CHMTableOfContents.h"
#import "CHMURLProtocol.h"

@interface CHMDocument () {
    
    CHMWindowController *_windowController;
    
    CHMContainer *_container;
    CHMTableOfContents *_tableOfContents;
    
    NSMutableArray *_bookmarks;
    NSMutableArray *_searchResults;
}

@property (weak, readonly) NSString *title;


@end

@implementation CHMDocument

#pragma mark NSObject

- (instancetype) init
{
    if( self = [super init] ) {
        _container = nil;
    }
    
    return self;
}


- (void) dealloc
{
    if( _container ) {
        [CHMURLProtocol unregisterContainer:_container];
    }
    
}

#pragma mark NSDocument

- (void)makeWindowControllers
{
    _windowController = [[CHMWindowController alloc] initWithWindowNibName:@"CHMDocument"];
    [self addWindowController:_windowController];
}


- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
    NSLog( @"CHMDocument:readFromFile:%@", fileName );
    
    _container = [[CHMContainer alloc] initWithContentsOfFile:fileName];
    if( !_container ) return NO;
    
    [CHMURLProtocol registerContainer:_container];
    _tableOfContents = [[CHMTableOfContents alloc] initWithContainer:_container];
    
    return YES;
}

- (NSData *)dataRepresentationOfType:(NSString *)type {
    // Viewer only
    return nil;
}


#pragma mark Accessors

- (NSString *)title
{
    return _container.title;
}

- (NSURL *)currentLocation
{
    return [CHMURLProtocol URLWithPath:_container.homePath inContainer:_container];
}

- (NSString *)uniqueId
{
    return _container.uniqueId;
}



@end
