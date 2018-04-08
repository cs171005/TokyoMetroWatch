//
//  CellularAutomata.swift
//  TokyoMetroWatch
//
//  Created by 河野穣 on 2016/06/22.
//  Copyright © 2016年 河野穣. All rights reserved.
//

import Foundation

class CellularAutomata{
    class func rule184(TargetLine:LineInfo,numOfCellPerMinute:Int){
        TargetLine.convertLineStateToCellStructure(numOfCellPerMinute)
        
        var oldLineState:[Int] = []
        var newLineState:[Int] = []
        
        let oldLineCellState = TargetLine.StateHistory.last!
        var newLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
        
        
        // preserve the current line state to innnerLinestate
        for pickedCell in TargetLine.StateHistory.last! {
            oldLineState.append(pickedCell.CellState)
            //produce newLineState at the same time as 0 sequence
            newLineState.append(0)
        }
        
        //Calculation of cellular automata
        for i in 0..<oldLineState.count-1{
            if oldLineState[i]==1{
                if oldLineState[i+1]==0 {
                    //does not exist in the next cell
                    newLineState[i+1]=1
                    newLineState[i]=0
                    
                    newLineCellState[i+1].TrainNumber = oldLineCellState[i].TrainNumber
                    newLineCellState[i+1].TrainType = oldLineCellState[i].TrainType
                    
                    
                }else{
                    //exist in the next cell
                    newLineState[i]=1
                    
                    newLineCellState[i].TrainNumber = oldLineCellState[i].TrainNumber
                    newLineCellState[i].TrainType = oldLineCellState[i].TrainType
                    
                }
            }
        }
        
        
        
        for i in 0 ..< newLineCellState.count{
            newLineCellState[i].CellState = newLineState[i]
        }
        
        if TargetLine.StateHistory.count == 1 {
            printCellStateWithRectangle(TargetLine,targetState: oldLineState)
        }
        
        printCellStateWithRectangle(TargetLine,targetState: newLineState)
        
        TargetLine.StateHistory.append(newLineCellState)
        
        
    }
    
    class func ruleStochasticsCA(TargetLine:LineInfo,numOfCellPerMinute:Int,hoppingProbToNilCell:Double,hoppingProbToStationCell:Double){
        TargetLine.convertLineStateToCellStructure(numOfCellPerMinute)
        var oldLineState:[Int] = []
        var newLineState:[Int] = []
        
        let oldLineCellState = TargetLine.StateHistory.last!
        var newLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
        
        // preserve the current line state to innnerLinestate
        for pickedCell in oldLineCellState {
            oldLineState.append(pickedCell.CellState)
            //produce newLineState at the same time as 0 sequence
            newLineState.append(0)
        }
        
        //Calculation of cellular automata
        //determinng the state of the target cell (not meaning calculating it) is the following scheme
        //1: confirm whether train is in the "TARGET" cell
        //2: if so, confirm it in the "NEXT" cell
        //3: check whether the next cell has a station name or not (determine the next is a station or not)
        //4: magnitude comparison of the hoppingProbRealizationValue and hoppingProbToNilCell or hoppingProbToStationCell
        
