//
//  DXUXPathCompileError.swift
//  DXUNetworking
//
//  Created by David Christensen on 11/08/15.
//  Copyright © 2015 David Christensen. All rights reserved.
//

import Foundation

/// This is not very useful yet, since the cases do not specify a string
public enum DXUXPathCompileErrorType: String {
    case UnexpectedToken
    case IncompleteExpression
}

/// Compilation error type thrown by the XPath parser-compiler in case it encounters an error
public struct DXUXPathCompileError: CustomStringConvertible, ErrorType {
    
    public var description: String {
        return "XPath error (\(errorType.rawValue)) at character \(compileState.index+1):\n\t\(errorMessage)\n\tError happened while parsing a \(compileState.instructionType.rawValue) instruction"
    }
    
    let errorMessage: String
    let errorType: DXUXPathCompileErrorType
    let compileState: (inputType: DXUXPathTokenType, instructionType: DXUXPathInstruction, currentToken: String, character: String, index: Int)
}