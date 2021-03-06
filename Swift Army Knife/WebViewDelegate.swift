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
    if let range = string.rangeOfString(regex, options:.RegularExpressionSearch){
        NSLog("matched on :%@",string.substringWithRange(range))
        return true
    }
    return false
}

public enum WError : ErrorType {
    case NoBeginNode
    case NoRegEx
    case NoActions
    case BrowserStartError
}


public enum StateKey : String {
    case Begin = "begin"
    case WhenURLMatches = "whenUrlMatches"
}

public enum CommandKey :String {
    case RegexURL = "regexUrl"
    case Actions = "actions"
}

public enum ActionKey : String {
    case RunScript = "runScript"
    case SavePicture = "savePicture"
    case SaveWebArchive = "saveWebArcive"
    case SavePdf = "savePdf"
    case Wait = "wait"
    case InnerText = "innerText"
    case OuterHTML = "outerHtml"
    case DomQueryAll = "domQueryAll"
    case DomQueryAllText = "domQueryAllText"
    case DomQuery = "domQuery"
    case DomQueryText = "domQueryText"
    case Exit = "Exit"
    case DebugPrint = "debugPrint"
    case Nil = ""
}



//a Key-Value pair representing some atomic thing that can be automated in the page.
public class BrowserAction {
    
    var actionType : ActionKey
    var actionElement : AnyObject
    init(jsonDict : [String:AnyObject]){
        actionType = .Nil
        actionElement = 0
        for (k,v) in jsonDict{
            actionType = ActionKey.init(rawValue: k as String)!
            actionElement = v
        }
    }
    
    //this could be in an extension to a protocol or something...
    func runAction(webview:WebView){
        switch actionType {
        case .SavePicture:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                webview.mainFrame.frameView.allowsScrolling = false//this might need to be set by default.
                
                let webFrameRect = webview.mainFrame.frameView.documentView.frame
                webview.frame = webFrameRect
                
                
                
                guard let imagerep = webview.bitmapImageRepForCachingDisplayInRect(webview.frame) else{
                    return
                }
                webview.cacheDisplayInRect(webview.frame, toBitmapImageRep: imagerep)
                
                //            let imageOfWebView = NSImage(size: webview.frame.size)
                //            imageOfWebView.addRepresentation(imagerep!)
                let imageData = imagerep.representationUsingType(.NSPNGFileType, properties: [:])
                
                
                do {
                    try imageData?.writeToFile(self.actionElement as! String, options: .AtomicWrite)
                }catch let e as NSError{
                    NSLog("%@",e)
                }

            })
            
            break;
        case .RunScript:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let result = webview.stringByEvaluatingJavaScriptFromString(self.actionElement as! String)
                if result.characters.count > 0 {
//                    debugPrint(result)
                    print(result)
                }

            })
            break;
        case .InnerText:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print(webview.mainFrame.DOMDocument.documentElement.innerText)
            });
            break;
        case .OuterHTML:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print(webview.mainFrame.DOMDocument.documentElement.outerHTML)
            })
        case .Exit:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                CFRunLoopStop(CFRunLoopGetCurrent())
                exit(EXIT_SUCCESS)
            });
            break;
        case .Wait:
            //this no longer seems needed, but would be nice to have in case this is ever a legit testing enginge.
            let delay:dispatch_time_t = UInt64(actionElement as! Int)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                NSLog("done waiting");
            })
        case .DomQueryAll:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let domNodes = webview.mainFrame.DOMDocument.querySelectorAll(self.actionElement as! String)
                for  index in 0...domNodes.length-1{
                    let domElement = domNodes.item(index) as! DOMElement
                    print(domElement.innerHTML)
                }
            })
            break;
        case .DomQuery:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let domElement = webview.mainFrame.DOMDocument.querySelector(self.actionElement as! String)
                print(domElement.innerHTML)
            })
            break
        case .DomQueryAllText:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let domNodes = webview.mainFrame.DOMDocument.querySelectorAll(self.actionElement as! String)
                for  index in 0...domNodes.length{
                    guard let domElement = domNodes.item(index) as? DOMElement else{
                        continue
                    }
                    print(domElement.innerText)
                }
            })
            break;
        case .DomQueryText:
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let domElement = webview.mainFrame.DOMDocument.querySelector(self.actionElement as! String)
                print(domElement.innerText)
            })
            break

        default:
            break;
            
        }
    }
    
}


// A UrlAction is a regular expression to match on page load, and some actions to take
public class UrlAction {
    public var regExUrlString : String = ""
    public var actions : [BrowserAction] = []
    public init(jsonDict : [String:AnyObject]){
        guard let saferegExUrlString = jsonDict[CommandKey.RegexURL.rawValue] as? String else{
            return
        }
        
        regExUrlString = saferegExUrlString
        guard let safeActions = jsonDict[CommandKey.Actions.rawValue] as? [[String:AnyObject]] else{
            NSLog("couldn't parse: %@", jsonDict)
            return
        }
        for jsonDict in safeActions{
            actions.append(BrowserAction.init(jsonDict: jsonDict))
        }
    }
}

public class AutomatedWebView: NSObject,WebFrameLoadDelegate {

    public var currentStep : StateKey = StateKey.Begin
    public var setupAction : UrlAction?
    public var mainAction : [UrlAction]? = []
    
    public init(instructionJson: [String:AnyObject]) {
        super.init()
        do {
            try setupWithInput(instructionJson)
        }catch let e as NSError{
            NSLog("%@", e)
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
    
    public func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        NSLog("loaded webview with URL:%@", sender.mainFrameURL)
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




