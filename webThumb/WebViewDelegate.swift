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

enum StateKey : String {
    case Begin = "begin"
    case WhenURLMatches = "whenUrlMatches"
}


enum ActionKey : String {
    case StartURL = "startUrl"
    case RegexURL = "regexUrl"
    case SavePictureAt = "SavePictureAt"
    case Action = "takeAction"
    case InnerText = "InnerText"
    case OuterHTML = "OuterHTML"
    case Exit = "Exit"
}

class WebViewDelegate: NSObject,WebFrameLoadDelegate {

    
    var currentState : StateKey = .Begin
    var currentAction : ActionKey = .Action
    
    var commandDict:[String:AnyObject] = [:]
//    static let startingIndexPath = "begin.takeAction"
//    var currentIndexPath = startingIndexPath
    
    
    
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        
        //        sender.mainFrame.DOMDocument.documentElement.innerText
        //        sender.mainFrame.DOMDocument.documentElement.outerHTML
        
        switch currentState {
            case .Begin :
                
                    self.currentState = .WhenURLMatches
                break;
            case .WhenURLMatches:
                break;
        }
        
        
        
        let actionItem = (commandDict as NSDictionary).valueForKeyPath(currentState.rawValue + "." + currentAction.rawValue)
        let actionScript =  actionItem as? String
        
        let result = sender.windowScriptObject.evaluateWebScript(actionScript)
        debugPrint(result)
        
        
        
        
        debugPrint(sender.mainFrameURL)
        
//        var scriptString = "$('input[name=Distance]').filter(':last')[0].checked = true;"
//        scriptString+="$('input[name=Zip]').val('43215');"
//        scriptString+="$('#resultSize > option').filter(':last').attr('selected', 'selected');"
//        scriptString+="$('input[value=\"Search for a Dentist\"]').last().click();console.log(\"testing\");"
//        debugPrint(scriptString)
//        
//        let result = sender.windowScriptObject.evaluateWebScript(scriptString) as? String
//        debugPrint(result)
        
        
        
        //read from the commandDict looking for the ActionCommndKeys, and response appropirately
        
        
        
        
    }
    
}
