//
//  FlickrService.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/9/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import UIKit
import MapKit

class FlickrService: NSObject {
    struct FlickrServiceConfig : ServiceConfig {
        var ApiHost: String { return Constants.Flickr.APIHost }
        var ApiScheme: String { return Constants.Flickr.APIScheme }
        var ApiPath: String { return Constants.Flickr.APIPath }
    }
    
    static func retrieveImagesByGeo(location:CLLocationCoordinate2D, completionHandler:(result:AnyObject?, error:NetworkError) -> Void) {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(location.latitude, longitude: location.longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.RecordPerPage
        ]
        
        if let url = HttpServiceHelper.buildURL(FlickrServiceConfig(), withPathExtension: "", queryItems: methodParameters)
        {
            
            let request = HttpRequest(url: url)
            HttpService.service(request) { (data, error) in
                if let data = data where error == NetworkError.NoError {
                    HttpServiceHelper.parseJSONResponse(data, error: error) { (result, error) in
                        completionHandler(result:result, error:error)
                    }
                }else {
                    completionHandler(result:data, error:error)
                }
            }
        }
    }

    static private func bboxString(latitude:Double, longitude:Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}