        for i in oldLineState.startIndex ..< oldLineState.endIndex-1{
            //In advance, calculate the realized value
            let hoppingProbRealizationValue:Double = Double(arc4random())/Double(UINT32_MAX)
            
            if oldLineState[i]==1{
                //train exist in the target cell
                if oldLineState[i+1]==0 {
                    //does not exist in one previous cell
                    switch TargetLine.StateArray[i+1].StationName {
                    //the next cell is ...
                    case nil:
                        //not a station
                        if hoppingProbRealizationValue < hoppingProbToNilCell{
                            //moved to the next cell
                            newLineState[i+1]=1
                            newLineState[i]=0
                            
                            newLineCellState[i+1].TrainNumber = oldLineCellState[i].TrainNumber
                            newLineCellState[i+1].TrainType = oldLineCellState[i].TrainType
                        }else{
                            //means stay there
                            newLineState[i]=1
                            
                            newLineCellState[i].TrainNumber = oldLineCellState[i].TrainNumber
                            newLineCellState[i].TrainType = oldLineCellState[i].TrainType
                        }
                        break
                        
                    default:
                        //a station
                        if hoppingProbRealizationValue < hoppingProbToStationCell{
                            newLineState[i+1]=1
                            newLineState[i]=0
                            
                            newLineCellState[i+1].TrainNumber = oldLineCellState[i].TrainNumber
                            newLineCellState[i+1].TrainType = oldLineCellState[i].TrainType
                            
                        }else{
                            //means stay there
                            newLineState[i]=1
                            
                            newLineCellState[i].TrainNumber = oldLineCellState[i].TrainNumber
                            newLineCellState[i].TrainType = oldLineCellState[i].TrainType
                        }
                        break
                    }
                }else{
                    //exist in one previous cell
                    newLineState[i]=1
                }
            }
        }
        
        if TargetLine.StateHistory.count == 1 {
            printCellStateWithRectangle(TargetLine,targetState: oldLineState)
            //print(oldLineState)
        }
        printCellStateWithRectangle(TargetLine,targetState: newLineState)
        //print(newLineState)
        
        for i in 0 ..< newLineCellState.count{
            newLineCellState[i].CellState = newLineState[i]
        }
        TargetLine.StateHistory.append(newLineCellState)
        
    }
    
    class func ruleStochasticsCAAsAverage(TargetLine:LineInfo,numOfCellPerMinute:Int,hoppingProbToNilCell:Double,hoppingProbToStationCell:Double,timestepPerOnce:Int,predictionTime:Int){
        TargetLine.convertLineStateToCellStructure(numOfCellPerMinute)
        
        var oldLineState:[Int] = []
        var newLineState:[Int] = []
        
        var predictedStateHistory:[[CellState]] = []
        var storedStateHistory:[[[CellState]]] = []
        
        let oldLineCellState = TargetLine.StateHistory.last!
        var newLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
        
        var storedTrainPosList:[[[String:Int]]] = []
        
        var meansPredictedStateHistory:[[CellState]] = []
        var meansNewLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
        var meansNewLineState:[Int] = []
        
