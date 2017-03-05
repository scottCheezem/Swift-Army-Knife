import Darwin
import Foundation
import WebKit
import PlaygroundSupport
import AutomatedWebView

//XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
PlaygroundPage.current.needsIndefiniteExecution = true
// get the file path for the file "test.json" in the playground bundle

if let filePath = Bundle.main.path(forResource: "getTheFlinstones", ofType: "json") {

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
            webView.shouldUpdateWhileOffscreen = true
            webView.frameLoadDelegate = webViewLoadDelegate

            webView.mainFrame.load(startingUrlRequest)
        
            PlaygroundPage.current.liveView = webView
        
        
    }
    

}
