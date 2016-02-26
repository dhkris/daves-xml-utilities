//
//  DXUXpathQuery.swift
//  DXUNetworking
//
//  Created by David Christensen on 29/06/15.
//  Copyright (c) 2015 David Christensen. All rights reserved.
//

import Foundation

public enum DXUXpathResultType: Int {
    case Nil = 0
    case Single = 1
    case Array = 2
}


// MARK: - Helper functions and closures (need cleanup)
/// Private (file local) extension, implementing a function similar to 
/// JavaScript's ord(char) -> [code point value]. 
private extension String {
    var o: UInt8 {
        let view = (self as NSString).substringToIndex(1)
        let bytes = (view as NSString).cStringUsingEncoding(NSUTF8StringEncoding)
        var map = Int16(bytes.memory)
        if map < 0 {
            map =  (-1*map) - 256
        }
        return UInt8(map % 256)
    }
}


/// Helper function: turn a character into a byte.
private func ord(string: String) -> UInt8 {
    return string.o
}

/// Helper function: turn a byte into a character. Inverse of ord(String) -> UInt8
private func chr(byte: UInt8) -> String {
    return NSString(format: "%c", byte) as String
}

/// Helper closure: Is byte a tag name character?
private let xpathIsEntityNameContaining: UInt8 -> Bool = {
    (byte: UInt8) -> Bool in
    return (byte >= ord("a") && byte <= ord("z")) || (byte == ord(":")) || (byte == ord("_"))
}

private let xpathIsComparison: UInt8 -> Bool = {
    (byte: UInt8) -> Bool in
    return (byte == "=".o || byte == "<".o || byte == ">".o || byte == "!".o)
}


/// Helper closure: Is byte a digit?
private let xpathIsDigit: UInt8 -> Bool = { ($0 >= ord("0")) && ($0 <= ord("9")) || ($0 == ord(".")) }

/// Helper closure: Is byte a forward slash?
private let xpathIsPath: UInt8 -> Bool = { $0 == ord("/") }

/// Helper closure: Is byte a square bracket?
private let xpathIsSquareBracket: UInt8 -> Bool = { $0 == ord("[") }

private let xpathIsAttr: UInt8 -> Bool = {
    return $0 == ord("@")
}

private let xpathIsWhitespace: UInt8 -> Bool = {
    byte -> Bool in
    return byte == ord(" ") || byte == ord("\"") || byte == ord("'")
}

/// Helper closure: Is byte an asterisk?
private let xpathIsAny: UInt8 -> Bool = { $0 == ord("*") }


// MARK: - XPath compiler
/// XPath Lite integration, baked-into the DXUXMLElement class
public class DXUXPath {
    /**
    Tokenize and parse the XPath query into a linear stream of operators.
    Throws an DXUXPathCompileError in case of compilation error.
    
    - parameter string: XPath query string
    
    - returns: Array of XPath operators and associated values
    */
    class public func compile(string: String) throws -> DXUXPathQuery {
        var charPtr = 0, // This is the most performant way, simple indexing
            currentPtr: DXUXPathInstruction = .Null, // The current instruction
            buffer = Array<DXUXPathOperation>(), // The instruction stream being constructed
            elemBuffer: String = "", // String buffer of the current token
            pathExpressionPtr = DXUXPathPathExpression.Unknown // Current (if any) expression
        
