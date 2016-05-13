//
//  AWPromise.swift
//  AWHttpRequest
//
//  Created by 秦 道平 on 16/5/8.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation

// MARK: - AWResult
enum AWResult<T> {
    case Success(T)
    case Error(NSError)
}

// MARK: - Error
enum AWPromiseError:ErrorType {
    case PromiseError(String)
}

// MARK: - Promise
enum AWPromiseState {
    case Panding, FullFilled, Rejected
}

class AWPromise<T> {
    typealias ResolveFunc = (T) -> ()
    typealias RejectFunc = (NSError) -> ()
    typealias PromiseBlock = (resolve:ResolveFunc,reject:RejectFunc) -> ()
    /// 用来保存后续操作
    var f_then : ResolveFunc? = nil
    /// 用来保存错误处理
    var f_error : RejectFunc? = nil
    /// 状态
    var state:AWPromiseState = .Panding
    /// 运行的结果
    var result : AWResult<T>? = nil
    init(@noescape block:PromiseBlock){
        block(resolve: { (t) in
            self.complete(t)
        }) { (error) in
            self.fail(error)
        }
    }
    func complete(t:T) -> () {
        self.result = AWResult.Success(t)
        state = .FullFilled
        f_then?(t) /// 如果 promise 内是同步函数， f_then 是还未被赋值时就被 complete 调用的
    }
    func fail(error:NSError) -> () {
        self.result = AWResult.Error(error)
        state = .Rejected
        f_error?(error)
    }
    func then<U>(f: (T throws -> U)) -> AWPromise<U> {
        /// 如果已经获取到值 (所在的 promise 是同步的) ，直接调用后面的方法
        if let _result = self.result {
            return AWPromise<U>(block: { (resolve, reject) in
                if self.state == .FullFilled {
                    if case let AWResult.Success(t) = _result {
                        do {
                            let u = try f(t)
                            resolve(u)
                        }
                        /// 捕捉 then 闭包中抛出的错误
                        catch AWPromiseError.PromiseError(let str) {
                            reject(NSError(domain: str, code: 0, userInfo: nil))
                        }
                        catch _ {
                            let error = NSError(domain: "Promise Error", code: 0, userInfo: nil)
                            reject(error)
                        }
                    }
                }
                else if self.state == .Rejected {
                    if case let AWResult.Error(error) = _result {
                        reject(error)
                    }
                }
            })
        }
        else { /// 所在的 promise 是异步的 (还未获取到值)，要封装操作后面执行
            return AWPromise<U>(block: { (resolve, reject) in
                self.f_error = reject
                self.f_then = { (t:T) -> () in
                    do {
                        let u = try f(t)
                        resolve(u)
                    }
                    /// 捕捉 then 闭包中捕捉的错误
                    catch AWPromiseError.PromiseError(let str) {
                        reject(NSError(domain: str, code: 0, userInfo: nil))
                    }
                    catch _ {
                        let error = NSError(domain: "Promise Error", code: 0, userInfo: nil)
                        reject(error)
                    }
                    
                }
            })
        }
    }
    /// 这个方法用来在 then 中返回另一个 Promise 对象 (在 then 中构造另一个异步代码)
    func then<U>(f : (T throws -> AWPromise<U>)) -> AWPromise<U> {
        /// 如果已经获取到值 (闭包中是同步代码)，将直接调用后面的方法
        if let _result = self.result {
            return AWPromise<U>(block: { (resolve, reject) in
                if self.state == .FullFilled {
                    if case let AWResult.Success(t) = _result {
                        do {
                            let promise = try f(t) /// 如果返回的 promise 内是同步函数，这里已经得到 result
                            promise.f_error = reject
                            promise.f_then = resolve
    //                        print(promise.result)
                            /// 如果 promise 里面是一个同步方法，就直接调用结束
                            if let _p_result = promise.result {
                                if case let AWResult.Success(_p_u) = _p_result {
                                    resolve(_p_u)
                                }
                                if case let AWResult.Error(_p_error) = _p_result {
                                    reject(_p_error)
                                }
                            }
                        }
                        /// 捕捉 then 中用 throw 抛出的错误，注意 then 中构造新的 Promise 对象中不要用  throw 错误，在 Promise 对象构造中应该使用 reject 来抛出错误
                        catch AWPromiseError.PromiseError(let str) {
                            reject(NSError(domain: str, code: 0, userInfo: nil))
                        }
                        catch _ {
                            reject(NSError(domain: "Promise Error", code: 0, userInfo: nil))
                        }
                    }
                }
                else if self.state == .Rejected {
                    if case let AWResult.Error(error) = _result {
                        reject(error)
                    }
                }
            })
            
        }
        /// 所在的 promise 是异步的， 要封装操作后后面执行
        else {
            return AWPromise<U>(block: { (resolve, reject) in
                self.f_error = reject
                self.f_then = { (t:T) -> () in
                    do {
                        let promise = try f(t)
                        promise.f_error = reject
                        promise.f_then = resolve
                        /// 如果 promise 里面是一个同步方法，就直接调用结束
                        if let _p_result = promise.result {
                            if case let AWResult.Success(_p_u) = _p_result {
                                resolve(_p_u)
                            }
                            if case let AWResult.Error(_p_error) = _p_result {
                                reject(_p_error)
                            }
                        }
                    }
                    /// 捕捉 then 中用 throw 抛出的错误，注意 then 中构造新的 Promise 对象中不要用  throw 错误，在 Promise 对象构造中应该使用 reject 来抛出错误
                    catch AWPromiseError.PromiseError(let str) {
                        reject(NSError(domain: str, code: 0, userInfo: nil))
                    }
                    catch _ {
                        reject(NSError(domain: "Promise Error", code: 0, userInfo: nil))
                    }
                }
            })
        }
        
    }
    func error(f:RejectFunc) -> () {
        self.f_error = f
        /// 如果已经发送错误，直接调用
        if self.state == .Rejected {
            if let _result = self.result {
                if case let AWResult.Error(error) = _result {
                    f(error)
                }
            }
        }
    }
    
}
