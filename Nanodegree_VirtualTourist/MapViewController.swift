//
//  MapViewController.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/8/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView : MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress))
        mapView.addGestureRecognizer(gesture)
        // Do any additional setup after loading the view.
    }


    // MARK: MKMapViewDelegate implements
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
        }
        //pinView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAnnotationTouched)))
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // deselect so that we can select again when we backk from next view
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        performSegueWithIdentifier("showFlickr", sender: self)
    }
    
    // MARK: Private methods
    
    func handleMapLongPress(gestureRecognizer:UIGestureRecognizer) {
        if (gestureRecognizer.state == .Began)
        {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }

    //func handleAnnotationTouched(gestureRecognizer:UIGestureRecognizer) {
    //    if let annotationView = gestureRecognizer.view as? MKAnnotationView {
    //        print((annotationView.annotation?.description)!)
    //    }
    //}
}
