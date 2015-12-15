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

enum CommandKey :String {
    case StartURL = "startUrl"
    case RegexURL = "regexUrl"
    case Actions = "actions"
}

enum ActionKey : String {
    case RunScript = "runScript"
    case SavePicture = "savePicture"
    case InnerText = "innerText"
    case OuterHTML = "outerHtml"
    case Exit = "Exit"
    case Nil = ""
}

class BrowserAction {
    var actionType : ActionKey
    var actionElement : AnyObject
    init(jsonDict : [String:String]){
        actionType = .Nil
        actionElement = 0
        for (k,v) in jsonDict{
            actionType = ActionKey.init(rawValue: k as String)!
            actionElement = v
        }
    }
    
    func runAction(webview:WebView){
        switch actionType {
            case .SavePicture:
                break;
            case .RunScript:
                webview.windowScriptObject.evaluateWebScript(actionElement as! String)
                break;
            case .InnerText:
                print(webview.mainFrame.DOMDocument.documentElement.innerText)
                break;
            case .OuterHTML:
                print(webview.mainFrame.DOMDocument.documentElement.outerHTML)
            case .Exit:
                CFRunLoopStop(CFRunLoopGetCurrent())
                exit(EXIT_SUCCESS)
                break;
            default:
                break;
                
        }
    }
    
}

class UrlAction {
    var regExUrlString : String = ""
    var actions : [[String:String]] = []
    init(jsonDict : [String:AnyObject]){
        guard let saferegExUrlString = jsonDict[CommandKey.RegexURL.rawValue] as? String else{
            return
        }
        
        regExUrlString = saferegExUrlString
        guard let safeActions = jsonDict[CommandKey.Actions.rawValue] as? [[String:String]] else{
            return
        }
        actions = safeActions
    }
}

class WebViewDelegate: NSObject,WebFrameLoadDelegate {

    
    var currentState : StateKey = .Begin
    var currentCommand : CommandKey = .Actions
    
    
    
    var commandDict:[String:AnyObject] = [:]
    
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        
        switch currentState {
            case .Begin :
                    let scriptItems = (commandDict as NSDictionary).valueForKeyPath(currentState.rawValue + "." + currentCommand.rawValue + "." + ActionKey.RunScript.rawValue) as! [String]
                    let scriptString = buildScriptString(scriptItems)
                    sender.windowScriptObject.evaluateWebScript(scriptString)
                    self.currentState = .WhenURLMatches
                break;
            case .WhenURLMatches:
                
                let urlPatternsToActOn = commandDict[currentState.rawValue] as! [[String : AnyObject]]
                
                for item in urlPatternsToActOn {
                    if let urlRegEx = item[CommandKey.RegexURL.rawValue] as? String{
                        if (sender.mainFrameURL as NSString).rangeOfString(urlRegEx, options: .RegularExpressionSearch).length > 0 {
                            //v is the Actions Array.
                            for (k,v) in item where k != CommandKey.RegexURL.rawValue {
                                let actionKey = ActionKey.init(rawValue: k)! as ActionKey
                                switch actionKey {
                                    case .SavePicture:
                                        break;
                                    case .RunScript:
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
        
        
    }
    
    func buildScriptString(array:[String]) -> String {
        var result = ""
        for scriptString in array {
            result += scriptString
        }
        return result
    }
    
}




