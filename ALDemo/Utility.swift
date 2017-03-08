//
//  Utility.swift
//  ALDemo
//
//  Created by 解 磊 on 2017/3/7.
//  Copyright © 2017年 AppLeg Corp. All rights reserved.
//

import Foundation

/// 延迟处理作业类型
typealias Task = (_ cancel : Bool) -> Void

/**
 延迟处理作业
 
 - parameter time: 延迟秒数
 - parameter task: 作业内容
 
 - returns: 延迟处理作业
 */
func delay(_ time:TimeInterval, task:@escaping ()->()) ->  Task? {
    
    func dispatch_later(_ block:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
            execute: block)
    }
    
    var closure: (()->())? = task
    var result: Task?
    
    let delayedClosure: Task = {
        cancel in
        if let internalClosure = closure {
            if (cancel == false) {
                DispatchQueue.main.async(execute: internalClosure);
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayedClosure
    
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    
    return result;
}

/**
 取消延迟处理作业
 
 - parameter task: 延迟处理作业
 */
func cancel(_ task:Task?) {
    task?(true)
}

/**
 生成随机整数
 
 - parameter range: 随机整数范围
 
 - returns: 随机整数
 */
func randomInRange(_ range: Range<Int>) -> Int {
    let count = UInt32(range.upperBound - range.lowerBound)
    return  Int(arc4random_uniform(count)) + range.lowerBound
}
