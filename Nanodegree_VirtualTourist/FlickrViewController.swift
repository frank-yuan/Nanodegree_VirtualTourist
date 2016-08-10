//
//  FlickrViewController.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/8/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import UIKit
import MapKit

class FlickrViewController: UIViewController {
    
    @IBOutlet weak var mapView : MKMapView!
    
    private let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.112872, longitudeDelta: 0.109863)
    
    var mapCoordinate : MapCoordinate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        let coordinate = mapCoordinate!.toLocationCoordinate2D()
        
        mapView.setCenterCoordinate(coordinate, animated: true)
        mapView.setRegion(MKCoordinateRegion(center: coordinate, span: coordinateSpan), animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
}
