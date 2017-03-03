//
//  Created by Anthony Shoumikhin on 6/25/15.
//  Copyright © 2015 shoumikh.in. All rights reserved.
//

import Foundation

public protocol Scannable {}

extension String: Scannable {}
extension Int: Scannable {}
extension Int32: Scannable {}
extension Int64: Scannable {}
extension UInt64: Scannable {}
extension Float: Scannable {}
extension Double: Scannable {}

open class StreamScanner : IteratorProtocol, Sequence
{
    open static let standardInput = StreamScanner(source: FileHandle.standardInput)
    fileprivate let source: FileHandle
    fileprivate let delimiters: CharacterSet
    fileprivate var buffer: Scanner?
    
    public init(source: FileHandle, delimiters: CharacterSet = CharacterSet.whitespacesAndNewlines)
    {
        self.source = source
        self.delimiters = delimiters
    }
    
    open func next() -> String?
    {
        return read()
    }
    
    open func makeIterator() -> Self
    {
        return self
    }
    
    open func ready() -> Bool
    {
        if buffer == nil || buffer!.isAtEnd
        {   //init or append the buffer
            let availableData = source.availableData
            
            if
                availableData.count > 0,
                let nextInput = NSString(data: availableData, encoding: String.Encoding.utf8.rawValue)
            {
                buffer = Scanner(string: nextInput as String)
            }
        }
        
        return buffer != nil && !buffer!.isAtEnd
    }
    
    open func read<T: Scannable>() -> T?
    {
        if ready()
        {
            var token: NSString?
            
            //grab the next valid characters into token
            if buffer!.scanUpToCharacters(from: delimiters, into: &token) && token != nil
            {
                //skip delimiters for the next invocation
                buffer!.scanCharacters(from: delimiters, into: nil)
                
                //convert the token into an instance of type T and return it
                return convert(token as! String)
            }
        }
        
        return nil
    }
    
    fileprivate func convert<T: Scannable>(_ token: String) -> T?
    {
        var ret: T? = nil
        
        if ret is String? { return token as? T }
        
        let scanner = Scanner(string: token)
        
        switch ret
        {
        case is Int? :
            var value: Int = 0
            if scanner.scanInt(&value)
            {
                ret = value as? T
            }
        case is Int32? :
            var value: Int32 = 0
            if scanner.scanInt32(&value)
            {
                ret = value as? T
            }
        case is Int64? :
            var value: Int64 = 0
            if scanner.scanInt64(&value)
            {
                ret = value as? T
            }
        case is UInt64? :
            var value: UInt64 = 0
            if scanner.scanUnsignedLongLong(&value)
            {
                ret = value as? T
            }
        case is Float? :
            var value: Float = 0
            if scanner.scanFloat(&value)
            {
                ret = value as? T
            }
        case is Double? :
            var value: Double = 0
            if scanner.scanDouble(&value)
            {
                ret = value as? T
            }
        default :
            ret = nil
        }
        
        return ret
    }
}
