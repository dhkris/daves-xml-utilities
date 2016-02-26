//
//  DXUXPathTokenType.swift
//  DXUNetworking
//
//  Created by David Christensen on 07/08/15.
//  Copyright © 2015 David Christensen. All rights reserved.
//

import Foundation

internal enum DXUXPathTokenType: String {
    case EntityNameContaining
    case Digit
    case Path
    case SquareBracket
    case Any
    case AttributeIndicator
    case Comparison
    case Other
}