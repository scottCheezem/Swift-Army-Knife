import Darwin
import Foundation
import WebKit
import XCPlayground
import AutomatedWebView

// get the file path for the file "test.json" in the playground bundle
let filePath = NSBundle.mainBundle().pathForResource("dd", ofType: "json")

// get the contentData
let contentData = NSFileManager.defaultManager().contentsAtPath(filePath!)

// get the string
let fileContent = NSString(data: contentData!, encoding: NSUTF8StringEncoding) as! String


var commandDict = fileContent.jsonStringToDict() as [String:AnyObject]?
let webViewLoadDelegate = AutomatedWebView(instructionJson: commandDict!)



let webView = WebView()
webView.shouldUpdateWhileOffscreen = true
webView.frame = CGRectMake(0, 0, 1000, 2000) 

let startingUrlString = webViewLoadDelegate.setupAction?.regExUrlString
let startingUrl = NSURL(string : startingUrlString!)
let startingUrlRequest = NSURLRequest(URL: startingUrl!)


debugPrint("loading ", startingUrlString)
webView.mainFrame.loadRequest(startingUrlRequest)
webView.frameLoadDelegate = webViewLoadDelegate

webView.mainFrame.DOMDocument

XCPlaygroundPage.currentPage.liveView = webView
