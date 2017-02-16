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
// $Revision: 1.3 $
//

#import <Foundation/Foundation.h>

struct chmFile;

@interface CHMContainer : NSObject {
    struct chmFile *_handle;
    NSString *_uniqueId;
    
    NSString *_path;
    NSString *_title;
    NSString *_homePath;
    NSString *_tocPath;
    NSString *_indexPath;
}

+ (instancetype)containerWithContentsOfFile:(NSString *)path;

- (instancetype)initWithContentsOfFile:(NSString *)path;

- (BOOL)hasObjectWithPath: (NSString *)path;
- (NSData *)dataWithContentsOfObject: (NSString *)objectPath;
- (NSString *)stringWithContentsOfObject: (NSString *)objectPath;
@property (readonly, copy) NSData *dataWithTableOfContents;

- (BOOL)loadMetadata;
- (void)computeIdFrom:(NSData *)systemData;
- (void)readWindowsDataFrom:(NSData *)windowsData readStringsDataFrom:(NSData *)stringsData;
- (void)readSystemDataFrom:(NSData *)systemData;

- (NSString *)findHomeForPath: (NSString *)basePath;

@property (readonly, copy) NSString *title;
@property (readonly, copy) NSString *uniqueId;
@property (readonly, copy) NSString *tocPath;
@property (readonly, copy) NSString *homePath;
@property (readonly, copy) NSString *path;

@end
