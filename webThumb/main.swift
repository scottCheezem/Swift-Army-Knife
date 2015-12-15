//
//  main.swift
//  webThumb
//
//  Created by Scott Cheezem on 9/3/15.
//  Copyright (c) 2015 Scott Cheezem. All rights reserved.
//

import Foundation
import Cocoa
import WebKit

var commandFileInputArg = ""
var fileContent = ""
//for now we'll just take a well formatted json file to read.
if Process.arguments.count > 1{
    commandFileInputArg = Process.arguments[1]
    debugPrint(commandFileInputArg)    
    
    do {
        fileContent = try NSString(contentsOfFile: commandFileInputArg, encoding: NSUTF8StringEncoding) as String
        debugPrint("loaded: ", fileContent)
    }catch let e as NSError {
        debugPrint(e)
        print("Could not open file for reading")
        exit(EXIT_FAILURE)
    }
    
    
}else{
    let stdin = StreamScanner(source: NSFileHandle.fileHandleWithStandardInput(), delimiters: NSCharacterSet.newlineCharacterSet())
    
    while var a:String = stdin.read() {
        fileContent += a+"\n"
    }
}

var commandDict = fileContent.jsonStringToDict()! as [String:AnyObject]

let _ = AutomatedWebView(instructionJson: commandDict)

CFRunLoopRun()