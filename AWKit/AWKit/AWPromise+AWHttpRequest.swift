//
//  AWPromise+AWHttpRequest.swift
//  AWHttpRequest
//
//  Created by 秦 道平 on 16/5/10.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation

extension AWHttpRequest {
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