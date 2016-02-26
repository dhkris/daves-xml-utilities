//
//  main.swift
//  DavesXMLUtilities
//
//  Created by David Christensen on 26/02/16.
//  Copyright © 2016 David Christensen. All rights reserved.
//

import Foundation

print("Simple test of Dave's XML utilities, fetching an RSS feed and extracting the titles using an XPath expression.")

// Fetch DR.DK RSS news
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { () -> Void in
    
    print("Fetching RSS feed for test...")
    if let inputXml = NSData(contentsOfURL: NSURL(string: "http://www.dr.dk/nyheder/service/feeds/allenyheder")!) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            let parser = DXUXMLParser(data: inputXml)
            print("Total of \(parser.rootElement.descendants().count) XML elements (tags+values) in the output tree.")
            
            print(parser.rootElement.source)
            
            let headlineXpathQueryString = "//title"
            print("News headlines (using the XPath expression: '\(headlineXpathQueryString)')")
            
            do {
                let results = try parser.rootElement.evaluateXpath(headlineXpathQueryString)
                print("\(results.count) headlines found...")
                results.forEach {
                    if let contentChild = $0.children.first, data = contentChild.cdata, stringRepresentation = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        print(" - '\(stringRepresentation)'")
                    }
                }
                exit(0)
            } catch let e as NSError {
                print("Caught error: \(e)")
                exit(1)
            } catch {
                print("Caught unspecified error while evaluating XPath.")
                exit(1)
            }
            
            
        })
        
    }
}

dispatch_main()