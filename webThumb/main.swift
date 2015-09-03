//
//  main.swift
//  webThumb
//
//  Created by Scott Cheezem on 9/3/15.
//  Copyright (c) 2015 Scott Cheezem. All rights reserved.
//

import Foundation
import WebKit

var urlArg = Process.arguments[1]
println(urlArg)
let webView = WebView()
let url = NSURL(string: urlArg)
let urlRequest = NSURLRequest(URL: url!)

//webView.mainFrameURL = url
webView.shouldUpdateWhileOffscreen = true
webView.mainFrame.loadRequest(urlRequest)
println("done")