        while(charPtr < string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)) {
            var byteType: DXUXPathTokenType = .Other
            let c = (string.lowercaseString as NSString).substringWithRange(NSMakeRange(charPtr, 1))
            let s = ord(c)
            
            // Evaluate, what kind of input byte we're encountering...
            if xpathIsEntityNameContaining(s) { byteType = .EntityNameContaining }
            else if xpathIsComparison(s) { byteType = .Comparison }
            else if xpathIsAttr(s) { byteType = .AttributeIndicator }
            else if xpathIsDigit(s) { byteType = .Digit }
            else if xpathIsPath(s) { byteType = .Path }
            else if xpathIsSquareBracket(s) { byteType = .SquareBracket }
            else if xpathIsAny(s) { byteType = .Any }
            
            // Handle the different input byte types. Each case has
            // different rules according to the predicted token type, and may terminate
            // the instruction being accumulated currently.
            
            if currentPtr == .PathExpression {
                if c == " " && elemBuffer.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 0 { }
                else if c == "]" && elemBuffer.substringFromIndex(elemBuffer.endIndex.predecessor()) != "\\" {
                    
                    let initialCharacter = elemBuffer.substringToIndex(elemBuffer.startIndex.successor())
                    
                    // Determine the type of path expression
                    if initialCharacter == "@" {
                        pathExpressionPtr = DXUXPathPathExpression.AttributeCondition(condition: elemBuffer.substringFromIndex(elemBuffer.startIndex.successor()))
                    } else if xpathIsDigit(ord(initialCharacter)) {
                        if let definedIdx = Int(elemBuffer) {
                            pathExpressionPtr = DXUXPathPathExpression.Index(value: definedIdx)
                        } else {
                            // This is probably a range?
                            let subComponents = elemBuffer.componentsSeparatedByString(":")
                            if subComponents.count == 2 {
                                if let a = Int(subComponents[0]),
                                       b = Int(subComponents[1]) {
                                    let range = Range<Int>(start: a, end: b)
                                    pathExpressionPtr = DXUXPathPathExpression.IndexRange(value: range)
                                }
                            }
                        }
                    } else if xpathIsEntityNameContaining(ord(initialCharacter)) {
                        // This is probably a "has child named..." path expression
                        pathExpressionPtr = DXUXPathPathExpression.HasChildOfType(type: elemBuffer)
                    }
                    currentPtr = .Null
                    elemBuffer = ""
                    buffer.append(DXUXPathOperation(instruction: DXUXPathInstruction.PathExpression, pathExpression: pathExpressionPtr))
                } else {
                    elemBuffer += c
                }
                charPtr += 1
                continue
            }
            
            if byteType == .SquareBracket {
                if currentPtr != .Index {
                    buffer.append(DXUXPathOperation(instruction: currentPtr, parameter: elemBuffer))
                    currentPtr = .PathExpression
                    pathExpressionPtr = .Unknown
                    elemBuffer = ""
                }
            }

                
            else if byteType == .Comparison {
                if currentPtr != .AttributePredicate {
                    throw DXUXPathCompileError(errorMessage: "Comparison in non-attribute predicate", errorType: DXUXPathCompileErrorType.UnexpectedToken, compileState: (inputType: byteType, instructionType: currentPtr, currentToken: elemBuffer, character: c, index: charPtr))
                }
                elemBuffer += c
            }
                
            else if byteType == .Digit {
                if currentPtr == .AttributePredicate {
                    elemBuffer += c
                }
            }
                
            else if byteType == .EntityNameContaining {
                
                if currentPtr == .ElementName {
                    elemBuffer += c
                }
                else if currentPtr == .AttributePredicate {
                    elemBuffer += c
                }
                else if currentPtr == .Null {
                    elemBuffer = c
                    currentPtr = .ElementName
                }
                else if currentPtr == .ChildOperator || currentPtr == .DescendantOperator {
                    buffer.append(DXUXPathOperation(instruction: currentPtr, parameter: elemBuffer))
                    elemBuffer = c
                    currentPtr = .ElementName
                    xmllog("Grabbed element name \(c)")
                }
                else {
                    xmllog("Error")
                    return []
                } // Error
            }
            else if byteType == .Path {
                xmllog("Path with E-bfr \(elemBuffer)")
                if currentPtr == .ChildOperator {
                    elemBuffer += c
                    currentPtr = .DescendantOperator
                }
                else {
                    xmllog("Has elem buffer: \(elemBuffer), e-type: \(currentPtr.rawValue)")
                    buffer.append(DXUXPathOperation(instruction: currentPtr, parameter: elemBuffer))
                    currentPtr = .ChildOperator
                    elemBuffer = c
                }
            }
            else if byteType == .AttributeIndicator {
                print("Found attr indicator")
                if currentPtr == .ChildOperator || currentPtr == .DescendantOperator {
                    buffer.append(DXUXPathOperation(instruction: currentPtr, parameter: elemBuffer))
                    elemBuffer = c
                    currentPtr = .ElementName
                    xmllog("Grabbed element name \(c)")
                } else {
                    buffer.append(DXUXPathOperation(instruction: currentPtr, parameter: elemBuffer))
                }
                elemBuffer = ""
                currentPtr = .AttributePredicate
            }
            else if byteType == .Any {
                elemBuffer = ""
                buffer.append(DXUXPathOperation(instruction: currentPtr, parameter: elemBuffer))
                currentPtr = .AnyChild
            } else {
                throw DXUXPathCompileError(errorMessage: "Unexpected character", errorType: DXUXPathCompileErrorType.UnexpectedToken, compileState: (inputType: byteType, instructionType: currentPtr, currentToken: elemBuffer, character: c, index: charPtr))
            }
            
            charPtr += 1
            
        }
        buffer.append(DXUXPathOperation(instruction: currentPtr, parameter: elemBuffer))
     
