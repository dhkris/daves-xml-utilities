//
//  DXUXPathInstruction.swift
//  DXUNetworking
//
//  Created by David Christensen on 07/08/15.
//  Copyright © 2015 David Christensen. All rights reserved.
//

import Foundation

/// Enumerated type
public enum DXUXPathInstruction : String {
    case Null = "null"
    case ElementName = "element"
    case ChildOperator = "child"
    case DescendantOperator = "descendant"
    case TypedChild = "typed"
    case AnyChild = "anychild"
    case ExprChild = "chxpr"
    case AttributePredicate = "attrib"
    case Index = "idx"
    case PathExpression = "px"
}

/// Enumerated type describing types of conditional expressions.
public enum DXUXPathPathExpression {
    
    /// Simple result indexing, i.e. /a/b[1]
    case Index (value: Int)
    
    /// Simple result slicing, i.e. /a/b[0:5]
    case IndexRange (value: Range<Int>)
    
    /// Simple "has descendant" condition
    case HasChildOfType (type: String)
    
    /// Simple boolean expression, i.e. /a/b[@version>2]
    case AttributeCondition (condition: String)
    
    /// Invalid or unimplemented expression
    case Unknown
}
