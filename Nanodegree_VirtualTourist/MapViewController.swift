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

    enum State{
        case Place
        case Delete
    }
    
    @IBOutlet weak var mapView : MKMapView!
    @IBOutlet weak var barItem: UIBarButtonItem!
    @IBOutlet weak var deleteLabel: UILabel!
    
    private var currentState = State.Place
    
    var fetchedResultsController : NSFetchedResultsController?{
        didSet{
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            reloadAnnotations()
        }
    }
    
    // MARK: UIViewcontroller overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        barItem.title = "Delete"

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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let annotation = mapView.selectedAnnotations.last as? CoreDataPointAnnotation {
            if let vc = segue.destinationViewController as? FlickrViewController {
                vc.mapCoordinate = annotation.data as? MapCoordinate
            }
        
            mapView.deselectAnnotation(annotation, animated: false)
        }
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
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if currentState == .Delete {
            
            if let annotation = view.annotation as? CoreDataPointAnnotation,
                context = fetchedResultsController?.managedObjectContext,
                coord = annotation.data as? MapCoordinate{
                context.deleteObject(coord)
                removeAnnotation(coord)
            }
            
        } else {
            // deselect so that we can select again when we backk from next view
            
            performSegueWithIdentifier("showFlickr", sender: self)
        }
    }
    
    // MARK: IBActions
    @IBAction func onDelete() {
        if (currentState == .Place) {
            switchState(.Delete)
            barItem.title = "Cancel"
        } else {
            switchState(.Place)
            barItem.title = "Delete"
            
        }
    }
    
    // MARK: Private methods
    
    func handleMapLongPress(gestureRecognizer:UIGestureRecognizer) {
        if (gestureRecognizer.state == .Began)
        {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            if let context = fetchedResultsController?.managedObjectContext{
                
                // Just create a new note and you're done!
                backgroundDownloadForMapCoordinate( MapCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude, context: context) )
            }
        }
    }
    
    func reloadAnnotations() {
        
        if let fc = fetchedResultsController{
            for obj in fc.fetchedObjects! {
                if let coord = obj as? MapCoordinate {
                    addAnnotation(coord)
                }
            }
        }
    }
    
    func addAnnotation(coord:MapCoordinate)
    {
        let latitude = Double(coord.latitude!)
        let longitude = Double(coord.longitude!)
        
        let annotation = CoreDataPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        annotation.data = coord
        mapView.addAnnotation(annotation)
    }

    func removeAnnotation(coord:MapCoordinate)
    {
        for annotation in mapView.annotations {
            if let anno = annotation as? CoreDataPointAnnotation,
                annoCoord = anno.data as? MapCoordinate
                where annoCoord == coord
            {
                mapView.removeAnnotation(anno)
                mapView.setNeedsDisplay()
                return
            }
        }
    }
    
    func switchState(state:State ) {
        if (currentState != state) {
            currentState = state
            onStateChanged(state)
        }
    }
    
    func onStateChanged(state:State) {
        UIView.animateWithDuration(0.3) {
            if (state == .Delete) {
                self.mapView.center.y -= 50
                self.deleteLabel.center.y -= 50
            } else {
                self.mapView.center.y += 50
                self.deleteLabel.center.y += 50
            }
        }
    }
    
    func backgroundDownloadForMapCoordinate(mapCoordinate: MapCoordinate) {
        performUpdatesUserInitiated { 
            mapCoordinate.downloading = true
            FlickrService.retrieveImagesByGeo(mapCoordinate.toLocationCoordinate2D()) { (result, error) in
                if (error == NetworkError.NoError) {
                    if let photos = result![Constants.FlickrResponseKeys.Photos],
                    photo = photos![Constants.FlickrResponseKeys.Photo] as? [AnyObject]
                    {
                        for photoData in photo {
                            if let url = photoData[Constants.FlickrResponseKeys.MediumURL] as? String{
                                performUIUpdatesOnMain {
                                    let flickrPhoto = FlickrPhoto(
                                        id: AnyObjectHelper.parseData(photoData, name: Constants.FlickrResponseKeys.ID, defaultValue: ""),
                                        url: url,
                                        mapCoordinate: mapCoordinate,
                                        context: self.fetchedResultsController!.managedObjectContext)
                                    flickrPhoto.startDownload()
                                }
                            }
                        }
                    }
                }
                mapCoordinate.downloading = false
            }
        }
    }
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
                addAnnotation(coordinate)
//                
//            case .Delete:
//                removeAnnotation(coordinate)
            default:
                break
            }
        }
        
    }
}
