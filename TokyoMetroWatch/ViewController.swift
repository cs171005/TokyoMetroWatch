//
//  ViewController.swift
//  TokyoMetroWatch
//
//  Created by 河野穣 on 2015/11/12.
//  Copyright (c) 2015年 河野穣. All rights reserved.
//

import Cocoa
import Foundation

class CommonConst {
    class var probLowerThreshold: Double {
        return 0.9
    }
    
    class var probSpilitInterval: Double {
        return 0.005
    }
    
    class var propProbParam: Double {
        return 0.8
    }
}

class ViewController: NSViewController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let now = NSDate()
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        
        let timeStmpStr = formatter.stringFromDate(now)
        
        print(timeStmpStr)

        let testLineInfo2 = LineInfo.init()
        testLineInfo2.printLineState()
        
        
        var resultEstError2 : [[Int]] = []
        
        for _ in 0..<2{
            let appended = [Int](count:13,repeatedValue:0)
            resultEstError2.append(appended)
        }
        
        
        var writtenText:String = ""
        //writtenText += testLineInfo2.dataReceiveTime + "\n"
        //write header row down
        let probLoopRepeatTime : Int = Int((1.0 - CommonConst.probLowerThreshold)/CommonConst.probSpilitInterval)
        for probseed in 0...probLoopRepeatTime{
            writtenText += (CommonConst.probLowerThreshold+CommonConst.probSpilitInterval*Double(probseed)).description + ","
        }
        writtenText.removeAtIndex(writtenText.endIndex.predecessor())
        writtenText += "\n"
        
        //write data value down
        
        for i in 0..<10{
            for probseed in 0...probLoopRepeatTime{
                writtenText += CellularAutomata.ruleStochasticsCAAsAverageWithAccuracyEvaluation(testLineInfo2,numOfCellPerMinute: (i+1),hoppingProbToNilCell: CommonConst.probLowerThreshold+CommonConst.probSpilitInterval*Double(probseed), hoppingProbToStationCell: CommonConst.propProbParam*(CommonConst.probLowerThreshold+CommonConst.probSpilitInterval*Double(probseed)), timestepPerOnce: 80*(i+1), predictionTime: 10, targetEvaluateStationPoint: "odpt.Station:TokyoMetro.Ginza.Ueno").description + ","
            }
            writtenText.removeAtIndex(writtenText.endIndex.predecessor())
            writtenText += "\n"
            //print(writtenText)
        }
        
    
        //print(writtenText)
        if let _ : NSString = NSSearchPathForDirectoriesInDomains( NSSearchPathDirectory.DesktopDirectory, NSSearchPathDomainMask.AllDomainsMask, true ).first {
            
            
            let file_name = ("result"+timeStmpStr+".csv")
            do {
                
                try writtenText.writeToFile( "/Users/ev30112/Dropbox/programming/TokyoMetroWatch/StoreResults/\(file_name)", atomically: false, encoding: NSUTF8StringEncoding )
                
            } catch {
                print("file error")
            }
        }

    }
}
