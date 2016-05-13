//
//  AWPromise+Alamofire.swift
//  AWHttpRequest
//
//  Created by 秦 道平 on 16/5/10.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Request
// MARK: get/post/put/delete
extension Alamofire.Request {
    static func get(url:URLStringConvertible,
             params:[String:AnyObject]? = nil,
             headers : [String:String]? = nil) -> Alamofire.Request {
        return Alamofire.request(.GET, url, parameters: params, headers: headers)
    }
    static func post(url:URLStringConvertible,
                    params: [String:AnyObject]? = nil,
                    headers : [String:String]? = nil) -> Alamofire.Request {
        return Alamofire.request(.POST, url, parameters: params, headers: headers)
    }
    static func put(url:URLStringConvertible,
                    params:[String:AnyObject]? = nil,
                    headers: [String:String]? = nil) -> Alamofire.Request {
        return Alamofire.request(.PUT, url, parameters: params, headers: headers)
    }
    static func delete(url:URLStringConvertible,
                    params:[String:AnyObject]? = nil,
                    headers : [String:String]? = nil) -> Alamofire.Request {
        return Alamofire.request(.DELETE, url, parameters: params, headers: headers)
    }
}
// MARK: Response
extension Alamofire.Request {
    func responseData(dataCallback:DataCallback,
            onError errorBlock:ErrorCallback? = nil) -> Self {
        return self.responseData { (response) in
            guard response.result.isSuccess else {
                if let error = response.result.error {
                    errorBlock?(error)
                }
                return
            }
            if let data = response.result.value {
                dataCallback(data)
            }
            else {
                let error = NSError(domain: "empty data", code: 0, userInfo: nil)
                errorBlock?(error)
            }
        }
    }
    func responseString(stringCallback:StringCallback,
                        onError errorBlock:ErrorCallback? = nil) -> Self {
        return self.responseString { (response) in
                guard response.result.isSuccess else {
                    if let error = response.result.error {
                        errorBlock?(error)
                    }
                    return
                }
                if let str = response.result.value {
                    stringCallback(str)
                }
                else {
                    let error = NSError(domain: "empty string", code: 0, userInfo: nil)
                    errorBlock?(error)
                }
        }
    }
    func responseJSON(jsonCallback:JsonCallback,
                      onError errorBlock:ErrorCallback? = nil) -> Self {
        return self.responseJSON { (response) in
                guard response.result.isSuccess else {
                    if let error = response.result.error {
                        errorBlock?(error)
                    }
                    return
                }
                if let json = response.result.value as? [String:AnyObject] {
                    jsonCallback(json)
                }
                else {
                    let error = NSError(domain: "no json response", code: 0, userInfo: nil)
                    errorBlock?(error)
                }
        }
    }
    
}
// MARK: Promise
extension Alamofire.Request {
    func dataPromise() -> AWPromise<NSData> {
        return AWPromise<NSData>(block: { (resolve, reject) in
            self.responseData({ (data) in
                resolve(data)
                }, onError: { (error) in
                    reject(error)
            })
        })
    }
    func stringPromise() -> AWPromise<String> {
        return AWPromise<String>(block: { (resolve, reject) in
            self.responseString({ (str) in
                resolve(str)
                }, onError: { (error) in
                    reject(error)
            })
        })
    }
    func jsonPromise() -> AWPromise<[String:AnyObject]> {
        return AWPromise<[String:AnyObject]>(block: { (resolve, reject) in
            self.responseJSON({ (json) in
                resolve(json)
                }, onError: { (error) in
                    reject(error)
            })
        })
    }
}

func test_alamofire() {
    Alamofire
        .request(.GET, "http://www.codingnext.com")
        .responseString({ (str) in
            debugPrint(str)
            }) { (error) in
                debugPrint(error)
    }
    
    Alamofire
        .request(.GET, "http://www.codingnext.com").stringPromise()
        .then { (str) in
            debugPrint(str)
        }
    
    Alamofire.Request.get("http://www.codingnext.com").stringPromise()
        .then { (str) in
            debugPrint(str)
    }
    
}