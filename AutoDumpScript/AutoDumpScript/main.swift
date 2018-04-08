//
//  main.swift
//  AutoDumpScript
//
//  Created by 河野穣 on 2016/07/21.
//  Copyright © 2016年 河野穣. All rights reserved.
//

import Foundation


var flag = 0

let urlStringEndpoint:String  = "https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:Train"
let urlStringRailway:String = "odpt.Railway:TokyoMetro.Ginza"
let urlStringDirection:String = "odpt.RailDirection:TokyoMetro.Asakusa"
var result:String = ""

// make the request URL
let urlstringrailway = "odpt:railway=" + urlStringRailway
let urlstringdirection = "odpt:railDirection=" + urlStringDirection
let urlStringConsumerKey:String = "CONSUMER_KEY"

let urlString = urlStringEndpoint + "&" + urlstringdirection + "&" + urlstringrailway + "&" + urlStringConsumerKey
//print(urlString)
let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
// set the method(HTTP-GET)
request.HTTPMethod = "GET"
// use NSURLSessionDataTask
let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { request, response, error in
    result = String(data: request!, encoding: NSUTF8StringEncoding)!
//    print(result)
    let resultData = result.dataUsingEncoding(NSUTF8StringEncoding)
    
    flag = 1 //completed loading data
})
task.resume()

//idling while loading data
repeat{
}while flag == 0
flag = 0

let now = NSDate()

let formatter = NSDateFormatter()
formatter.dateFormat = "MMddHHmm"

let timeStmpStr = formatter.stringFromDate(now)

if let _ : NSString = NSSearchPathForDirectoriesInDomains( NSSearchPathDirectory.DesktopDirectory, NSSearchPathDomainMask.AllDomainsMask, true ).first {
    
    
    let file_name = ("ginzaWeekday"+timeStmpStr+".json")
    do {
        try result.writeToFile( "/Users/ev30112/Desktop/rawDataStore/\(file_name)", atomically: false, encoding: NSUTF8StringEncoding )
        
    } catch {
        print("file error")
    }
}
       
