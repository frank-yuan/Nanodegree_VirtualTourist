//
//  HttpService.swift
//  Nanodegree_OnTheMap
//
//  Created by Xuan Yuan (Frank) on 7/26/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import Foundation


enum NetworkError : Int {
    case NoError = 0,
    RequestError,
    ResponseWrongStatus,
    NoData,
    ParseJSONError,
    ParseHttpBodyError
}

protocol EndPointConfig {
    var ApiScheme: String { get }
    var ApiHost: String { get }
    var ApiPath: String { get }
}

class HttpRequest : NSObject {
    enum HttpMethod : String{
        case GET = "GET"
        case POST = "POST"
        case DELETE = "DELETE"
        case PUT = "PUT"
    }
    
    private let method:HttpMethod
    private let url:NSURL
    private var header = [String:String]()
    private var data = [String:AnyObject]()
    
    init(url:NSURL, method:HttpMethod = .GET) {
        self.url = url
        self.method = method
    }
    
    func addData(key:String, value:AnyObject) {
        data[key] = value
    }
    
    func addHeader(header:[String:String]) {
        for entry in header {
            self.header[entry.0] = entry.1
        }
    }
}

private extension HttpRequest {
    func toNSURLReuqest() -> NSURLRequest {
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method.rawValue
        
        for headerEntry in header {
            request.setValue(headerEntry.1, forHTTPHeaderField: headerEntry.0)
        }
        
        if data.count > 0 {
            do {
                let httpBody = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions.PrettyPrinted)
                request.HTTPBody = httpBody
            } catch {
                print("Error parsing json from data")
            }
        }
        
        return request
    }
}

class HttpService : NSObject {

    static func service(request:HttpRequest, completeHandler:(NSData?, NetworkError) -> Void) -> Void {
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request.toNSURLReuqest()) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                performUIUpdatesOnMain {
                    completeHandler(nil, NetworkError.RequestError)
                }
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                performUIUpdatesOnMain {
                    completeHandler(data, NetworkError.ResponseWrongStatus)
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                performUIUpdatesOnMain {
                    completeHandler(nil, NetworkError.NoData)
                }
                return
            }
            
            performUIUpdatesOnMain {
                completeHandler(data, NetworkError.NoError)
            }
        }
        task.resume()
    }
}
