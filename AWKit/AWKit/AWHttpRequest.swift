//
//  AWHttpRequest.swift
//  AWHttpRequest
//
//  Created by 秦 道平 on 16/5/6.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation

typealias JSON = [String:AnyObject]
typealias DataCallback = (NSData) -> ()
typealias StringCallback = (String) -> ()
typealias JsonCallback = (JSON) ->()
typealias ResponseCallback = (AWHttpResponse<NSData>) -> ()
typealias ErrorCallback = (NSError) -> ()

// MARK: - AWHttpConfiguration
private let _sharedConfiguration = AWHttpConfiguration(name:"shared")
class AWHttpConfiguration {
    /// 队列任务
    var sessionQueue = NSOperationQueue()
    var sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    static var sharedConfiguration : AWHttpConfiguration! {
        return _sharedConfiguration
    }
    init(name:String) {
        /// queue
        self.sessionQueue.name = "adow.awhttpmanager.session-queue.\(name)"
        self.sessionQueue.maxConcurrentOperationCount = 6
        
        /// 10 MB Cache on Memory and Disk
        self.sessionConfiguration.URLCache =
            NSURLCache(memoryCapacity: 10 * 1024 * 1024,
                                  diskCapacity: 10 * 1024 * 1024,
                                  diskPath: "adow.awhttpmanager.urlcache.\(name)")
    }
    
    func makeSessionFromConfiguration() -> NSURLSession {
        return
            NSURLSession(configuration: self.sessionConfiguration,
                         delegate: nil,
                         delegateQueue: self.sessionQueue)
    }
}

// MARK: - AWHttpResponse
struct AWHttpResponse<T> {
    var request : AWHttpRequest!
    var result : AWResult<T>!
}

