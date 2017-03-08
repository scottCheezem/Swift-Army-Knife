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

infix operator =~
func =~(string:String, regex:String) -> Bool {
    if let range = string.range(of: regex, options:.regularExpression){
        NSLog("matched on :%@",string.substring(with: range))
        return true
    }
    return false
}

public enum WError : Error {
    case noBeginNode
    case noRegEx
    case noActions
    case browserStartError
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
open class BrowserAction {
    
    var actionType : ActionKey
    var actionElement : AnyObject
    init(jsonDict : [String:AnyObject]){
        actionType = .Nil
        actionElement = 0 as AnyObject
        for (k,v) in jsonDict{
            actionType = ActionKey.init(rawValue: k as String)!
            actionElement = v
        }
    }
    
    //this could be in an extension to a protocol or something...
    func runAction(_ webview:WebView){
        switch actionType {
        case .SavePicture:
            DispatchQueue.main.async(execute: { () -> Void in
                
                webview.mainFrame.frameView.allowsScrolling = false//this might need to be set by default.
                
                let webFrameRect = webview.mainFrame.frameView.documentView.frame
                webview.frame = webFrameRect
                
                
                
                guard let imagerep = webview.bitmapImageRepForCachingDisplay(in: webview.frame) else{
                    return
                }
                webview.cacheDisplay(in: webview.frame, to: imagerep)
                
                //            let imageOfWebView = NSImage(size: webview.frame.size)
                //            imageOfWebView.addRepresentation(imagerep!)
                let imageData = imagerep.representation(using: .PNG, properties: [:])
                
                
                do {
                    try imageData?.write(to: URL(fileURLWithPath: self.actionElement as! String), options: .atomicWrite)
                }catch let e as NSError{
                    NSLog("%@",e)
                }

            })
            
            break;
        case .RunScript:
            DispatchQueue.main.async(execute: { () -> Void in
                if let result = webview.stringByEvaluatingJavaScript(from: self.actionElement as! String), result.characters.count > 0 {
                    print(result)
                }

            })
            break;
        case .InnerText:
            DispatchQueue.main.async(execute: { () -> Void in
                print(webview.mainFrame.domDocument.documentElement.innerText)
            });
            break;
        case .OuterHTML:
            DispatchQueue.main.async(execute: { () -> Void in
                print(webview.mainFrame.domDocument.documentElement.outerHTML)
            })
        case .Exit:
            DispatchQueue.main.async(execute: { () -> Void in
                CFRunLoopStop(CFRunLoopGetCurrent())
                exit(EXIT_SUCCESS)
            });
            break;
        case .Wait:
            //this no longer seems needed, but would be nice to have in case this is ever a legit testing enginge.
//            let delay:DispatchTime = UInt64(actionElement as! Int)
            let delayCount = NSNumber(value: actionElement as! Int).uint32Value// * NSEC_PER_SEC
//                Int(actionElement as! NSNumber)
            debugPrint(delayCount)
            
            
            sleep(delayCount)
            
            
//            DispatchTime(uptimeNanoseconds: delayCount)
//            let delay = DispatchTime.now() + Double((Int64)(delayCount * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
//            DispatchQueue.main.asyncAfter(deadline: delay, execute: { 
            NSLog("done waiting")                
//            })
        case .DomQueryAll:
            DispatchQueue.main.async(execute: { () -> Void in
                let domNodes = webview.mainFrame.domDocument.querySelectorAll(self.actionElement as! String)
                for  index in 0...(domNodes?.length)!-1{
                    let domElement = domNodes?.item(index) as! DOMElement
                    print(domElement.innerHTML)
                }
            })
            break;
        case .DomQuery:
            DispatchQueue.main.async(execute: { () -> Void in
                if let domElement = webview.mainFrame.domDocument.querySelector(self.actionElement as! String){
                    print(domElement.innerHTML)
                }
            })
            break
        case .DomQueryAllText:
            DispatchQueue.main.async(execute: { () -> Void in
//                let domeNodes = webview.mainFrame.domDocument.querySelectorAll(self.actionElement as! String)
                if let domNodes = webview.mainFrame.domDocument.querySelectorAll(self.actionElement as! String){
                    for  index in 0...domNodes.length{
                        guard let domElement = domNodes.item(index) as? DOMElement else{
                            continue
                        }
                        print(domElement.innerText)
                    }
                }
            })
            
            break;
        case .DomQueryText:
            DispatchQueue.main.async(execute: { () -> Void in
                if let domElement = webview.mainFrame.domDocument.querySelector(self.actionElement as! String){
                    print(domElement.innerText)
                }
            })
            break

        default:
            break;
            
        }
    }
    
}


// A UrlAction is a regular expression to match on page load, and some actions to take
open class UrlAction {
    open var regExUrlString : String = ""
    open var actions : [BrowserAction] = []
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

open class AutomatedWebView: NSObject,WebFrameLoadDelegate {

    open var currentStep : StateKey = StateKey.Begin
    open var setupAction : UrlAction?
    open var mainAction : [UrlAction]? = []
    
    public init(instructionJson: [String:AnyObject]) {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(progressFinished), name:.WebViewProgressFinished , object: nil)
        
        do {
            try setupWithInput(instructionJson)
        }catch let e as NSError{
            NSLog("%@", e)
        }
    }
    
    func progressFinished(_ sender:NSNotification){
        if let webView = sender.object as? WebView{
            let url = webView.mainFrameURL
            debugPrint(url)
            let progress = webView.estimatedProgress
            NSLog("%d", progress)
        }
    }
    
    
    
    func setupWithInput(_ instructionJson: [String:AnyObject]) throws {
        guard let safeBeginDict = instructionJson[StateKey.Begin.rawValue] as? [String:AnyObject] else{
            throw WError.noBeginNode
        }
        
        setupAction = UrlAction(jsonDict: safeBeginDict)
        
        guard let safeMainLoopDict = instructionJson[StateKey.WhenURLMatches.rawValue] as? [[String:AnyObject]] else {
            throw WError.noRegEx
        }
        
        for urlActionDict in safeMainLoopDict{
            mainAction?.append(UrlAction(jsonDict: urlActionDict))
        }
    }
    
    open func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        NSLog("loaded webview with URL:%@", sender.mainFrameURL)
        if currentStep == StateKey.Begin{
            for browserAction in (setupAction?.actions)!{
                browserAction.runAction(sender)
            }
            currentStep = StateKey.WhenURLMatches
        }else if currentStep == StateKey.WhenURLMatches{
            if let mainActions = mainAction {
                for urlAction in mainActions where sender.mainFrameURL =~ urlAction.regExUrlString {
                    for browserAction in urlAction.actions {
                        browserAction.runAction(sender)
                    }
                }            
            }
        }
    }
    
    
}




