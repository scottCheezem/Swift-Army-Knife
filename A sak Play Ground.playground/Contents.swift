import Darwin
import Foundation
import WebKit
//import XCPlayground
import PlaygroundSupport
import AutomatedWebView


PlaygroundPage.current.needsIndefiniteExecution = true
// get the file path for the file "test.json" in the playground bundle
//let filePath = Bundle.mainBundle().pathForResource("getTheFlinstones", ofType: "json")

if let filePath = Bundle.main.path(forResource: "getTheFlinstones", ofType: "json") {

// get the contentData
//let contentData = NSFileManager.defaultManager().contentsAtPath(filePath!)

    if let contentData = FileManager.default.contents(atPath: filePath),
        let contentDataString = String(data: contentData, encoding: .utf8),
        let commandDict = contentDataString.jsonStringToDict(){
            let webViewLoadDelegate = AutomatedWebView(instructionJson: commandDict)
            let webView = WebView()
            webView.frame = CGRect(x: 0, y: 0, width: 1000, height: 2000)
            let startingUrlString = webViewLoadDelegate.setupAction!.regExUrlString
            print(startingUrlString)
            let startingUrl = URL(string:startingUrlString)
            let startingUrlRequest = URLRequest(url: startingUrl!)
            webView.shouldUpdateWhileOffscreen = false
            webView.frameLoadDelegate = webViewLoadDelegate
        
        
        
//            vc.view.addSubview(webView)
            webView.mainFrame.load(startingUrlRequest)
        PlaygroundPage.current.liveView = webView
        
    }
    

//// get the string
//let fileContent = NSString(data: contentData!, encoding: NSUTF8StringEncoding) as! String
//
//
//var commandDict = fileContent.jsonStringToDict() as [String:AnyObject]?
//let webViewLoadDelegate = AutomatedWebView(instructionJson: commandDict!)
//
//
//
//let webView = WebView()
//webView.shouldUpdateWhileOffscreen = true
//
//let startingUrlString = webViewLoadDelegate.setupAction?.regExUrlString
//let startingUrl = NSURL(string : startingUrlString!)
//let startingUrlRequest = NSURLRequest(URL: startingUrl!)
//
//debugPrint("loading ", startingUrlString)
//webView.mainFrame.loadRequest(startingUrlRequest)
//webView.frameLoadDelegate = webViewLoadDelegate

    

}
