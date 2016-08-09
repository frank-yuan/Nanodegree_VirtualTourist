//
//  MapViewController.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/8/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView : MKMapView!
    
    var fetchedResultsController : NSFetchedResultsController?{
        didSet{
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            reloadAnnotations()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress))
        mapView.addGestureRecognizer(gesture)
        
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest(entityName: "MapCoordinate")
        fr.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: true)]
        //    NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr,
                                            managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
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
            if let context = fetchedResultsController?.managedObjectContext{
                
                // Just create a new note and you're done!
                let _ = MapCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude, context: context)
            }
//            let annotation = MKPointAnnotation()
//            
//            annotation.coordinate = coordinate
//            mapView.addAnnotation(annotation)
        }
    }
    
    func reloadAnnotations() {
        
        if let fc = fetchedResultsController{
            for obj in fc.fetchedObjects! {
                if let coord = obj as? MapCoordinate {
                    addAnnotation(Double(coord.latitude!), longitude: Double(coord.longitude!))
                }
            }
        }
    }
    
    func addAnnotation(latitude:Double, longitude:Double)
    {
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.addAnnotation(annotation)
    }

    //func handleAnnotationTouched(gestureRecognizer:UIGestureRecognizer) {
    //    if let annotationView = gestureRecognizer.view as? MKAnnotationView {
    //        print((annotationView.annotation?.description)!)
    //    }
    //}
}

// MARK:  - Fetches
extension MapViewController{
    
    func executeSearch(){
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }catch let e as NSError{
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

extension MapViewController : NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
        
        if let coordinate = anObject as? MapCoordinate {
            
            switch(type){
                
            case .Insert:
                addAnnotation(Double(coordinate.latitude!), longitude: Double(coordinate.longitude!))
                
            default:
                break
            }
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    }
}
