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
        if let data = self.dataUsingEncoding(NSUTF8StringEncoding){
            do {
                let json = try  NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject]
                return json
            }catch let e as NSError{
                debugPrint(e)
            }
            
        }
        return nil
    }
}