        //Calculation of cellular automata
        //determinng the state of the target cell (not meaning calculating it) is the following scheme
        //1: confirm whether train is in the "TARGET" cell
        //2: if so, confirm it in the "NEXT" cell
        //3: check whether the next cell has a station name or not (determine the next is a station or not)
        //4: magnitude comparison of the hoppingProbRealizationValue and hoppingProbToNilCell or hoppingProbToStationCell
        for predtime in 0 ..< predictionTime{
            predictedStateHistory.append(TargetLine.StateHistory.last!)
            for _ in 0 ..< timestepPerOnce {
                // preserve the current line state to innerLinestate
                for pickedCell in predictedStateHistory.last! {
                    oldLineState.append(pickedCell.CellState)
                }
                
                for _ in 0 ..< oldLineCellState.count {
                    //produce newLineState as 0 sequence
                    newLineState.append(0)
                }
                for i in oldLineState.startIndex ..< oldLineState.endIndex-1{
                    //In advance, calculate the realized value
                    let hoppingProbRealizationValue:Double = Double(arc4random())/Double(UINT32_MAX)
                    
                    if oldLineState[i]==1{
                        //train exist in the target cell
                        if oldLineState[i+1]==0 {
                            //does not exist in one previous cell
                            switch TargetLine.StateArray[i+1].StationName {
                            //the next cell is ...
                            case nil:
                                //not a station
                                if hoppingProbRealizationValue < hoppingProbToNilCell{
                                    //moved to the next cell
                                    newLineState[i+1]=1
                                    newLineState[i]=0
                                    
                                    newLineCellState[i+1].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                                    newLineCellState[i+1].TrainType = (predictedStateHistory.last!)[i].TrainType
                                }else{
                                    //means stay there
                                    newLineState[i]=1
                                    
                                    newLineCellState[i].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                                    newLineCellState[i].TrainType = (predictedStateHistory.last!)[i].TrainType
                                }
                                break
                                
                            default:
                                //a station
                                if hoppingProbRealizationValue < hoppingProbToStationCell{
                                    newLineState[i+1]=1
                                    newLineState[i]=0
                                    
                                    newLineCellState[i+1].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                                    newLineCellState[i+1].TrainType = (predictedStateHistory.last!)[i].TrainType
                                    
                                }else{
                                    //means stay there
                                    newLineState[i]=1
                                    
                                    newLineCellState[i].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                                    newLineCellState[i].TrainType = (predictedStateHistory.last!)[i].TrainType
                                }
                                break
                            }
                        }else{
                            //exist in one previous cell
                            newLineState[i]=1
                            newLineCellState[i].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                            newLineCellState[i].TrainType = (predictedStateHistory.last!)[i].TrainType
                        }
                    }
                }
                
//                if predictedStateHistory.count == 1 {
//                    printCellStateWithRectangle(TargetLine,targetState: oldLineState)
//                    //print(oldLineState)
//                }
//                printCellStateWithRectangle(TargetLine,targetState: newLineState)
                //print(newLineState)
                
                for i in 0 ..< newLineCellState.count{
                    newLineCellState[i].CellState = newLineState[i]
                }
                predictedStateHistory.append(newLineCellState)
                newLineState.removeAll()
                newLineState = []
                oldLineState.removeAll()
                oldLineState = []
                newLineCellState.removeAll()
                newLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
                
            }
            
            if predtime < predictionTime-1{
                print("-", terminator: "")
            }else{
                print("-|")
            }
            
            storedStateHistory.append(predictedStateHistory)
            predictedStateHistory.removeAll()
        }
        //        to confirm the contents of storedStateHistory as law datas (text datas)
        //        for i in 0 ..< storedStateHistory.count{
        //            // i is a number which represents what time of the prediction
        //            for j in 0 ..< storedStateHistory[i].count{
        //                // j is timestep (one timestep is represented as a line)
        //                for k in 0 ..< storedStateHistory[i][j].count{
        //                    // k is cellState index
        //                    print(storedStateHistory[i][j][k])
        //                }
        //                print("^^^^^^^^^^^^^^^^^^^^^")
        //
        //                print("-----------------")
        //            }
        //            print("~~~~~~~~~~~~~~~~~~~~")
        //        }
        
        //Aggregation of train positions in each time
        for i in 0 ..< storedStateHistory.count{
            // i is a number which represents what time of the prediction
            var prestoredTrainPosList:[[String:Int]] = []
            for j in 0 ..< storedStateHistory[i].count{
                // j is timestep (one timestep is represented as a line)
                var TrainPosList:[String:Int] = [:]
                for targetTrain in TargetLine.TrainnumberList{
                    for k in 0 ..< storedStateHistory[i][j].count{
                        // k is cellState index
                        if(storedStateHistory[i][j][k].TrainNumber != nil && targetTrain == storedStateHistory[i][j][k].TrainNumber ){
                            //print("sim:\(i):"+"time:\(j):"+"\(targetTrain):"+"cellpos:\(k)")
                            TrainPosList[targetTrain] = k
                            break
                        }
                    }
                    //print("^^^^^^^^^^^^^^^^^^^^^")
                }
                //print(TrainPosList)
                prestoredTrainPosList.append(TrainPosList)
                //print("-----------------")
            }
            //print(prestoredTrainPosList)
            storedTrainPosList.append(prestoredTrainPosList)
            //print("~~~~~~~~~~~~~~~~~~~~")
        }
        
