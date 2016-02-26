//
//  DXUXPathOperation.swift
//  DXUNetworking
//
//  Created by David Christensen on 07/08/15.
//  Copyright © 2015 David Christensen. All rights reserved.
//

import Foundation

/**
 Pass-by value type describing a single XPath interpreter instruction.
*/
public struct DXUXPathOperation {
    
    /// Instruction type
    let instruction: DXUXPathInstruction
    
    /// (Optional) value, such as index or tag name
    let parameter: String!
    
    /// Optional path expression, being evaluated by the conditional evaluator engine
    let pathExpression: DXUXPathPathExpression!
    
    /// Initialise a simple XPath instruction
    init(instruction: DXUXPathInstruction, parameter: String) {
        self.instruction = instruction
        self.parameter = parameter
        self.pathExpression = nil
    }
    
    /// Initialise an XPath instruction with a conditional expression
    init(instruction: DXUXPathInstruction, pathExpression: DXUXPathPathExpression) {
        self.instruction = instruction
        self.parameter = nil
        self.pathExpression = pathExpression
    }
}