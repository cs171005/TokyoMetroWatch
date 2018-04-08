//
//  LineInfo.swift
//  TokyoMetroWatch
//
//  Created by 河野穣 on 2016/05/31.
//  Copyright © 2016年 河野穣. All rights reserved.
//

import Cocoa
import Foundation

class LineInfo{
    
    var urlStringRailway:String
    var urlStringDirection:String
    let urlStringConsumerKey:String = "CONSUMER_KEY"
    
    var flag:Int = 0
    var flag2:Int = 0
    var traininfo:[TrainInfo]=[]
    var StationName:[Int:String] = [:]
    var TrainnumberList:[String] = []
    var StateArray:[CellState] = []
    var StateHistory:[[CellState]] = []
    var dataReceiveTime:String = ""
    
    var NecessaryTime:[(fromStation:String,toStation:String,necesarryTime:Int)] = []
    //var numOfCellPerMinute:Int = 2
    
    init(urlStringRailway:String = "odpt.Railway:TokyoMetro.Ginza",urlStringDirection:String = "odpt.RailDirection:TokyoMetro.Asakusa"){
        //for the debbuging mode
        srand(100)
        
        let urlStringEndpoint:String  = "https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:Train"
        self.urlStringRailway = urlStringRailway
        self.urlStringDirection = urlStringDirection
        
        var result:String = ""
        
        // make the request URL
        let urlstringrailway = "odpt:railway=" + urlStringRailway
        let urlstringdirection = "odpt:railDirection=" + urlStringDirection
        let urlString = urlStringEndpoint + "&" + urlstringdirection + "&" + urlstringrailway + "&" + urlStringConsumerKey
        print(urlString)
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        // set the method(HTTP-GET)
        request.HTTPMethod = "GET"
        // use NSURLSessionDataTask
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { request, response, error in
            result = String(data: request!, encoding: NSUTF8StringEncoding)!
            let resultData = result.dataUsingEncoding(NSUTF8StringEncoding)
            
            var jsonArray:NSArray
            do{
                jsonArray = try NSJSONSerialization.JSONObjectWithData(resultData!, options: NSJSONReadingOptions.AllowFragments) as! NSArray
                //print(jsonArray)
                for jsondata in jsonArray {
                    let trainNumber = (jsondata["odpt:trainNumber"]as? String)!
                    let trainType = jsondata["odpt:trainType"]as? String!
                    let railway = jsondata["odpt:railway"]as? String!
                    let terminalStation = jsondata["odpt:terminalStation"]as? String!
                    let fromStation = jsondata["odpt:fromStation"]as? String!
                    let toStation = jsondata["odpt:toStation"]as? String!
                    let delay = jsondata["odpt:delay"]as! Int!
                
                    let train = TrainInfo(trainNumber: trainNumber, railway: railway, trainType: trainType, terminalStation: terminalStation, fromStation: fromStation, toStation: toStation,delay:delay)
                    self.traininfo.append(train)
                    self.TrainnumberList.append((jsondata["odpt:trainNumber"]as? String)!)
                    
                    self.dataReceiveTime = jsondata["dc:date"]as! String!
                }
                
            }catch{
                print("parse error")
            }
            self.flag = 1 //completed loading data
        })
        task.resume()
        
        //idling while loading data
        repeat{
        }while self.flag == 0
        self.flag = 0
        
        print(self.TrainnumberList)
        
        setStationName()
        //convertLineStateToCellStructure()
        
        self.flag2 = 0
        let urlStringEndpoint2:String  = "https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:Railway"
        var result2:String = ""
        