        //        storedTrainPosList[0].forEach{print("\($0)")}
        //        print("-----------------")
        //        storedTrainPosList[1].forEach{print("\($0)")}
        print(TargetLine.dataReceiveTime)
        print(numOfCellPerMinute,hoppingProbToNilCell,hoppingProbToStationCell)
        print("------------------------means prediction------------------------")
        var pos_mean = 0.0
        for timestep in 0 ... timestepPerOnce{
            meansNewLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
            for _ in 0 ..< oldLineCellState.count {
                //produce newLineState as 0 sequence
                meansNewLineState.append(0)
            }
            
            for target in TargetLine.TrainnumberList{
                var exception = 0
                for sim in 0 ..< predictionTime{
                    //print("\(timestep):\(target):"+"\(storedTrainPosList[sim][timestep][target])")
                    if storedTrainPosList[sim][timestep][target] != nil{
                        //calculate sumation of position
                        pos_mean += Double(storedTrainPosList[sim][timestep][target]!)
                    }else{
                        exception += 1
                    }
                }
                
                if predictionTime == exception {
                        break
                }/*else if exception != 0 && exception < predictionTime{
                    pos_mean += Double(exception)*Double(TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute).count)
                    
                }*/
                
                pos_mean = round(pos_mean/Double(predictionTime-exception))
                let ind = Int(pos_mean)
                //print(ind)
                meansNewLineCellState[ind].TrainNumber = target
                meansNewLineCellState[ind].CellState = 1
                meansNewLineState[ind] = 1
                //                print("[\(timestep):\(target):"+"\(pos_mean)]")
                //                print("-----------------")
                pos_mean = 0.0
            }
            printCellStateWithRectangle(TargetLine, targetState: meansNewLineState)
            meansPredictedStateHistory.append(meansNewLineCellState)
            meansNewLineCellState.removeAll()
            meansNewLineState.removeAll()
            //            print("-----------------")
        }
        print("------------------------means prediction------------------------")
    }
    
    class func ruleStochasticsCAAsAverageWithAccuracyEvaluation(TargetLine:LineInfo,numOfCellPerMinute:Int,hoppingProbToNilCell:Double,hoppingProbToStationCell:Double,timestepPerOnce:Int,predictionTime:Int,targetEvaluateStationPoint:String)-> Int{
        TargetLine.convertLineStateToCellStructure(numOfCellPerMinute)
        
        let trueTravelTime = 1620
        var estimatedTravelTimeError = 0
        var estmatedErrorSum = 0
        
        var oldLineState:[Int] = []
        var newLineState:[Int] = []
        
        var predictedStateHistory:[[CellState]] = []
        var storedStateHistory:[[[CellState]]] = []
        
        let oldLineCellState = TargetLine.StateHistory.last!
        var newLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
        
        var storedTrainPosList:[[[String:Int]]] = []
        
        var meansPredictedStateHistory:[[CellState]] = []
        var meansNewLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
        var meansNewLineState:[Int] = []
        