        return buffer
    }
    
    /**
    Evaluate a given XPath parse output on a given tag, returning an array of results (if any)
    
    - parameter element: XML element to evaluate query on
    - parameter tree:    Parse tree
    
    - returns: Array of XML elements matching the query
    */
    class public func evaluate(onElement element: DXUXMLElement, withParseResult tree: DXUXPathQuery) -> [DXUXMLElement] {
        var resultBuf: [DXUXMLElement] = [element]
        for instruction in tree {
            
            if(instruction.instruction == .Null) {
                continue
            } else if(instruction.instruction == DXUXPathInstruction.AttributePredicate) {
                let bfr = DXUXPath.evaluateCondition(string: instruction.parameter, onElements: resultBuf)
                resultBuf = bfr
                continue
            } else if(instruction.instruction == .PathExpression) {
                switch(instruction.pathExpression!) {
                case .AttributeCondition(condition: let condition):
                    let bfr = DXUXPath.evaluateCondition(string: condition, onElements: resultBuf)
                    resultBuf = bfr
                case .HasChildOfType(type: let type):
                    let buf = resultBuf
                    resultBuf = []
                    for x in buf {
                        if x.children.filter({ $0.name == type }).count > 0 {
                            resultBuf.append(x)
                        }
                    }
                case .Index(value: let idx):
                    resultBuf = [resultBuf[idx]]
                case .IndexRange(value: let idxRange):
                    let slice = resultBuf[idxRange]
                    resultBuf = []
                    resultBuf.appendContentsOf(slice)
                case .Unknown:
                    print("Unknown path expr")
                }
                continue
            }
            
            var accumulatedResult: Array<DXUXMLElement> = []
            
            for tag in resultBuf {
                xmllog(" --- \(tag.name)")
                if(instruction.instruction == .ChildOperator) {
                    for child in tag.children {
                        if(child.type == .Regular) {
                            xmllog("Appending tag \(child.name)")
                            accumulatedResult.append(child)
                        }
                    }
                }
                else if(instruction.instruction == .DescendantOperator) {
                    for descendant in tag.descendants(satisfying: {
                        (elem) -> Bool in
                        return true
                    }) {
                        accumulatedResult.append(descendant)
                    }
                }
                else if(instruction.instruction == .ElementName) {
                    if(tag.name.lowercaseString == instruction.parameter) {
                        accumulatedResult.append(tag)
                    }
                }
                
            }
            
            resultBuf = accumulatedResult
            
        }
        return resultBuf
    }
 
    /**
        Evaluate a DXUXPathPathExpression of type "AttributeCondition".
    */
    class func evaluateCondition(string string: String, onElements: [DXUXMLElement], DXUassemblyResult: NSMutableString? = nil) -> [DXUXMLElement] {
        
        var output: [DXUXMLElement] = []
        
        if string.componentsSeparatedByString(">=").count >= 2 {
            let components = string.componentsSeparatedByString(">=")
            let attribute = components[0]
            let value = components[1]
            DXUassemblyResult?.appendFormat("GEQ? *%@, .\"%@\"\n", attribute, value)
            
            for element in onElements {
                
                if let attributeValue = element.typedAttributes[attribute] {
                    switch(attributeValue) {
                    case .Text(let stringValue):
                        let comparisonResult = stringValue.compare(value)
                        if comparisonResult == NSComparisonResult.OrderedDescending || comparisonResult == .OrderedSame {
                            output.append(element)
                        }
                    case .Integer(let integerValue):
                        if integerValue >= (Int(value) ?? -65535) {
                            output.append(element)
                        }
                    case .FloatingPoint(let floatValue):
                        print("Got floatValue, \(floatValue) for \(attribute). Comparing if > than \(value)")
                        if floatValue >= (Double(value) ?? -65535) {
                            print("Appended output element")
                            output.append(element)
                        }
                    case .Boolean(let boolValue):
                        if (boolValue) == (value.lowercaseString == "true") {
                            output.append(element)
                        }
                    default:
                        break
                    }
                }
                
            }
        }
        else if string.componentsSeparatedByString("<=").count >= 2 {
            let components = string.componentsSeparatedByString("<=")
            let attribute = components[0]
            let value = components[1]
            DXUassemblyResult?.appendFormat("LEQ? *%@, .\"%@\"\n", attribute, value)
            
            for element in onElements {
                
                if let attributeValue = element.typedAttributes[attribute] {
                    switch(attributeValue) {
                    case .Text(let stringValue):
                        let comparisonResult = stringValue.compare(value)
                        if comparisonResult == NSComparisonResult.OrderedAscending || comparisonResult == .OrderedSame {
                            output.append(element)
                        }
                    case .Integer(let integerValue):
                        if integerValue <= (Int(value) ?? -65535) {
                            output.append(element)
                        }
                    case .FloatingPoint(let floatValue):
                        print("Got floatValue, \(floatValue) for \(attribute). Comparing if > than \(value)")
                        if floatValue <= (Double(value) ?? -65535) {
                            print("Appended output element")
                            output.append(element)
                        }
                    case .Boolean(let boolValue):
                        if (boolValue) == (value.lowercaseString == "true") {
                            output.append(element)
                        }
                    default:
                        break
                    }
                }
                
            }
        }
        else if string.componentsSeparatedByString("<").count >= 2 {
            let components = string.componentsSeparatedByString("<")
            let attribute = components[0]
            let value = components[1]
            DXUassemblyResult?.appendFormat("LT? *%@, .\"%@\"\n", attribute, value)
            for element in onElements {
                
                if let attributeValue = element.typedAttributes[attribute] {
                    switch(attributeValue) {
                    case .Text(let stringValue):
                        let comparisonResult = stringValue.compare(value)
                        if comparisonResult == NSComparisonResult.OrderedAscending {
                            output.append(element)
                        }
                    case .Integer(let integerValue):
                        if integerValue < (Int(value) ?? -65535) {
                            output.append(element)
                        }
                    case .FloatingPoint(let floatValue):
                        print("Got floatValue, \(floatValue) for \(attribute). Comparing if > than \(value)")
                        if floatValue < (Double(value) ?? -65535) {
                            print("Appended output element")
                            output.append(element)
                        }
                    case .Boolean(let boolValue):
                        if (boolValue) != (value.lowercaseString == "true") {
                            output.append(element)
                        }
                    default:
                        break
                    }
                }
                
            }
        }
        else if string.componentsSeparatedByString(">").count >= 2 {
            let components = string.componentsSeparatedByString(">")
            let attribute = components[0]
            let value = components[1]
            DXUassemblyResult?.appendFormat("GT? *%@, .\"%@\"\n", attribute, value)
            for element in onElements {
                if element.typedAttributes == nil {
                    continue
                }
                if let attributeValue = element.typedAttributes[attribute] {
                    switch(attributeValue) {
                    case .Text(let stringValue):
                        let comparisonResult = stringValue.compare(value)
                        if comparisonResult == NSComparisonResult.OrderedDescending {
                            output.append(element)
                        }
                    case .Integer(let integerValue):
                        if integerValue > (Int(value) ?? -65535) {
                            output.append(element)
                        }
                    case .FloatingPoint(let floatValue):
                        print("Got floatValue, \(floatValue) for \(attribute). Comparing if > than \(value)")
                        if floatValue > (Double(value) ?? -65535) {
                            print("Appended output element")
                            output.append(element)
                        }
                    case .Boolean(let boolValue):
                        if (boolValue) != (value.lowercaseString == "true") {
                            output.append(element)
                        }
                    default:
                        break
                    }
                }
                
            }
        }
        else if string.componentsSeparatedByString("!=").count >= 2 {
            let components = string.componentsSeparatedByString("!=")
            let attribute = components[0]
            let value = components[1]
            DXUassemblyResult?.appendFormat("NEQ *%@, .\"%@\"\n", attribute, value)
            for element in onElements {
                if let attributeValue = element.typedAttributes[attribute] {
                    switch(attributeValue) {
                    case .Text(let stringValue):
                        let comparisonResult = stringValue.compare(value)
                        if comparisonResult != NSComparisonResult.OrderedSame {
                            output.append(element)
                        }
                    case .Integer(let integerValue):
                        if (Int(value) ?? -65535) != integerValue {
                            output.append(element)
                        }
                    case .FloatingPoint(let floatValue):
                        if (Double(value) ?? -65535) != floatValue {
                            output.append(element)
                        }
                    case .Boolean(let boolValue):
                        if (boolValue) != (value.lowercaseString == "true") {
                            output.append(element)
                        }
                    default:
                        break
                    }
                }
                
            }
        }
        else if string.componentsSeparatedByString("=").count >= 2 {
            let components = string.componentsSeparatedByString("=")
            let attribute = components[0]
            let value = components[1]
            DXUassemblyResult?.appendFormat("EQL? *%@, .\"%@\"\n", attribute, value)
            for element in onElements {
                
                if let attributeValue = element.typedAttributes[attribute] {
                    switch(attributeValue) {
                    case .Text(let stringValue):
                        let comparisonResult = stringValue.compare(value)
                        if comparisonResult == NSComparisonResult.OrderedSame {
                            output.append(element)
                        }
                    case .Integer(let integerValue):
                        if integerValue == (Int(value) ?? -65535) {
                            output.append(element)
                        }
                    case .FloatingPoint(let floatValue):
                        print("Got floatValue, \(floatValue) for \(attribute). Comparing if > than \(value)")
                        if floatValue == (Double(value) ?? -65535) {
                            print("Appended output element")
                            output.append(element)
                        }
                    case .Boolean(let boolValue):
                        if (boolValue) == (value.lowercaseString == "true") {
                            output.append(element)
                        }
                    default:
                        break
                    }
                }
                
            }
        }
        else {
            // Assume we just want tags with a given property since the caller will evaluate
            // other types of path expressions.
            for element in onElements {
                if let _ = element.attributes[string] as? String {
                    output.append(element)
                }
            }
        }
        
        return output
        
    }
    
}