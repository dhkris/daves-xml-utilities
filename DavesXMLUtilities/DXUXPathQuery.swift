//
//  DXUXPathQuery.swift
//  DXUNetworking
//
//  Created by David Christensen on 07/08/15.
//  Copyright © 2015 David Christensen. All rights reserved.
//

import Foundation

/// Parse tree type alias for convenience
public typealias DXUXPathQuery = Array<DXUXPathOperation>

/// Useful method to "deparse" an XPath query to an assembly like language.
/// The upcoming LALR parser+compiler (flex+yacc-based) will use this
/// as the intermediate representation.
func DXUXPathQueryDisassemble(query: DXUXPathQuery) -> String {
    var outputBfr = ""
    for operation in query {
        switch(operation.instruction) {
        case .Null:
            if outputBfr == "" {
                outputBfr = "XPATH \(Int(CFAbsoluteTimeGetCurrent()))\n"
            } else {
                outputBfr += "   NOOP\n"
            }
        case .ChildOperator:
            outputBfr += "   CHILDREN\n"
        case .DescendantOperator:
            outputBfr += "   DESCENDANTS\n"
        case .ElementName:
            outputBfr += "      NAMED #\(operation.parameter) \n"
        case .TypedChild:
            outputBfr += "   CHLN \(operation.parameter)\n"
        case .ExprChild:
            outputBfr += "   CHLX \(operation.parameter)\n"
        case .AnyChild:
            outputBfr += "   CHLA\n"
        case .AttributePredicate:
            outputBfr += "      WHERE "
            let mutable = NSMutableString()
            DXUXPath.evaluateCondition(string: operation.parameter, onElements: [], DXUassemblyResult: mutable)
            outputBfr += mutable as String
        case .Index:
            if operation.parameter == "" {
            } else {
                outputBfr += "      ATINDEX #\(operation.parameter)\n"
            }
        case .PathExpression:
            switch(operation.pathExpression!) {
            case .Index(value: let index):
                outputBfr += "  PEXP.IDX #\(index)\n"
            case .IndexRange(value: let idxRange):
                outputBfr += "  PEXP.IDXRANGE #\(idxRange.startIndex), #\(idxRange.endIndex)\n"
            case .AttributeCondition(condition: let conditional):
                outputBfr += "  WHERE "
                let mutable = NSMutableString()
                DXUXPath.evaluateCondition(string: conditional, onElements: [], DXUassemblyResult: mutable)
                outputBfr += mutable as String
            case .HasChildOfType(type: let type):
                outputBfr += "  PEXP.HASCHILD '\(type)'\n"
            case .Unknown:
                outputBfr += "  PEXP.NOP\n"
            }
        }
    }
    outputBfr += "END"
    return outputBfr
}