//
//  DXUXMLElement.swift
//  DXUNetworking
//
//  Created by David Christensen on 22/06/15.
//  Copyright (c) 2015 David Christensen. All rights reserved.
//

import Foundation

/**
*  Class describing an XML node, with a references to the element's children and parent, or content and parent, or CDATA and parent.

An element can only have one of the following:

* Children
* Content
* CDATA
*/
public class DXUXMLElement {
    
    public var statedEncoding: String = "utf-8"
    
    private var _name: String!
    /// Full name of the element.
    public var name: String! {
        get { return _name }
        set { _name = newValue }
    }
    
    
    var typedAttributes: [String: DXUXMLValueType]!
    private var _attributes: [NSObject: AnyObject]!
    /// Key-value attributes of the element.
    public var attributes: [NSObject: AnyObject]! {
        get { return _attributes }
        set { _attributes = newValue }
    }
    
    
    /// Array of a type=.Regular element's children
    public var children: [DXUXMLElement]!
    
    /// Element type (Regular, ContentOnly or CDataOnly)
    public var type: DXUXMLElementType = .Regular
    
    
    
    private var _content: String!
    /// String content of a type=.ContentOnly element.
    public var content: String! {
        get { return _content }
        set { _content = newValue }
    }
    
    
    private var _cdata: NSData!
    /// CDATA content of a type=.CDataOnly element.
    public var cdata: NSData! {
        get { return _cdata }
        set { _cdata = newValue }
    }
    
    /// Parent tag. The root tag, by necessity, has nil as the parent.
    public weak var parent: DXUXMLElement!
    
    /// Prefix (if any) of the tag. For instance, soap:body has "soap" as the prefix.
    public var prefix: String? {
        if pfxComponents.count == 1 { return nil }
        else { return pfxComponents.first }
    }
    
    /// Unprefixed name of the element. If no prefix is present, the full name.
    public var unprefixedName: String? {
        if pfxComponents.count == 1 { return self.name }
        else { return pfxComponents.last }
    }
    
    /// Private computed property to subdivide an element's name into prefix and unprefixed name.
    private var pfxComponents: [String] {
        return self.name.componentsSeparatedByString(":")
    }
    
    /**
    Initialise an element with a parent element and a name.
    
    - parameter aParent:  Reference to parent object. The parent object must add the element as a child.
    - parameter withName: Element name. This is the tag name
    
    - returns: New element object describing a named element with a reference to its parent
    */
    public init(asChildOf aParent: DXUXMLElement, withName: String) {
        self.parent = aParent
        self.children = []
        self.content = ""
        self.attributes = [:]
        self.typedAttributes = [:]
        self.name = withName
    }
    
    public init(contentWithParent parent: DXUXMLElement, content: String) {
        self.parent = parent
        self.children = []
        self.type = .ContentOnly
        self.content = content
        self.name = "\\content"
        self.attributes = [:]
        self.typedAttributes = [:]
    }
    
    public init(cdataWithParent parent: DXUXMLElement, cdata: NSData) {
        self.parent = parent
        self.children = []
        self.type = .CDataOnly
        self.cdata = cdata
        self.name = "\\cdata"
        self.attributes = [:]
        self.typedAttributes = [:]
    }
    
    public init(tagWithParent parent: DXUXMLElement, name: String, attributes: [NSObject: AnyObject]?) {
        self.parent = parent
        self.children = []
        self.type = .Regular
        self.name = name
        self.attributes = (attributes ?? [:])
        self.typedAttributes = [:]
    }
    
    /**
    Initialise a blank element.
    
    - returns: New element object
    */
    public init() {
        self.parent = nil
        self.children = []
        self.attributes = [:]
        self.content = ""
        self.name = "root"
    }
    
