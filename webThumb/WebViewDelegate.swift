//
//  WebViewDelegate.swift
//  webThumb
//
//  Created by Scott Cheezem on 12/11/15.
//  Copyright © 2015 Scott Cheezem. All rights reserved.
//

import Cocoa
import Foundation
import WebKit

class WebViewDelegate: NSObject,WebFrameLoadDelegate {

    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        debugPrint("loaded")
        let domDoc = frame.DOMDocument
        
        
    }
    
}
