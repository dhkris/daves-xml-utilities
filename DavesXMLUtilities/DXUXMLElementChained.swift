//
//  DXUXMLElementChained.swift
//  DXUNetworking
//
//  Created by David Christensen on 15/08/15.
//  Copyright © 2015 David Christensen. All rights reserved.
//

import Foundation

extension DXUXMLElement {
    
    func addChild(name: String, attributes: [String: String]) -> DXUXMLElement {
        let child = DXUXMLElement(asChildOf: self, withName: name)
        for(key, value) in attributes {
            child.attributes[key] = value
        }
        return child
    }
    
    func addSibling(name: String, attributes: [String: String]) -> DXUXMLElement {
        let sibling = DXUXMLElement(asChildOf: self.parent, withName: name)
        for(key, value) in attributes {
            sibling.attributes[key] = value
        }
        return sibling
    }
    
    var siblings : [DXUXMLElement] {
        return self.parent.children.filter {
            $0 !== self
        }
    }
    
}