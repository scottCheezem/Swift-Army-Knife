//
//  WebViewDelegate.swift
//  webThumb
//
//  Created by Scott Cheezem on 12/11/15.
//  Copyright © 2015 Scott Cheezem. All rights reserved.
//


import Foundation
import WebKit

infix operator =~ {}
func =~(string:String, regex:String) -> Bool {
    if let range = string.rangeOfString(regex, options:.RegularExpressionSearch){
        debugPrint("matched on :",string.substringWithRange(range))
        return true
    }
    return false
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
    case Wait = "wait"
    case DomQueryAll = "domQueryAll"
    case DomQuery = "domQuery"
    case DebugPrint = "debugPrint"
    case Nil = ""
    //it would be great to have a query selector here.
}


//a Key-Value pair representing some atomic thing that can be automated in the page.
public class BrowserAction {
    var actionType : ActionKey
    var actionElement : AnyObject
    init(jsonDict : [String:AnyObject]){
        actionType = .Nil
        actionElement = 0
        for (k,v) in jsonDict{
//            debugPrint("Building action with ", k, ":", v)
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
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let result = webview.stringByEvaluatingJavaScriptFromString(self.actionElement as! String)
                    debugPrint(result)
                })
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
            case .Wait:
                //this no longer seems needed, but would be nice to have in case this is ever a legit testing enginge.
                let delay:dispatch_time_t = UInt64(actionElement as! Int)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                    debugPrint("I waited for ", self.actionElement);
                })
            case .DomQueryAll:
                let domNodes = webview.mainFrame.DOMDocument.querySelectorAll(actionElement as! String)
                for  index in 0...domNodes.length-1{
//                    print(domNodes.item(index).textContent)
                    let domElement = domNodes.item(index) as! DOMElement
                    print(domElement.innerHTML)
                }
                break;
            case .DomQuery:
                let domElement = webview.mainFrame.DOMDocument.querySelector(actionElement as! String)
                    print(domElement.innerHTML)
                break
            default:
                break;
                
        }
    }
    
}


// A UrlAction is a regular expression to match on page load, and some actions to take
public class UrlAction {
    public var regExUrlString : String = ""
    var actions : [BrowserAction] = []
    init(jsonDict : [String:AnyObject]){
        guard let saferegExUrlString = jsonDict[CommandKey.RegexURL.rawValue] as? String else{
            return
        }
        
        regExUrlString = saferegExUrlString
        guard let safeActions = jsonDict[CommandKey.Actions.rawValue] as? [[String:AnyObject]] else{
            debugPrint("couldn't parse", jsonDict)
            return
        }
        for jsonDict in safeActions{
            actions.append(BrowserAction.init(jsonDict: jsonDict))
        }
    }
}

public class AutomatedWebView: NSObject,WebFrameLoadDelegate {

    var currentStep : StateKey = StateKey.Begin
   public var setupAction : UrlAction?
    public var mainAction : [UrlAction]? = []

    
    public init(instructionJson: [String:AnyObject]) {
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
            debugPrint("couldn't find the Begin key")
            throw WError.NoBeginNode
        }
        
        setupAction = UrlAction(jsonDict: safeBeginDict)
        
        guard let safeMainLoopDict = instructionJson[StateKey.WhenURLMatches.rawValue] as? [[String:AnyObject]] else {
            debugPrint("Couldn't find the whenUrlMatches key")
            throw WError.NoRegEx
        }
        
        for urlActionDict in safeMainLoopDict{
//            debugPrint("Building URLAction with :",urlActionDict)
            mainAction?.append(UrlAction(jsonDict: urlActionDict))
        }

    }
    
    
    public func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {

        debugPrint("loaded:", sender.mainFrameURL)
//        debugPrint("but then theres this ", frame.dataSource?.initialRequest.URL?.absoluteString)
//        debugPrint("but then theres also this ", frame.dataSource?.request.URL?.absoluteString)
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




