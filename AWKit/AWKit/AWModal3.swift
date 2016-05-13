//
//  AWModal3.swift
//  AWHttpRequest
//
//  Created by 秦 道平 on 16/5/10.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation

class AWPromiseApiObject{
    var url: NSURL!
    var parameters: [String : AnyObject]! = [:]
    var headers: [String : String]? = nil
    init(url:NSURL,
         parameters:[String:AnyObject] = [:],
         headers: [String:String]? = nil) {
        self.url = url
        self.parameters = parameters
        self.headers = headers
    }
}
extension AWPromiseApiObject {
    func getJsonPromise() -> AWPromise<[String:AnyObject]> {
        return AWHttpRequest.get(url, params: parameters, headers: headers).jsonPromise()
    }
    func postJsonPromise() -> AWPromise<[String:AnyObject]> {
        return AWHttpRequest.post(url, params: parameters, headers: headers).jsonPromise()
    }
    func putJsonPromise() -> AWPromise<[String:AnyObject]> {
        return AWHttpRequest.put(url, params: parameters, headers: headers).jsonPromise()
    }
    func getModalPromise<T:AWJsonModel>() -> AWPromise<T> {
        return AWPromise<T>(block: { (resolve, reject) in
            self.getJsonPromise()
                .then({ (json) in
                    let t = T.init(dict: json)
                    resolve(t)
                })
                .error({ (error) in
                    reject(error)
                })
        })
    }
    func postModalPromise<T:AWJsonModel>() -> AWPromise<T> {
        return AWPromise<T>(block: { (resolve, reject) in
            self.postJsonPromise()
                .then({ (json) in
                    let t = T.init(dict: json)
                    resolve(t)
                })
                .error({ (error) in
                    reject(error)
                })
        })
    }
    func putModalPromise<T:AWJsonModel>() -> AWPromise<T> {
        return AWPromise<T>(block: { (resolve, reject) in
            self.putJsonPromise()
                .then({ (json) in
                    let t = T.init(dict: json)
                    resolve(t)
                })
                .error({ (error) in
                    reject(error)
                })
        })
    }
}
// MARK: - Test
class Home : AWPromiseApiObject{
    static func index(parameters:[String:AnyObject] = [:],
                      headers:[String:String]? = nil) -> Home {
        return Home(url: NSURL(string:"")!,
                    parameters: parameters,
                    headers: headers)
    }
}
struct HomeModel : AWJsonModel {
    var name: String
    init(dict: [String : AnyObject]) {
        self.name = ""
    }
}
func test_promise_object() {
    /// Json
    Home.index(["a":1])
        .getJsonPromise()
        .then { (json) in
            debugPrint(json)
        }
        .error { (error) in
            debugPrint(error)
    }
    /// HomeModel
    Home.index(["a":1])
        .getModalPromise()
        .then { (m:HomeModel) -> () in
            debugPrint(m)
        }
        .error { (error) in
            debugPrint(error)
    }
    
}
