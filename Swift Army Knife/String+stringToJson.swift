//
//  String+stringToJson.swift
//  webThumb
//
//  Created by Scott Cheezem on 12/13/15.
//  Copyright © 2015 Scott Cheezem. All rights reserved.
//

import Foundation

public extension String {
    
    public func jsonStringToDict() -> [String:AnyObject]? {
        if let data = self.data(using: String.Encoding.utf8){
            do {
                let json = try  JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:AnyObject]
                return json
            }catch let e as NSError{
                debugPrint(e)
            }
            
        }
        return nil
    }
    
    
    
}

