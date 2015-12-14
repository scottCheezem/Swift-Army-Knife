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


//for now we'll just take a well formatted json file to read.
var commandFileInputArg = Process.arguments[1]
debugPrint(commandFileInputArg)

var fileContent = ""

do {
    fileContent = try NSString(contentsOfFile: commandFileInputArg, encoding: NSUTF8StringEncoding) as String
    debugPrint(fileContent)
}catch let e as NSError {
    debugPrint(e)
}

//lots of stuff to check the file exists here
//also a different case where we just pipe commands from stdin

var commandDict = fileContent.jsonStringToDict()! as [String:AnyObject]

let webviewDelegate = WebViewDelegate()
webviewDelegate.commandDict = commandDict

let startingUrl = (commandDict as NSDictionary).valueForKeyPath("begin.startUrl") as? String




let webView = WebView()
webView.frame = CGRectMake(0, 0, 1000, 1000)

let url = NSURL(string: startingUrl!)
let urlRequest = NSURLRequest(URL: url!)


webView.frameLoadDelegate = webviewDelegate
webView.shouldUpdateWhileOffscreen = true
webView.mainFrame.loadRequest(urlRequest)


CFRunLoopRun()