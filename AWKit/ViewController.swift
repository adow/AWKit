//
//  ViewController.swift
//  AWHttpRequest
//
//  Created by 秦 道平 on 16/5/6.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var testImageView : UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        self.test_promise()
//        self.test_http_promise()
//        let url = NSURL(string: "http://7vihfk.com1.z0.glb.clouddn.com/photo-1457369804613-52c61a468e7d.jpeg")!
//        let url = NSURL(string: "http://img.wifiwx.com/material/card/img/710x236/2016/05/20160513081416vmo7.jpg")!
//        let url = NSURL(string: "http://img.wifiwx.com/material/video_split/img/710x236/2016/05/05b33aa5eb85ec31674a7e756abcd246.png")!
//        let url = NSURL(string: "https://images.unsplash.com/photo-1460500063983-994d4c27756c?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&s=27c2758e7f3aa5b8b3a4a1d1f1812310")!
        let url = NSURL(string: "https://images.unsplash.com/photo-1422393462206-207b0fbd8d6b?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&s=b09f84e8e8fd58ee91faf817b9f903d7")!
//        let url = NSURL(string: "https://drscdn.500px.org/photo/153370295/q%3D50_w%3D140_h%3D140/6edc2bbf7b2ce954b3dc3f7197cdf88d?v=3")!
        self.testImageView.aw_downloadImageURL_loading(url, showLoading: true) { (_, _) in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}
extension ViewController {
    @IBAction func onButton(sender:UIButton!){
//        test_awhttprequest()
        self.test_request()
    }
    func test_request(){
        let url = NSURL(string: "https://www.google.com")!
//        let url = NSURL(string: "http://www.codingnext.com")!
        AWHttpRequest.get(url)
            .responseString({ (str) in
                debugPrint(str)
                }) { (error) in
                    
        }
    }
}
extension ViewController {
    
    func test_http_promise() {
        let queue = NSOperationQueue()
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.timeoutIntervalForRequest = 3.0
        AWPromise<NSData> (block:{ (resolve, reject) in
            let session = NSURLSession(configuration: sessionConfiguration, delegate: nil, delegateQueue: queue)
            let task = session.dataTaskWithURL(NSURL(string:"https://www.zhihu.com")!, completionHandler: { (data, response, error) in
                dispatch_sync(dispatch_get_main_queue(), { 
                    if let error = error {
                        reject(error)
                    }
                    else if let data = data {
                        resolve(data)
                    }    
                })
                
                
            })
            task.resume()
        })
        .then { (data) -> () in
            print("First Request")
            let str = String(data: data, encoding: NSUTF8StringEncoding)
            print(str)
        }
        .then { () -> AWPromise<NSData> in
            return AWPromise<NSData>(block: { (resolve, reject) in
                let session = NSURLSession(configuration: sessionConfiguration, delegate: nil, delegateQueue: queue)
                let task = session.dataTaskWithURL(NSURL(string:"https://www.apple.com")!, completionHandler: { (data, response, error) in
                    dispatch_sync(dispatch_get_main_queue(), { 
                        if let error = error {
                            reject(error)
                        }
                        else if let data = data {
                            resolve(data)
                        }    
                    })
                })
                task.resume()
            })
        }
        .then { (data) -> String in
            let str = String(data: data, encoding: NSUTF8StringEncoding)!
            return str
        }
        .then { (str) -> () in
            print("Second Request")
            print(str)
            print("All Completed")
        }
        .error { (error) in
            debugPrint(error)
        }
    }
    func test_promise() {
        func test() -> AWPromise<NSData> {
            return AWPromise<NSData>(block: { (resolve, reject) in
                print("a")
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    print("wait")
                    NSThread.sleepForTimeInterval(3.0)
                    dispatch_async(dispatch_get_main_queue(), {
                        print("start resolve")
                        resolve(NSData())
                    })
                    
                })
            })
        }
        
        AWPromise<NSData>(block: { (resolve, reject) in
            print("start")
//            resolve(NSData())
//            let error = NSError(domain: "test error", code: 0, userInfo: nil)
//            reject(error)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                print("wait")
                NSThread.sleepForTimeInterval(3.0)
                dispatch_sync(dispatch_get_main_queue(), {
                    print("wait complete")
//                    resolve(NSData())
                    let error = NSError(domain: "test error", code: 1, userInfo: nil)
                    reject(error)
                })
                
            })
        })
            .then { (data) -> [String:String] in
                throw AWPromiseError.PromiseError("1 error")
//                return ["aaa":"bbb"]
            }
            .then { (d) -> AWPromise<String> in
                print(d)
                print("start 2")
                throw AWPromiseError.PromiseError("2 error")
//                return AWPromise<String>(block: { (resolve, reject) in
//                    print("wait 2")
//                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
//                        NSThread.sleepForTimeInterval(3.0)
//                        dispatch_async(dispatch_get_main_queue(), {
//                            print("wait 2 complete")
////                            resolve("ok")
//                            reject(NSError(domain: "2 error", code: 0, userInfo: nil))
//                        })
//                    })
////                    resolve("ok")
////                    reject(NSError(domain: "2 error", code: 0, userInfo: nil))
//                })
            }
            .then{ (str) -> () in
                print(str)
                print("done")
            }
            .error { (error) in
                print("\(error.domain)")
        }
    }
}