    public func evaluateXpath(query: String) throws -> [DXUXMLElement] {
        do {
            return try DXUXPath.evaluate(onElement: self, withParseResult: DXUXPath.compile(query))
        } catch  {
            if let compileError = error as? DXUXPathCompileError {
                print("\(compileError)")
            }
            throw error
        }
    }
    
    /// Recursively generate the XML source representation of this tag and its children.
    public var source: String {
        if self.type == .ContentOnly {
            return self.content
        } else if self.type == .CDataOnly {
            return "<![CDATA[\n" + (NSString(data: self.cdata, encoding: NSUTF8StringEncoding) as! String) + "\n]]>"
        }
        
        if self.name == "root" {
            return "<?xml version=\"1.0\" encoding=\"\(statedEncoding)\"?>" + self.children.first!.source
        }
        var childBuffer = ""
        for child in self.children {
            childBuffer += child.source
        }
        return "<\(self.name)\(self.attributeString)>\(childBuffer)</\(self.name)>"
    }

    
    /// XML source representation of the element's attribute dictionary
    private var attributeString: String {
        var buffer = ""
        for (key, value) in attributes {
            buffer += " \(key)=\"\(value)\""
        }
        return buffer
    }
    
    /// Hierarchical string representation of the tag's inheritance
    public var ancestorString: String {
        var buffer = ""
        var pointer = self.parent
        while(pointer != nil) {
            buffer += pointer.name + ":"
            pointer = pointer.parent
            if pointer == nil {
                break
            }
        }
        return buffer
    }
    
    /**
    Get all 1st-level children (not children's children) with the specific element name.
    
    - parameter named: Desired element name

    - returns: Array of children having the specified element name
    */
    func children(named named: String) -> [DXUXMLElement] {
        return self.children.filter {
            return $0.name == named
        }
    }
    
    /**
    Get all nth-level descendants (all the way down the tree) with the specified element name.
    
    - parameter named: Desired descendant element name
    
    - returns: Array of descendants having the specified element name.
    */
    func descendants(named named: String) -> [DXUXMLElement] {
        return descendants().filter { $0.name == named }
    }
    
    /**
    Get all nth-level descendants that satisfy the specified closure boolean.
    
    - parameter closure: Closure describing the condition(s) the descendants must satisfy
    
    - returns: Array of descendants satisfying the specified conditions in the closure
    */
    func descendants(satisfying closure: DXUXMLElement -> Bool) -> [DXUXMLElement] {
        return descendants().filter(closure)
    }
    
    /**
    Get the total number of descendants
    */
    func numberOfDescendants() -> Int {
        return descendants().count
    }
    
    /**
    Get all nth-level ancestors (all the way up the tree) that satisfy the specified closure conditions.
    
    - parameter closure: Closure describing the condition(s) the descendants must satisfy.
    
    - returns: Array of ancestors satisfying the specified conditions in the closure.
    */
    func ancestorsSatisfying(closure: DXUXMLElement -> Bool) -> [DXUXMLElement] {
        var pointer = self.parent,
            ancestry = Array<DXUXMLElement>()
        while(pointer != nil) {
            if closure(pointer) { ancestry.append(pointer) }
            pointer = pointer.parent
        }
        return ancestry
    }
    
    /**
    Return all nth-level descendants of this element.
    
    - parameter depth: OPTIONAL Starting depth (used for indentation). Does NOT specify a limit to downwards tree traversal.
    
    - returns: All descendants of this element.
    */
    func descendants(toDepth depth: Int = 0) -> [DXUXMLElement] {
        let ownChildren = self.children
        let recursedChldren: [[DXUXMLElement]] = ownChildren.map {
            var flat: [DXUXMLElement] = [$0]
            for ch in $0.descendants(toDepth: depth+1) {
                flat.append(ch)
            }
            return Array<DXUXMLElement>(flat)
        }
        
        var childBuffer: [DXUXMLElement] = []
        for child in recursedChldren {
            for subchild in child {
                childBuffer.append(subchild)
            }
        }
        return childBuffer
    }
}