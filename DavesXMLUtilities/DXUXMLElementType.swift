//
//  DXUXMLElementType.swift
//  DXUNetworking
//
//  Created by David Christensen on 23/06/15.
//  Copyright (c) 2015 David Christensen. All rights reserved.
//

import Foundation

/**
XML element type enumeration.
Elements can have one of three types:

* Regular, which have child tags
* Content only, which describes the text content of tags.
* CDATA only, which describes CDATA-protected data content of tags.

The structure, &lt;b&gt;Hello, World!&lt;/b&gt; will describe

    REGULAR TAG: b --> CONTENT ONLY TAG: "Hello, World!".

Since Content-only and CDATA-only elements have no tag name (since they're not "real" tags), they are represented as \string and \cdata respectively, for internal house keeping.

*/
public enum DXUXMLElementType {
    case Regular
    case ContentOnly
    case CDataOnly
    case ProcessingInstruction
}