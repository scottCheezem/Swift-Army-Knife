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

infix operator =~ {}
func =~(string:String, regex:String) -> Bool {
    return string.rangeOfString(regex, options:.RegularExpressionSearch) != nil
}

enum WError : ErrorType {
    case NoBeginNode
    case NoRegEx
    case NoActions
    case BrowserStartError
}


enum StateKey : String {
    case Begin = "begin"
    case WhenURLMatches = "whenUrlMatches"
}

enum CommandKey :String {
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
    //it would be great to have a query selector here.
}



//a Key-Value pair representing some atomic thing that can be automated in the page.
class BrowserAction {
    var actionType : ActionKey
    var actionElement : AnyObject
    init(jsonDict : [String:AnyObject]){
        actionType = .Nil
        actionElement = 0
        for (k,v) in jsonDict{
            debugPrint("Building action with ", k, ":", v)
            actionType = ActionKey.init(rawValue: k as String)!
            actionElement = v
        }
    }
    //this could be in an extension to a protocol or something...
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


// A UrlAction is a regular expression to match on page load, and some actions to take
class UrlAction {
    var regExUrlString : String = ""
    var actions : [BrowserAction] = []
    init(jsonDict : [String:AnyObject]){
        guard let saferegExUrlString = jsonDict[CommandKey.RegexURL.rawValue] as? String else{
            return
        }
        
        regExUrlString = saferegExUrlString
        guard let safeActions = jsonDict[CommandKey.Actions.rawValue] as? [[String:AnyObject]] else{
            return
        }
        for jsonDict in safeActions{
            actions.append(BrowserAction.init(jsonDict: jsonDict))
        }
    }
}

class AutomatedWebView: NSObject,WebFrameLoadDelegate {



    var currentStep : StateKey = StateKey.Begin
    var setupAction : UrlAction?
    var mainAction : [UrlAction]? = []

    
    init(instructionJson: [String:AnyObject]) {
        debugPrint("initing Automated Webview")
        super.init()
        do {
            try setupWithInput(instructionJson)
        }catch let e as NSError{
            debugPrint(e)
        }

    }
    
    func setupWithInput(instructionJson: [String:AnyObject]) throws {
        guard let safeBeginDict = instructionJson[StateKey.Begin.rawValue] as? [String:AnyObject] else{
            throw WError.NoBeginNode
        }
        
        setupAction = UrlAction(jsonDict: safeBeginDict)
        
        guard let safeMainLoopDict = instructionJson[StateKey.WhenURLMatches.rawValue] as? [[String:AnyObject]] else {
            throw WError.NoRegEx
        }
        
        for urlActionDict in safeMainLoopDict{
            mainAction?.append(UrlAction(jsonDict: urlActionDict))
        }

    }
    
    
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        debugPrint("loaded webview with URL:", sender.mainFrameURL)
        debugPrint(currentStep)
        if currentStep == StateKey.Begin{
            for browserAction in (setupAction?.actions)!{
                browserAction.runAction(sender)
            }
            currentStep = StateKey.WhenURLMatches
        }else if currentStep == StateKey.WhenURLMatches{
            for urlAction in mainAction! where sender.mainFrameURL =~ urlAction.regExUrlString {
                for browserAction in urlAction.actions {
                    browserAction.runAction(sender)
                }
            }
            
            
        }
    }
    
    
}




