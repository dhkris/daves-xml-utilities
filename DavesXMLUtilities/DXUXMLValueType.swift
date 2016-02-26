//
//  DXUXMLValueType.swift
//  DXUNetworking
//
//  Created by David Christensen on 15/10/15.
//  Copyright © 2015 David Christensen. All rights reserved.
//

import Foundation

/// Simple wrapper type, using the beautiful Swift enums-with-storage.
/// Allows a single return type AND enforces type checking when unwrapping
/// the value. Sometimes, it's good to enforce proper practice...
public enum DXUXMLValueType : CustomStringConvertible {
    case Text(String)
    case Integer(Int)
    case FloatingPoint(Double)
    case Boolean(Bool)
    case Bytestream(String)
    static func createFromPrimitive(value: Any) -> DXUXMLValueType {
        if value is String {
            return DXUXMLValueType.Text(value as! String)
        } else if value is Int {
            return DXUXMLValueType.Integer(value as! Int)
        } else if value is Double {
            return DXUXMLValueType.FloatingPoint(value as! Double)
        } else if value is Bool {
            return DXUXMLValueType.Boolean(value as! Bool)
        } else {
            return DXUXMLValueType.Bytestream("\(value)")
        }
    }
    
    public
    var description: String {
        switch(self) {
        case .Text(let stringValue):
            return "xml-string: '''\(stringValue)'''"
        case .Integer(let integerValue):
            return "xml-integer<64.s>: \(integerValue)"
        case .FloatingPoint(let floatValue):
            return "xml-float<ieee.32>: \(floatValue)"
        case .Boolean(let boolValue):
            return "xml-boolean: \(boolValue)"
        default:
            return "xml-unknown-type."
        }
    }
}