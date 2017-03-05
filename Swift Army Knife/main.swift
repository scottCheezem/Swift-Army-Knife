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
if CommandLine.arguments.count > 1{
    commandFileInputArg = CommandLine.arguments[1]
//    debugPrint(commandFileInputArg)    
    
    do {
        fileContent = try NSString(contentsOfFile: commandFileInputArg, encoding: String.Encoding.utf8.rawValue) as String
//        debugPrint("loaded: ", fileContent)
    }catch let e as NSError {
        debugPrint(e)
        print("Could not open file for reading")
        exit(EXIT_FAILURE)
    }
    
    
}else{
    let stdin = StreamScanner(source: FileHandle.standardInput, delimiters: CharacterSet.newlines)
    
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
let startingUrl = URL(string : startingUrlString!)
let startingUrlRequest = URLRequest(url: startingUrl!)


//debugPrint("loading ", startingUrlString)
webView.mainFrame.load(startingUrlRequest)
webView.frameLoadDelegate = webViewLoadDelegate



CFRunLoopRun()