        //Calculation of cellular automata
        //determinng the state of the target cell (not meaning calculating it) is the following scheme
        //1: confirm whether train is in the "TARGET" cell
        //2: if so, confirm it in the "NEXT" cell
        //3: check whether the next cell has a station name or not (determine the next is a station or not)
        //4: magnitude comparison of the hoppingProbRealizationValue and hoppingProbToNilCell or hoppingProbToStationCell
        var arrivedTarget = false
        for predtime in 0 ..< predictionTime{
            predictedStateHistory.append(TargetLine.StateHistory.last!)
            for timestep in 0 ..< timestepPerOnce {
                // preserve the current line state to innerLinestate
                for pickedCell in predictedStateHistory.last! {
                    oldLineState.append(pickedCell.CellState)
                }
                
                for _ in 0 ..< oldLineCellState.count {
                    //produce newLineState as 0 sequence
                    newLineState.append(0)
                }
                for i in oldLineState.startIndex ..< oldLineState.endIndex-1{
                    //In advance, calculate the realized value
                    
                    let hoppingProbRealizationValue:Double = Double(arc4random())/Double(UINT32_MAX)
                    
                    if oldLineState[i]==1{
                        //train exist in the target cell
                        if oldLineState[i+1]==0 {
                            //does not exist in one previous cell
                            switch TargetLine.StateArray[i+1].StationName {
                            //the next cell is ...
                            case nil:
                                //not a station
                                if hoppingProbRealizationValue < hoppingProbToNilCell{
                                    //moved to the next cell
                                    newLineState[i+1]=1
                                    newLineState[i]=0
                                    
                                    newLineCellState[i+1].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                                    newLineCellState[i+1].TrainType = (predictedStateHistory.last!)[i].TrainType
                                }else{
                                    //means stay there
                                    newLineState[i]=1
                                    
                                    newLineCellState[i].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                                    newLineCellState[i].TrainType = (predictedStateHistory.last!)[i].TrainType
                                }
                                break
                                
                            default:
                                //a station
                                if hoppingProbRealizationValue < hoppingProbToStationCell{
                                    newLineState[i+1]=1
                                    newLineState[i]=0
                                    
                                    newLineCellState[i+1].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                                    newLineCellState[i+1].TrainType = (predictedStateHistory.last!)[i].TrainType
                                    
                                }else{
                                    //means stay there
                                    newLineState[i]=1
                                    
                                    newLineCellState[i].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                                    newLineCellState[i].TrainType = (predictedStateHistory.last!)[i].TrainType
                                }
                                break
                            }
                        }else{
                            //exist in one previous cell
                            newLineState[i]=1
                            newLineCellState[i].TrainNumber = (predictedStateHistory.last!)[i].TrainNumber
                            newLineCellState[i].TrainType = (predictedStateHistory.last!)[i].TrainType
                        }
                    }
                }
                
//                if predictedStateHistory.count == 1 {
//                    printCellStateWithRectangle(TargetLine,targetState: oldLineState)
//                    //print(oldLineState)
//                }
//                printCellStateWithRectangle(TargetLine,targetState: newLineState)
                //print(newLineState)
                
                for i in 0 ..< newLineCellState.count{
                    newLineCellState[i].CellState = newLineState[i]
                    //print("trainnum:"+"\(newLineCellState[i].TrainNumber)")
                    //print("staname:"+"\(newLineCellState[i].StationName)")
                    //print(arrivedTarget)
                    if newLineCellState[i].TrainNumber == TargetLine.TrainnumberList[0] && newLineCellState[i].StationName == targetEvaluateStationPoint && !arrivedTarget{
                        estimatedTravelTimeError = (timestep+1)*(60/numOfCellPerMinute)-trueTravelTime
                        //print(estimatedTravelTimeError)
                        arrivedTarget = true
                        //print(arrivedTarget)
                    }
                }
                predictedStateHistory.append(newLineCellState)
                newLineState.removeAll()
                newLineState = []
                oldLineState.removeAll()
                oldLineState = []
                newLineCellState.removeAll()
                newLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
                
            }
            
            estmatedErrorSum += estimatedTravelTimeError*estimatedTravelTimeError
            
            if predtime < predictionTime-1{
                print("-", terminator: "")
            }else{
                print("-|")
            }
            
            storedStateHistory.append(predictedStateHistory)
            predictedStateHistory.removeAll()
            
            estimatedTravelTimeError = 0
            arrivedTarget = false
        }
        
        
        
        estmatedErrorSum /= predictionTime
        //        to confirm the contents of storedStateHistory as law datas (text datas)
        //        for i in 0 ..< storedStateHistory.count{
        //            // i is a number which represents what time of the prediction
        //            for j in 0 ..< storedStateHistory[i].count{
        //                // j is timestep (one timestep is represented as a line)
        //                for k in 0 ..< storedStateHistory[i][j].count{
        //                    // k is cellState index
        //                    print(storedStateHistory[i][j][k])
        //                }
        //                print("^^^^^^^^^^^^^^^^^^^^^")
        //
        //                print("-----------------")
        //            }
        //            print("~~~~~~~~~~~~~~~~~~~~")
        //        }
        
