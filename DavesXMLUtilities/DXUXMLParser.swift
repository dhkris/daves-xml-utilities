//
//  DXUXMLParser.swift
//  DXUNetworking
//
//  Created by David Christensen on 22/06/15.
//  Copyright (c) 2015 David Christensen. All rights reserved.
//

import Foundation

public var DXUXMLParsingLoggingEnabled = false

/// ...this is really a stub
internal func xmllog(string: String) {
    if DXUXMLParsingLoggingEnabled == true {
        print(string)
    }
}

/// Identifying root element key
public let DXUXMLRootElementKey = "rootElement"

/**
DXUXMLParser implements a DOM-like accessor to a given XML document.

At the core, DXUXMLParser uses NSXMLParser, which is an event-based (i.e. SAX-based) parser. However,
DXUXMLParser constructs a sparse and skinny tree representation, which can be traversed from the root element.

Each element is represented by the DXUXMLElement class.

Performance is very good. Benchmarks using a 80 kilobyte/3500 element XML document results in the following performance characteristics:

* <b>iPad Air 2:</b> 81 ms
* <b>iPhone 6:</b> 89 ms
* <b>iPhone 5s/iPad Air/iPad Mini Retina 2+3:</b> 109 ms
* <b>iPhone 5:</b> 149 ms
*/
public class DXUXMLParser : NSObject, NSXMLParserDelegate {
   
    private var xmlData: NSData
    private var parser: NSXMLParser!
    
    /**
    Initialise the parser with a document provided in the supplied string
    
    - parameter string: String containing the valid XML document to parse
    
    - returns: New DXUXMLParser object
    */
    public init(string: String) {
        self.xmlData = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
    
    /**
    Initialise the parser with a document provided byte-wise in the supplied NSData object.
    
    - parameter data: Document data
    
    - returns: New DXUXMLParser objects
    */
    public init(data: NSData) {
        self.xmlData = data
    }

    
    
    
    private var parseBuffer: DXUXMLElement!
    private var parsePointer: DXUXMLElement!
    private var parseLogOut: [String: AnyObject]!
    
    /// Parse to a DXUClient-compatible form, returning a dictionary with a single key-value pair. The key "rootElement" has the parsed document's root element as value.
    public var parse: [String: AnyObject]? {
        parseBuffer = DXUXMLElement()
        parsePointer = parseBuffer
        parseLogOut = [:]
        self.parser = NSXMLParser(data: self.xmlData)
        self.parser.delegate = self
        self.parser.parse()
        return [DXUXMLRootElementKey: parseBuffer]
    }
    
    /// Return the root element of the parsed document
    public var rootElement: DXUXMLElement {
        if self.parseBuffer == nil {
            self.parse
        }
        return self.parseBuffer
    }
    
    
    /**
        Create a wrapped (enum-with-storage) value from an attribute string.
        This has three primary advantages:
     
            * Allows true numeric (integer and floating point) and boolean comparisons
            * Better performance when dealing with numbers and booleans
            * Enforces type checking when using values, since the value is typically unwrapped with a switch statement.
    */
    func createAttributeValue(fromString value: String) -> DXUXMLValueType {
        if Int(value) != nil {
            return DXUXMLValueType.Integer(Int(value)!)
        } else if Double(value) != nil {
            return DXUXMLValueType.FloatingPoint(Double(value)!)
        } else if value.lowercaseString == "true" || value.lowercaseString == "false" {
            return DXUXMLValueType.Boolean(value.lowercaseString == "true")
        } else {
            return DXUXMLValueType.Text(value)
        }
    }
    
    // MARK: - NSXMLParser delegate (event callback) method implementations
    public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        let element = DXUXMLElement(asChildOf: parsePointer, withName: elementName)
        element.attributes = attributeDict
        parsePointer.children.append(element)
        parsePointer = element
        element.typedAttributes = [:]
        
        for (key, value) in attributeDict {
            element.typedAttributes[key] = createAttributeValue(fromString: value)
        }

        xmllog("START \(element.name) as child of \(element.ancestorString)")
        if(attributeDict.count > 0) {
            xmllog("\t\tPROPERTIES: \(attributeDict)")
        }
        
    }
    
    public func parser(parser: NSXMLParser, foundCharacters string: String) {
        xmllog("CONTENT \(parsePointer.name):\(parsePointer.ancestorString) <-- \"\(string)\"")
        let contentNode = DXUXMLElement(asChildOf: parsePointer, withName: "\\content")
        contentNode.type = .ContentOnly
        contentNode.content = string
        if string == " " || string == "  " || string == "\n" || string == "\t" { return }
        parsePointer.children.append(contentNode)
    }
    public func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData) {
        let contentNode = DXUXMLElement(asChildOf: parsePointer, withName: "\\cdata")
        contentNode.cdata = CDATABlock
        contentNode.type = .CDataOnly
        parsePointer.children.append(contentNode)
    }
    
    public func parserDidEndDocument(parser: NSXMLParser) {
        xmllog("Parser ended document")
    }
    
    public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        xmllog("END \(parsePointer.name) as child of \(parsePointer.ancestorString)")
        if let parentElementPtr = parsePointer?.parent {
            parsePointer = parentElementPtr
        }
    }
    
}