        // make the request URL
        let urlString2 = urlStringEndpoint2 + "&" + "owl:sameAs=" + urlStringRailway + "&" + urlStringConsumerKey
        //print(urlString)
        let request2 = NSMutableURLRequest(URL: NSURL(string: urlString2)!)
        // set the method(HTTP-GET)
        request2.HTTPMethod = "GET"
        // use NSURLSessionDataTask
        let task2 = NSURLSession.sharedSession().dataTaskWithRequest(request2, completionHandler: { request2, response, error in
            result2 = String(data: request2!, encoding: NSUTF8StringEncoding)!
            let resultData2 = result2.dataUsingEncoding(NSUTF8StringEncoding)
            
            
            var jsonArray2:NSArray
            do{
                jsonArray2 = try NSJSONSerialization.JSONObjectWithData(resultData2!, options: NSJSONReadingOptions.AllowFragments) as! NSArray
                let takenTraveltimeData:NSArray = jsonArray2.valueForKey("odpt:travelTime") as! NSArray
                //print(takenTraveltimeData)
                for between in takenTraveltimeData {
                    for i in 0 ..< between.count{
                        if between[i].valueForKey("odpt:trainType") as! String == "odpt.TrainType:Local" {
                            //                            print(between[i].valueForKey("odpt:fromStation") as! String)
                            //                            print(between[i].valueForKey("odpt:toStation") as! String)
                            //                            print(between[i].valueForKey("odpt:necessaryTime") as! Int)
                            
                            self.NecessaryTime.append((fromStation:between[i].valueForKey("odpt:fromStation") as! String, toStation:between[i].valueForKey("odpt:toStation") as! String, necesarryTime:between[i].valueForKey("odpt:necessaryTime") as! Int))
                            
                        }
                        
                    }
                    
                }
            }catch{
                print("parse error")
            }
            self.flag2 = 1 //completed loading data
        })
        task2.resume()
        
