//
//  AWImageLoader.swift
//  AWHttpRequest
//
//  Created by 秦 道平 on 16/5/11.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation
import UIKit

typealias AWImageLoaderCallback = (UIImage,NSURL)->()
typealias AWImageLoaderCallbackList = [AWImageLoaderCallback]

private let _sharedImageLoader = AWImageLoader()

class AWImageLoader : NSObject {
    /// 回调列表
    var fetchList : [String:AWImageLoaderCallbackList] = [:]
    /// 用来操作回调列表的锁
    var fetchList_operation_queue : dispatch_queue_t = dispatch_queue_create("adow.adimageloader.fetchlist_operation_queue", DISPATCH_QUEUE_CONCURRENT)
    /// 用来编码图片的进程
    var imageDecode_queue : dispatch_queue_t =
        dispatch_queue_create("adow.adimageloader.decode_queue", DISPATCH_QUEUE_CONCURRENT)
    /// 用来保存生成好图片
    var fastCache : NSCache!
    /// 配置 request
    var requestConfiguration : AWHttpConfiguration!
    static var sharedImageLoader : AWImageLoader{
        return _sharedImageLoader
    }
    override private init() {
        super.init()
        fastCache = NSCache()
        fastCache.totalCostLimit = 10 * 1024 * 1024
        
        /// AWHttpRequest
        self.requestConfiguration = AWHttpConfiguration(name: "adimageloader")
        self.requestConfiguration.sessionQueue.maxConcurrentOperationCount = 10
        self.requestConfiguration.sessionConfiguration.requestCachePolicy = .ReturnCacheDataElseLoad
        self.requestConfiguration.sessionConfiguration.timeoutIntervalForRequest = 3
        self.requestConfiguration.sessionConfiguration.URLCache = NSURLCache(memoryCapacity: 10 * 1024 * 1024,
                       diskCapacity: 30 * 1024 * 1024,
                       diskPath: "adow.awhttpmanager.urlcache.adimageloader")
    }
}
extension AWImageLoader {
    func readFetch(key:String, callback:(AWImageLoaderCallbackList?) -> ()) {
        dispatch_barrier_async(self.fetchList_operation_queue) { 
            let f_list = self.fetchList[key]
            callback(f_list)
        }
    }
    func addFetch(key:String, callback:AWImageLoaderCallback) {
        dispatch_barrier_async(self.fetchList_operation_queue) { 
            let f_list = self.fetchList[key]
            if var f_list = f_list {
                f_list.append(callback)
                self.fetchList[key] = f_list
            }
            else {
                self.fetchList[key] = [callback,]
            }
        }
    }
    func removeFetch(key:String) {
        dispatch_barrier_async(self.fetchList_operation_queue) { 
            self.fetchList.removeValueForKey(key)
        }
    }
    func clearFetch() {
        dispatch_barrier_async(self.fetchList_operation_queue) { 
            self.fetchList.removeAll()
        }
    }
}
extension AWImageLoader {
    func downloadImage(url:NSURL, callback:AWImageLoaderCallback) -> NSURLSessionTask?{
        let fetch_key = url.absoluteString
        /// fast cache
        if let cached_image = self.fastCache.objectForKey(fetch_key) as? UIImage {
            self.readFetch(fetch_key, callback: { (f_list) in
                self.removeFetch(fetch_key)
                dispatch_sync(dispatch_get_main_queue(), {
                    if let f_list = f_list{
                        NSLog("fastCache:%d callback for %@", f_list.count,url.absoluteString)
                        f_list.forEach({ (f) in
                            f(cached_image,url)
                        })
                    }
                    else {
                        NSLog("fastCache:no callback for %@",url.absoluteString)
                    }
                })
                
            })
        }
        /// origin
        self.addFetch(fetch_key, callback: callback)
        /// AWHttpRequest
        /// 用来回调到外部去
        let f_callback = {(data:NSData) -> () in
            dispatch_async(self.imageDecode_queue, {
                if let image = UIImage(data: data) {
//                    self.fastCache.setObject(image, forKey: fetch_key)
                    self.readFetch(fetch_key, callback: { (f_list) in
                        self.removeFetch(fetch_key)
                        dispatch_sync(dispatch_get_main_queue(), {
                            if let f_list = f_list{
                                NSLog("origin %d callback for %@", f_list.count,url.absoluteString)
                                f_list.forEach({ (f) in
                                    f(image,url)
                                })
                            }
                            else {
                                NSLog("origin no callback for %@",url.absoluteString)
                            }
                        })
                    })
                }
            })
        }
        let task = AWHttpRequest.get(url)
            .setRequestConfiguration(self.requestConfiguration)
            .responseData({ (data) in
                f_callback(data)
                }) { (error) in
                    f_callback(NSData()) /// 出错的时候会返回一个空的图片
        }
        return task
        
    }
}
extension AWImageLoader {
    func clearCache() {
        self.fastCache.removeAllObjects()
        self.requestConfiguration.sessionConfiguration.URLCache?.removeAllCachedResponses()
    }
}
func aw_download_image(url:NSURL!,
                       completionBlock:AWImageLoaderCallback) -> NSURLSessionTask?{
    return AWImageLoader.sharedImageLoader.downloadImage(url, callback: completionBlock)
}