        //Aggregation of train positions in each time
        for i in 0 ..< storedStateHistory.count{
            // i is a number which represents what time of the prediction
            var prestoredTrainPosList:[[String:Int]] = []
            for j in 0 ..< storedStateHistory[i].count{
                // j is timestep (one timestep is represented as a line)
                var TrainPosList:[String:Int] = [:]
                for targetTrain in TargetLine.TrainnumberList{
                    for k in 0 ..< storedStateHistory[i][j].count{
                        // k is cellState index
                        if(storedStateHistory[i][j][k].TrainNumber != nil && targetTrain == storedStateHistory[i][j][k].TrainNumber ){
                            //print("sim:\(i):"+"time:\(j):"+"\(targetTrain):"+"cellpos:\(k)")
                            TrainPosList[targetTrain] = k
                            break
                        }
                    }
                    //print("^^^^^^^^^^^^^^^^^^^^^")
                }
                //print(TrainPosList)
                prestoredTrainPosList.append(TrainPosList)
                //print("-----------------")
            }
            //print(prestoredTrainPosList)
            storedTrainPosList.append(prestoredTrainPosList)
            //print("~~~~~~~~~~~~~~~~~~~~")
        }
        
        //        storedTrainPosList[0].forEach{print("\($0)")}
        //        print("-----------------")
        //        storedTrainPosList[1].forEach{print("\($0)")}
        print(TargetLine.dataReceiveTime)
        print(numOfCellPerMinute,hoppingProbToNilCell,hoppingProbToStationCell)
        //print("------------------------means prediction------------------------")
        var pos_mean = 0.0
        for timestep in 0 ... timestepPerOnce{
            meansNewLineCellState = TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute)
            for _ in 0 ..< oldLineCellState.count {
                //produce newLineState as 0 sequence
                meansNewLineState.append(0)
            }
            
            for target in TargetLine.TrainnumberList{
                var exception = 0
                for sim in 0 ..< predictionTime{
                    //print("\(timestep):\(target):"+"\(storedTrainPosList[sim][timestep][target])")
                    if storedTrainPosList[sim][timestep][target] != nil{
                        //calculate sumation of position
                        pos_mean += Double(storedTrainPosList[sim][timestep][target]!)
                    }else{
                        exception += 1
                    }
                }
                
                if predictionTime == exception {
                    break
                }/*else if exception != 0 && exception < predictionTime{
                 pos_mean += Double(exception)*Double(TargetLine.setNilLineCellStateWithNecessaryTime(numOfCellPerMinute).count)
                 
                 }*/
                
                pos_mean = round(pos_mean/Double(predictionTime-exception))
                let ind = Int(pos_mean)
                //print(ind)
                meansNewLineCellState[ind].TrainNumber = target
                meansNewLineCellState[ind].CellState = 1
                meansNewLineState[ind] = 1
                //                print("[\(timestep):\(target):"+"\(pos_mean)]")
                //                print("-----------------")
                pos_mean = 0.0
            }
            //printCellStateWithRectangle(TargetLine, targetState: meansNewLineState)
            meansPredictedStateHistory.append(meansNewLineCellState)
            meansNewLineCellState.removeAll()
            meansNewLineState.removeAll()
            //            print("-----------------")
        }
        //print("------------------------means prediction------------------------")
        print(estmatedErrorSum)
        return estmatedErrorSum
    }
    
    class private func printCellStateWithRectangle(TargetLine:LineInfo,targetState:[Int]){
        var StateWithRectangle:String = ""
        for i in targetState.startIndex ..< targetState.endIndex{
            if TargetLine.StateArray[i].StationName != nil{
                StateWithRectangle += "["
            }
            
            switch targetState[i]{
            case 0:
                StateWithRectangle += "□"
                break
            case 1:
                StateWithRectangle += "■"
                break
            default:
                break
            }
            if TargetLine.StateArray[i].StationName != nil{
                StateWithRectangle += "]"
            }else{
                StateWithRectangle += ""
            }
        }
        print(StateWithRectangle)
        
    }
}

