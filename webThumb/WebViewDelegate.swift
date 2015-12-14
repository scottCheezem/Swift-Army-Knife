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
    case SavePicture = "savePicture"
    case Action = "takeAction"
    case InnerText = "innerText"
    case OuterHTML = "outerHtml"
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
                    let actionItem = (commandDict as NSDictionary).valueForKeyPath(currentState.rawValue + "." + currentAction.rawValue)
                    let actionScript =  actionItem as? String
                    let result = sender.windowScriptObject.evaluateWebScript(actionScript)
                    debugPrint(result)
                    self.currentState = .WhenURLMatches
                break;
            case .WhenURLMatches:
                
                let urlPatternsToActOn = commandDict[currentState.rawValue] as! [[String : AnyObject]]
                
                for item in urlPatternsToActOn {
                    if let urlRegEx = item[ActionKey.RegexURL.rawValue] as? String{
                        if (sender.mainFrameURL as NSString).rangeOfString(urlRegEx, options: .RegularExpressionSearch).length > 0 { 
                            
                            for (k,v) in item where k != ActionKey.RegexURL.rawValue {
                                let actionKey = ActionKey.init(rawValue: k)! as ActionKey
                                switch actionKey {
                                    case .SavePicture:
                                        break;
                                    case .Action:
                                        let action = v as? String //this needs to be way more exhaustive
                                        let result = sender.windowScriptObject.evaluateWebScript(action)
                                        debugPrint(result)
                                        break;
                                    case .InnerText:
                                        print(sender.mainFrame.DOMDocument.documentElement.innerText)
                                        break;
                                    case .OuterHTML:
                                        print(sender.mainFrame.DOMDocument.documentElement.outerHTML)
                                    case .Exit:
                                        CFRunLoopStop(CFRunLoopGetCurrent())
                                        exit(EXIT_SUCCESS)
                                        break;
                                    default:
                                        break;
                        
                                }
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                }
                
                
                break;
        }
        
        
        
        
        
        
        
        
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
