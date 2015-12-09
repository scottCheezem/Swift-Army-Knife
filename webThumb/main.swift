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

var urlArg = Process.arguments[1]
print(urlArg)
let webView = WebView()
webView.frame = CGRectMake(0, 0, 100, 100)
let url = NSURL(string: urlArg)
let urlRequest = NSURLRequest(URL: url!)

//webView.mainFrameURL = url
webView.shouldUpdateWhileOffscreen = true
webView.mainFrame.loadRequest(urlRequest)