        //idling while loading data
        repeat{
        }while self.flag2 == 0
        self.flag2 = 0
    }
    
    init(fixedUrl:String,urlStringRailway:String = "odpt.Railway:TokyoMetro.Ginza",urlStringDirection:String = "odpt.RailDirection:TokyoMetro.Asakusa"){
        
        //for the debbuging mode
        srand(100)
        
        self.urlStringRailway = urlStringRailway
        self.urlStringDirection = urlStringDirection
    
        var result:String = ""
        // make the request URL
        let urlString = fixedUrl
        //print(urlString)
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        // set the method(HTTP-GET)
        request.HTTPMethod = "GET"
        // use NSURLSessionDataTask
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { request, response, error in
            result = String(data: request!, encoding: NSUTF8StringEncoding)!
            let resultData = result.dataUsingEncoding(NSUTF8StringEncoding)
            
            var jsonArray:NSArray
            do{
                jsonArray = try NSJSONSerialization.JSONObjectWithData(resultData!, options: NSJSONReadingOptions.AllowFragments) as! NSArray
                //print(jsonArray)
                for jsondata in jsonArray {
                    let trainNumber = (jsondata["odpt:trainNumber"]as? String)!
                    let trainType = jsondata["odpt:trainType"]as? String!
                    let railway = jsondata["odpt:railway"]as? String!
                    let terminalStation = jsondata["odpt:terminalStation"]as? String!
                    let fromStation = jsondata["odpt:fromStation"]as? String!
                    let toStation = jsondata["odpt:toStation"]as? String!
                    let delay = jsondata["odpt:delay"]as! Int!
                    
                    let train = TrainInfo(trainNumber: trainNumber, railway: railway, trainType: trainType, terminalStation: terminalStation, fromStation: fromStation, toStation: toStation,delay:delay)
                    self.traininfo.append(train)
                    self.TrainnumberList.append((jsondata["odpt:trainNumber"]as? String)!)
                    
                    self.dataReceiveTime = jsondata["dc:date"]as! String!
                }
                
            }catch{
                print("Train info session parse error")
            }
            self.flag = 1 //completed loading data
        })
        task.resume()
        
        //idling while loading data
        repeat{
        }while self.flag == 0
        self.flag = 0
        
        print(self.TrainnumberList)
        
        setStationName()
        //convertLineStateToCellStructure()
        
        self.flag2 = 0
        //let urlStringEndpoint2:String  = "https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:Railway"
        var result2:String = ""
        
        // make the request URL
        //let urlString2 = urlStringEndpoint2 + "&" + "owl:sameAs=" + urlStringRailway + "&" + urlStringConsumerKey
        //print(urlString2)
        let request2 = NSMutableURLRequest(URL: NSURL(string: "http://localhost/hoge/stationindex.json")!)
        // set the method(HTTP-GET)
        request2.HTTPMethod = "GET"
        // use NSURLSessionDataTask
        let task2 = NSURLSession.sharedSession().dataTaskWithRequest(request2, completionHandler: { request2, response, error in
            result2 = String(data: request2!, encoding: NSUTF8StringEncoding)!
            let resultData2 = result2.dataUsingEncoding(NSUTF8StringEncoding)
            //print(resultData2)
            
            var jsonArray2:NSArray
            do{
                jsonArray2 = try NSJSONSerialization.JSONObjectWithData(resultData2!, options: NSJSONReadingOptions.AllowFragments) as! NSArray
                let takenTraveltimeData:NSArray = jsonArray2.valueForKey("odpt:travelTime") as! NSArray
                //print(takenTraveltimeData)
                for between in takenTraveltimeData {
                    for i in 0 ..< between.count{
                        if between[i].valueForKey("odpt:trainType") as! String == "odpt.TrainType:Local" {
//                            print(between[i].valueForKey("odpt:fromStation") as! String)
//                            print(between[i].valueForKey("odpt:toStation") as! String)
//                            print(between[i].valueForKey("odpt:necessaryTime") as! Int)
                            
                            self.NecessaryTime.append((fromStation:between[i].valueForKey("odpt:fromStation") as! String, toStation:between[i].valueForKey("odpt:toStation") as! String, necesarryTime:between[i].valueForKey("odpt:necessaryTime") as! Int))
                            
                        }
                        
                    }
                    
                }
            }catch{
                print("inter-station necessary time parse error")
            }
            self.flag2 = 1 //completed loading data
        })
        task2.resume()
        
        //idling while loading data
        repeat{
        }while self.flag2 == 0
        self.flag2 = 0
    }
    
    func printLineState(){
        print("===========================")
        for i in 0 ..< self.traininfo.count{
            print("[\(i+1)]")
            print(self.traininfo[i].trainNumber!)
            print(self.traininfo[i].railway!)
            print(self.traininfo[i].trainType!)
            print(self.traininfo[i].terminalStation!)
            print(self.traininfo[i].delay) //should be wrapped
            print("---------------------------")
            print(self.traininfo[i].fromStation!)
            print(self.traininfo[i].toStation) //should be wrapped
            print("===========================")
            
            
        }
    }
    
    func convertLineStateToCellStructure(numOfCellPerMinute:Int){
        //generate an array that represents the line state
        self.StateArray = setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
        // add trainInfo to StateArray
        var toStationNum:Int?,fromStationNum:Int?
        for i in 0..<self.traininfo.count{
            //Confirmation of the departure station
            if self.traininfo[i].fromStation != nil {
                //fromStation is not nil
                for j in 0..<self.StateArray.count{
                    if self.traininfo[i].fromStation == self.StateArray[j].StationName {
                        fromStationNum = j
                        break
                    }
                }
            }
            
            //Confirmation of the arraival station
            if self.traininfo[i].toStation != nil {
                for j in 0..<self.StateArray.count{
                    if self.traininfo[i].toStation == self.StateArray[j].StationName {
                        toStationNum = j
                        break
                    }
                }
            }else{
                //toStation is nil
                toStationNum = nil
            }
            
            //place the information of each train in StateArray
            if toStationNum == nil{
                //If stopping at the station, the train is in the i th CellState[].
                self.StateArray[fromStationNum!].CellState = 1
                self.StateArray[fromStationNum!].TrainNumber = self.traininfo[i].trainNumber
                self.StateArray[fromStationNum!].TrainType = self.traininfo[i].trainType
            }else{
                //If traveling between stations, the train is in CellState[], which represents the inter-station.
                var j = 1
                while(self.StateArray[fromStationNum!+j].CellState == 1){
                    j += 1
                }
                self.StateArray[fromStationNum!+j].CellState = 1
                self.StateArray[fromStationNum!+j].TrainNumber = self.traininfo[i].trainNumber
                self.StateArray[fromStationNum!+j].TrainType = self.traininfo[i].trainType
            }
        }
        
        //        for i in self.StateArray.startIndex ..< self.StateArray.endIndex{
        //            print(StateArray[i])
        //        }
        StateHistory.append(StateArray)
    }
    
    func setNilLineCellState()->[CellState]{
        var generatedCellState:[CellState] = []
        //appned 0 to make StateArray an empty array
        for i in 0..<self.StationName.count{
            //insert a cell that represents a station
            let newCell:CellState = CellState.init(CellState: 0, StationName:StationName[i])
            generatedCellState.append(newCell)
            //insert a cell that represents the inter-station
            //represented among all stations in a single cell
            let newCellnil:CellState = CellState.init(CellState: 0, StationName:nil)
            generatedCellState.append(newCellnil)
        }
        generatedCellState.removeLast()
        
        return generatedCellState
    }
    
    func setNilLineCellStateWithNecessaryTime(numOfCellPerMinute:Int)->[CellState]{
        var generatedCellState:[CellState] = []
        
        //appned 0 to make StateArray an empty array
        for i in 0..<self.StationName.count{
            //insert a cell that represents a station
            let newCell:CellState = CellState.init(CellState: 0, StationName:StationName[i])
            generatedCellState.append(newCell)
            //insert a cell that represents the inter-station represented between each station in accordance with the required time
            let newCellnil:CellState = CellState.init(CellState: 0, StationName:nil)
            if NecessaryTime[i].fromStation == StationName[i]{
                for _ in 0 ..< NecessaryTime[i].necesarryTime {
                    for _ in 0..<numOfCellPerMinute{
                        generatedCellState.append(newCellnil)
                    }
                }
            }
        }
        
        for _ in 0..<NecessaryTime[self.StationName.count-1].necesarryTime{
            for _ in 0..<numOfCellPerMinute{
                generatedCellState.removeLast()
            }
        }
        
        //        for i in 0..<generatedCellState.count{
        //            print(generatedCellState[i])
        //        }
        
        return generatedCellState
    }
    
    private func setStationName(){
        self.flag = 0
        //get the list of station name and make a dictionary [station number:station name]
        
        let urlStringEndpoint:String  = "https://api.tokyometroapp.jp/api/v2/datapoints?rdf:type=odpt:Railway"
        var result:String = ""
        
        // make the request URL
        let urlString = urlStringEndpoint + "&" + "owl:sameAs=" + urlStringRailway + "&" + urlStringConsumerKey
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        // set the method(HTTP-GET)
        request.HTTPMethod = "GET"
        // use NSURLSessionDataTask
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { request, response, error in
            result = String(data: request!, encoding: NSUTF8StringEncoding)!
            let resultData = result.dataUsingEncoding(NSUTF8StringEncoding)
            var jsonArray:NSArray
            do{
                jsonArray = try NSJSONSerialization.JSONObjectWithData(resultData!, options: NSJSONReadingOptions.AllowFragments) as! NSArray
                let takenStationData:NSArray = jsonArray.valueForKey("odpt:stationOrder") as! NSArray
                
                for station in takenStationData {
                    //print(station.count)
                    for i in 0..<station.count{
                        self.StationName[(station[i].valueForKey("odpt:index")?.integerValue)!] = (station[i].valueForKey("odpt:station")?.description)!
                    }
                    
                }
                
                
                
            }catch{
                print("set station name parse error")
            }
            self.flag = 1 //completed loading data
        })
        task.resume()
        
        //idling while loading data
        repeat{
        }while self.flag == 0
        self.flag = 0
    }
}

struct TrainInfo {
    var trainNumber:String?
    var railway:String?
    var trainType:String?
    var terminalStation:String?
    var fromStation:String?
    var toStation:String?
    var delay:Int
    
    
    init(trainNumber:String?,railway:String?,trainType:String?,terminalStation:String?,fromStation:String?,toStation:String?,delay:Int){
        self.trainNumber = trainNumber
        self.railway = railway
        self.trainType = trainType
        self.terminalStation = terminalStation
        self.fromStation = fromStation
        self.toStation = toStation
        self.delay = delay
        
    }
    
}

struct CellState {
    var CellState:Int
    var TrainNumber:String?
    var TrainType:String?
    var StationName:String?
    
    init(CellState:Int,StationName:String?,TrainNumber:String? = nil,TrainType:String? = nil){
        self.CellState = CellState
        self.StationName = StationName
    }
}


