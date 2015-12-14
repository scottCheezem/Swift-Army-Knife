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
        debugPrint(fileContent)
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




//lots of stuff to check the file exists here
//also a different case where we just pipe commands from stdin

var commandDict = fileContent.jsonStringToDict()! as [String:AnyObject]

let webviewDelegate = WebViewDelegate()

webviewDelegate.commandDict = commandDict

guard let startingUrl = (commandDict as NSDictionary).valueForKeyPath("begin.startUrl") as? String else{
    print("there was no startUrl dictionary")
    exit(EXIT_FAILURE)
}


let webView = WebView()

let url = NSURL(string: startingUrl)
let urlRequest = NSURLRequest(URL: url!)


webView.frameLoadDelegate = webviewDelegate
webView.shouldUpdateWhileOffscreen = true
webView.mainFrame.loadRequest(urlRequest)

//webView.frame = CGRectMake(0, 0, 1000, 1000)


CFRunLoopRun()