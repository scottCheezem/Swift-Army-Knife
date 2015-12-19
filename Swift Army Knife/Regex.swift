//
//  Regex.swift
//  webThumb
//
//  Created by Scott Cheezem on 12/13/15.
//  Copyright © 2015 Scott Cheezem. All rights reserved.
//

import Foundation

class Regex {
    var internalExpresseion:NSRegularExpression? = NSRegularExpression()
    var pattern: String? = ""
    
    init(pattern:String){
        do{
            self.internalExpresseion = try NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
        }catch let e as NSError{
            debugPrint(e)
        }
    }
    
    func test(input:String) -> Bool{
        let matches = internalExpresseion?.matchesInString(input, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, input.characters.count))
        return matches?.count > 0
    }
}