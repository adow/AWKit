//
//  Model.swift
//  cxlihe
//
//  Created by 秦 道平 on 16/4/17.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation

// MARK: - model
protocol AWJsonModel {
    init(dict:[String:AnyObject])
    static func listFromArray(array:[[String:AnyObject]]) -> [Self]
}
extension AWJsonModel {
    static func listFromArray(array:[[String:AnyObject]]) -> [Self] {
        var l : [Self] = []
        for dict in array {
            let m = Self.init(dict:dict)
            l.append(m)
        }
        return l
    }
}

// MARK: - ApiPromiseMethods
protocol AWApiPromiseMethods {
    func getJsonPromise(parameters:[String:AnyObject],
                headers : [String:String]?) -> AWPromise<[String:AnyObject]>
    func postJsonPromise(parameters:[String:AnyObject],
                headers : [String:String]?) -> AWPromise<[String:AnyObject]>
    func putJsonPromise(paramseters:[String:AnyObject],
                headers:[String:String]?) -> AWPromise<[String:AnyObject]>
    func getModelPromise<T:AWJsonModel>(parameters:[String:AnyObject],
                headers:[String:String]?) -> AWPromise<T>
    func postModelPromise<T:AWJsonModel>(parameters:[String:AnyObject],
                headers:[String:String]?) -> AWPromise<T>
    func putModelPromise<T:AWJsonModel>(parameters:[String:AnyObject],
                headers:[String:String]?) -> AWPromise<T>
    
    var url : NSURL! {
        get
    }
}
/// Default Implementations
extension AWApiPromiseMethods {
    func getJsonPromise(parameters:[String:AnyObject] = [:],
                        headers:[String:String]? = nil) -> AWPromise<[String:AnyObject]> {
        return AWHttpRequest.get(self.url, params: parameters,headers: headers).jsonPromise()
    }
    func postJsonPromise(parameters:[String:AnyObject] = [:],
                         headers:[String:String]? = nil) -> AWPromise<[String:AnyObject]> {
        return AWHttpRequest.post(self.url, params: parameters,headers: headers).jsonPromise()
    }
    func putJsonPromise(parameters: [String:AnyObject] = [:],
                        headers:[String:String]? = nil ) -> AWPromise<[String:AnyObject]> {
        return AWHttpRequest.put(self.url, params: parameters,headers: headers).jsonPromise()
    }
    func getModelPromise<T:AWJsonModel>(parameters:[String:AnyObject] = [:],
                         headers:[String:String]? = nil) -> AWPromise<T> {
        return AWPromise<T>(block: { (fulfill, reject) in
            self.getJsonPromise(parameters,headers: headers).then({ (json) -> () in
                let t = T.init(dict: json)
                fulfill(t)
            })
        })
    }
    func postModelPromise<T:AWJsonModel>(parameters:[String:AnyObject] = [:],
                          headers:[String:String]? = nil) -> AWPromise<T> {
        return AWPromise<T>(block: { (fulfill, reject) in
            self.postJsonPromise(parameters,headers: headers).then({ (json) -> () in
                let t = T.init(dict: json)
                fulfill(t)
            })
        })
    }
    func putModelPromise<T:AWJsonModel>(parameters:[String:AnyObject] = [:],headers:[String:String]? = nil) -> AWPromise<T> {
        return AWPromise<T>(block: { (fulfill, reject) in
            self.putJsonPromise(parameters,headers: headers).then({ (json) -> () in
                let t = T.init(dict: json)
                fulfill(t)
            })
        })
    }
}

// MARK: - test
enum CXApi {
    enum Home : AWApiPromiseMethods {
        case index
        var url: NSURL! {
            get {
                switch self {
                case .index:
                    return NSURL(string: "http://www.codingnext.com")!
                }
            }
        }
    }
}

func test_model (){
    /// json
    CXApi.Home.index
        .getJsonPromise(["a":1])
        .then { (json) in
            debugPrint(json)
        }
        .error { (error) in
            debugPrint(error)
    }
    /// HomeModel
    CXApi.Home.index
        .getModelPromise(["a":1])
        .then { (m:HomeModel)in
            debugPrint(m)
        }
        .error { (error) in
            debugPrint(error)
    }
    
    
}