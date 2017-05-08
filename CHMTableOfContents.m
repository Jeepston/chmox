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

#import "CHMTableOfContents.h"
#import "CHMContainer.h"
#import "CHMTopic.h"
#import "CHMURLProtocol.h"

#include <libxml/HTMLparser.h>

@interface CHMTableOfContents () {
    NSMutableArray *_rootTopics;
}

@end

@implementation CHMTableOfContents

typedef struct {
    // Context
    CHMContainer *container;
    CHMTableOfContents *toc;
    NSMutableArray *topicStack;
    CHMTopic *placeholder; 
    CHMTopic *lastTopic;
    
    // Topic properties
    NSString *name;
    NSString *path;
} TOCBuilderContext;

static void createNewTopic( TOCBuilderContext *context );
static void documentDidStart( TOCBuilderContext *toc );
static void documentDidEnd( TOCBuilderContext *toc );
static void elementDidStart( TOCBuilderContext *toc, const xmlChar *name, const xmlChar **atts );
static void elementDidEnd( TOCBuilderContext *toc, const xmlChar *name );


static htmlSAXHandler saxHandler = {
    NULL, /* internalSubset */
    NULL, /* isStandalone */
    NULL, /* hasInternalSubset */
    NULL, /* hasExternalSubset */
    NULL, /* resolveEntity */
    NULL, /* getEntity */
    NULL, /* entityDecl */
    NULL, /* notationDecl */
    NULL, /* attributeDecl */
    NULL, /* elementDecl */
    NULL, /* unparsedEntityDecl */
    NULL, /* setDocumentLocator */
    (startDocumentSAXFunc) documentDidStart, /* startDocument */
    (endDocumentSAXFunc) documentDidEnd, /* endDocument */
    (startElementSAXFunc) elementDidStart, /* startElement */
    (endElementSAXFunc) elementDidEnd, /* endElement */
    NULL, /* reference */
    NULL, /* characters */
    NULL, /* ignorableWhitespace */
    NULL, /* processingInstruction */
    NULL, /* comment */
    NULL, /* xmlParserWarning */
    NULL, /* xmlParserError */
    NULL, /* xmlParserError */
    NULL, /* getParameterEntity */
};

#pragma mark Lifecycle

- (instancetype)initWithContainer:(CHMContainer *)container
{
    if( self = [super init] ) {
	_rootTopics = [[NSMutableArray alloc] init];

	TOCBuilderContext context = {
	    container, self, [[NSMutableArray alloc] init],
            [[CHMTopic alloc] init],
	    nil, nil, nil
	};
	
	NSData *tocData = [container dataWithTableOfContents];
	
	// XML_CHAR_ENCODING_NONE / XML_CHAR_ENCODING_UTF8 / XML_CHAR_ENCODING_8859_1
	htmlParserCtxtPtr parser = htmlCreatePushParserCtxt( &saxHandler, &context,
							     tocData.bytes, (int)tocData.length,
							     NULL, XML_CHAR_ENCODING_8859_1 );
	htmlParseChunk( parser, tocData.bytes, 0, 1 );
	[context.topicStack release];

	htmlDocPtr doc = parser->myDoc;
	htmlFreeParserCtxt( parser );
	if( doc ) {
	    xmlFreeDoc( doc );
	}

	DEBUG_OUTPUT( @"Root topics: %@", _rootTopics );

    }
    
    return self;
}


- (void) dealloc
{
    [_rootTopics release];
    [super dealloc];
}

#pragma mark Mutators

- (void)addRootTopic:(CHMTopic *)topic 
{
    [_rootTopics addObject:topic];
}

#pragma mark libxml SAX handler implementation

static void documentDidStart( TOCBuilderContext *context )
{
    DEBUG_OUTPUT( @"SAX:documentDidStart" );
}

static void documentDidEnd( TOCBuilderContext *context )
{
    DEBUG_OUTPUT( @"SAX:documentDidEnd" );
}

