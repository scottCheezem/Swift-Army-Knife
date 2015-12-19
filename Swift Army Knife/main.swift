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
//import AutomatedWebView

var commandFileInputArg = ""
var fileContent = ""
//for now we'll just take a well formatted json file to read.
if Process.arguments.count > 1{
    commandFileInputArg = Process.arguments[1]
//    debugPrint(commandFileInputArg)    
    
    do {
        fileContent = try NSString(contentsOfFile: commandFileInputArg, encoding: NSUTF8StringEncoding) as String
//        debugPrint("loaded: ", fileContent)
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

let webViewLoadDelegate = AutomatedWebView(instructionJson: commandDict)
let webView = WebView()
webView.shouldUpdateWhileOffscreen = true
//webView.frame = CGRectMake(0, 0, 1000, 1000) // this will be for saving images of the page , or pdfs//maybe to a resize to match the content size

let startingUrlString = webViewLoadDelegate.setupAction?.regExUrlString
let startingUrl = NSURL(string : startingUrlString!)
let startingUrlRequest = NSURLRequest(URL: startingUrl!)


//debugPrint("loading ", startingUrlString)
webView.mainFrame.loadRequest(startingUrlRequest)
webView.frameLoadDelegate = webViewLoadDelegate



CFRunLoopRun()