// MARK: - AWHttpRequest
// MARK: File
struct AWPostFileItem {
    let name : String
    let filename : String?
    let filedata : NSData?
}
// MARK: Method
enum AWHttpMethod :String {
    case GET
    case POST
    case PUT
    case DELETE
}
// MARK: Request
class AWHttpRequest : NSObject{
    var headers : [String:String]? {
        didSet {
            self.headers?.forEach({ (k,v) in
                self.rawRequest?.setValue(v, forHTTPHeaderField: k)
            })
        }
    }
    var params : [String:AnyObject]?
    var rawRequest : NSMutableURLRequest!
    var requestConfiguration = AWHttpConfiguration.sharedConfiguration
    func setRequestConfiguration(configuration:AWHttpConfiguration) -> AWHttpRequest{
        self.requestConfiguration = configuration
        return self
    }
    private init (url: NSURL!,
                  method : String = "GET",
                  params:[String:AnyObject]? = nil,
                  headers : [String:String]? = nil) {
        super.init()
        self.params = params
        if method == "GET" {
            if let q = self.query {
                var path = url.absoluteString
                if path.containsString("?") {
                    path += q
                }
                else {
                    path += "?" + q
                }
                let q_url = NSURL(string: path)!
                rawRequest = NSMutableURLRequest(URL: q_url)
            }
            else {
                rawRequest = NSMutableURLRequest(URL: url)
            }
        }
        else {
            rawRequest = NSMutableURLRequest(URL: url)
            if let body = self.plainBody {
                rawRequest.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
            }
        }
        self.headers = headers
        
    }
    convenience init(method:AWHttpMethod, url: NSURL,
         params:[String:AnyObject]? = nil,
         headers:[String:String]? = nil) {
        self.init(url: url, method: method.rawValue, params:params,headers: headers)
    }
    // MARK: get/post/put/delete/postFile
    static func get (url:NSURL,
                     params:[String:AnyObject]? = nil,
                     headers:[String:String]? = nil) -> AWHttpRequest{
        let request = AWHttpRequest(url: url,
                                    params: params,
                                    headers: headers)
        return request
    }
    static func post(url:NSURL,
                     params:[String:AnyObject]? = nil,
                     headers:[String:String]? = nil) -> AWHttpRequest {
        return AWHttpRequest(url: url, method: "POST", params: params, headers: headers)
    }
    static func put(url:NSURL,
                     params:[String:AnyObject]? = nil,
                     headers:[String:String]? = nil) -> AWHttpRequest {
        return AWHttpRequest(url: url, method: "PUT", params: params, headers: headers)
    }
    static func delete(url:NSURL,
                     params:[String:AnyObject]? = nil,
                     headers:[String:String]? = nil) -> AWHttpRequest {
        return AWHttpRequest(url: url, method: "DELETE", params: params, headers: headers)
    }
    static func postFile(url:NSURL,
                         files postFileItems:[AWPostFileItem]? = nil,
                         params:[String:AnyObject]? = nil,
                         headers:[String:String]? = nil) -> AWHttpRequest {
        let request = AWHttpRequest(url: url, method: "POST", params: params, headers: headers)
        /// 需要上传文件
        if let postFileItems = postFileItems {
            let boundary = NSUUID().UUIDString
            let content_type = "multipart/form-data; boundary=\(boundary)"
            request.addHeader("Content-Type", value: content_type)
            let data = NSMutableData()
            /// 普通参数
            if let params = params {
                params.forEach({ (k,v) in
                    let header = "--\(boundary)\r\n"
                    data.appendData(header.dataUsingEncoding(NSUTF8StringEncoding)!)
                    let key = "Content-Disposition: form-data;name=\"\(k)\"\r\n\r\n"
                    data.appendData(key.dataUsingEncoding(NSUTF8StringEncoding)!)
                    data.appendData(v.dataUsingEncoding(NSUTF8StringEncoding)!)
                    data.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                })
            }
            /// 文件参数
            postFileItems.forEach({ (file) in
                guard let file_data = file.filedata else {
                   return
                }
                let header = "--\(boundary)\r\n"
                data.appendData(header.dataUsingEncoding(NSUTF8StringEncoding)!)
                let key = "Content-Disposition: form-data; name = \"\(file.name)\"; filename = \"\(file.filename)\"\r\n"
                data.appendData(key.dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData("Content-Type: application/octet-stream\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData(file_data)
                data.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            })
            request.rawRequest.HTTPBody = data
        }
        
        return request
    }
}
// MARK: Headers, query, body
extension AWHttpRequest {
    func addHeader(key:String, value:String) {
        self.rawRequest.addValue(value, forHTTPHeaderField: key)
    }
    var query:String? {
        if let params = self.params {
            let q = params.reduce("", combine: { (q, dict) -> String in
                let (k,v) = dict
                return q + "\(k)=\(v)&"
            })
            return q
        }
        else {
            return nil
        }
    }
    /// httpBody
    var plainBody:String? {
        if let params = self.params {
            return params.reduce("", combine: { (q, dict) -> String in
                let (k,v) = dict
                let v_encoded = v.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
                return q + "\(k)=\(v_encoded)&"
            })
        }
        return nil
    }
}
// MARK: Response
extension AWHttpRequest {
    /// common response
    private func response(responseCallback : ResponseCallback) -> NSURLSessionTask{
        let session = self.requestConfiguration.makeSessionFromConfiguration()
        let task = session.dataTaskWithRequest(self.rawRequest)
            { (data, response, error) in
                dispatch_sync(dispatch_get_main_queue()){
                    let result : AWResult<NSData>
                    if let error = error {
                        result = AWResult<NSData>.Error(error)
                    }
                    else if let data = data {
                        result = AWResult.Success(data)
                    }
                    else {
                        let error = NSError(domain: "empty data", code: 0, userInfo: nil)
                        result = AWResult<NSData>.Error(error)
                    }
                    let r = AWHttpResponse(request: self, result: result)
                    responseCallback(r)    
                }
                
            }
        task.resume()
        return task
    }
    /// data
    func responseData(dataCallback : DataCallback,
            onError errorBlock : ErrorCallback? = nil) -> NSURLSessionTask{
        return self.response { (response) in
            switch response.result! {
            case .Error(let error):
                errorBlock?(error)
            case .Success(let data):
                dataCallback(data)
            }
        }
        
    }
    /// String
    func responseString(stringCallback : StringCallback,
            onError errorBlock:ErrorCallback? = nil) -> NSURLSessionTask {
        return self.response({ (response) in
            switch response.result! {
            case .Error(let error):
                errorBlock?(error)
            case .Success(let data):
                let str = String(data: data, encoding: NSUTF8StringEncoding) ?? ""
                stringCallback(str)
            }
        })
    }
    /// JSON
    func responseJSON(jsonCallback : JsonCallback,
                      onError errorBlock: ErrorCallback? = nil) -> NSURLSessionTask {
        return self.response({ (response) in
            switch response.result! {
            case .Success(let data):
                if let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)) as? [String:AnyObject] {
                    jsonCallback(json)
                }
                else {
                    let error = NSError(domain: "Not JSON Object", code: 0, userInfo: nil)
                    errorBlock?(error)
                }
            case .Error(let error):
                errorBlock?(error)
            }
        })
    }
}
// MARK: - test
func test_awhttprequest() {
    AWHttpConfiguration.sharedConfiguration.sessionConfiguration.requestCachePolicy = .ReturnCacheDataElseLoad
    AWHttpRequest
        .get(NSURL(string: "http://weixin.lvlianba.com/debug")!,params: ["a":"1"])
        .responseString({ (str) in
            debugPrint(str)
        }) { (error) in
            debugPrint(error)
    }
    
    AWHttpRequest(method: .GET, url: NSURL(string: "http://www.codingnext.com")!)
        .responseString({ (str) in
            debugPrint(str)
            }) { (error) in
                debugPrint(error)
    }
    
    /// configuration
    let configuraton = AWHttpConfiguration(name:"test")
    let r = AWHttpRequest.get(NSURL(string: "http://www.codingnext.com")!)
    r.requestConfiguration = configuraton
    r.responseString ({ (str) in
        debugPrint(str)
    })
   
    /// chainable configuration
    AWHttpRequest
        .get(NSURL(string: "http://www.codingnext.com")!)
        .setRequestConfiguration(configuraton)
        .responseString({ (str) in
            debugPrint(str)
            }) { (error) in
                debugPrint(error)
    }
    
}