static void elementDidStart( TOCBuilderContext *context, const xmlChar *name, const xmlChar **atts )
{
//    DEBUG_OUTPUT( @"SAX:elementDidStart %s", name );

    if( !strcasecmp( "ul", (const char*)name ) ) {
//        DEBUG_OUTPUT( @"Stack BEFORE %@", context->topicStack );

	if( context->name ) {
	    createNewTopic( context );
	}
	
	if( context->lastTopic ) {
	    [context->topicStack addObject:context->lastTopic];
	    context->lastTopic = nil;
	}
        else {
	    [context->topicStack addObject:context->placeholder];
        }
        
//        DEBUG_OUTPUT( @"Stack AFTER %@", context->topicStack );
    }
    else if( !strcasecmp( "li", (const char*)name ) ) {
	// Opening depth level
	context->name = nil;
	context->path = nil;
    }
    else if( !strcasecmp( "param", (const char*)name ) && ( atts != NULL )) {
	// Topic properties
	const xmlChar *type = NULL;
	const xmlChar *value = NULL;
	
	for( int i = 0; atts[ i ] != NULL ; i += 2 ) {
	    if( !strcasecmp( "name", (const char*)atts[ i ] ) ) {
		type = atts[ i + 1 ];
	    }
	    else if( !strcasecmp( "value", (const char*)atts[ i ] ) ) {
		value = atts[ i + 1 ];
	    }
	}
	
	if( ( type != NULL ) && ( value != NULL ) ) {
	    if( !strcasecmp( "Name", (const char*)type ) ) {
		// Name of the topic
		context->name = [[NSString alloc] initWithUTF8String:(const char*)value];
	    }
	    else if( !strcasecmp( "Local", (const char*)type ) ) {
		// Path of the topic
		context->path = [[NSString alloc] initWithUTF8String:(const char*)value];
	    }
	    else {
		// Unsupported topic property
		//NSLog( @"type=%s  value=%s", type, value );
	    }
	}
    }
}

static void elementDidEnd( TOCBuilderContext *context, const xmlChar *name )
{
//    DEBUG_OUTPUT( @"SAX:elementDidEnd %s", name );
    
    if( !strcasecmp( "li", (const char*)name ) && context->name ) {
	// New complete topic
	createNewTopic( context );
    }
    else if( !strcasecmp( "ul", (const char*)name ) ) {
//        DEBUG_OUTPUT( @"Stack BEFORE %@", context->topicStack );

	// Closing depth level
	if( context->topicStack.count > 0 ) {
            context->lastTopic = context->topicStack[context->topicStack.count - 1];
	    [context->topicStack removeLastObject];

            if( context->lastTopic == context->placeholder ) {
                context->lastTopic = nil;
            }
	}
        else {
            context->lastTopic = nil;
        }
        
//        DEBUG_OUTPUT( @"Stack AFTER %@", context->topicStack );
    }
}

static void createNewTopic( TOCBuilderContext *context )
{
    NSURL *location = nil;
    
    if( context->path ) {
	location = [CHMURLProtocol URLWithPath:context->path inContainer:context->container];
    }

    context->lastTopic = [[CHMTopic alloc] initWithName:context->name location:location];
    [context->name release];
    [context->path release];
    context->name = nil;
    context->path = nil;
    
    NSInteger level = context->topicStack.count;
    
    // Add topic to its parent
    while( --level >= 0 ) {
        CHMTopic *parent = context->topicStack[level];

        if( parent != context->placeholder ) {
            DEBUG_OUTPUT( @"createNewTopic: %@, %ld", context->lastTopic, (long)level );
            [parent addObject:context->lastTopic];
            return;
        }
    }
    
    [context->toc addRootTopic:context->lastTopic];
    DEBUG_OUTPUT( @"createNewTopic: %@ -root-", context->lastTopic );
}


#pragma mark NSOutlineViewDataSource implementation

- (NSInteger)outlineView:(NSOutlineView *)outlineView
    numberOfChildrenOfItem:(id)item
{
    return item? [item countOfSubTopics] : _rootTopics.count;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item
{
    return [item countOfSubTopics] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
	    child:(NSInteger)theIndex
	   ofItem:(id)item
{
    return item? [item objectInSubTopicsAtIndex:theIndex] : _rootTopics[theIndex];
}

- (id)outlineView:(NSOutlineView *)outlineView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
	   byItem:(id)item
{
    return [item name];
}

@end
