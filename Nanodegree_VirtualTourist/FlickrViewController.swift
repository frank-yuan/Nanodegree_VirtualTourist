//
//  FlickrViewController.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/8/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class FlickrViewController: UIViewController {
    
    @IBOutlet weak var mapView : MKMapView!
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout : UICollectionViewFlowLayout!
    @IBOutlet weak var noImageLabel : UILabel!
    @IBOutlet weak var newCollectionButton : UIButton!
    
    
    private let collectionCellIdentifier = "FlickrImageCell"
    private let cellSpacing:CGFloat = 0.5
    
    
    private let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.112872, longitudeDelta: 0.109863)
    
    var mapCoordinate : MapCoordinate?
    
    var fetchedResultsController : NSFetchedResultsController?{
        didSet{
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            //collectionView.reloadData()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack
        
        let fr = NSFetchRequest(entityName: "FlickrPhoto")
        fr.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        let pred = NSPredicate(format: "rMapCoord = %@", argumentArray: [self.mapCoordinate!])
        fr.predicate = pred
        // Create the FetchedResultsController
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fr,
                                                                   managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        if (fetchedResultsController?.fetchedObjects?.count > 0) {
            self.noImageLabel.hidden = true
            self.collectionView.reloadData()
        } else {
            MapCoordinate.backgroundDownloadForMapCoordinate(mapCoordinate!, context: stack.context) { (result, error) in
                if (error == NetworkError.NoError) {
                    if (self.fetchedResultsController?.fetchedObjects?.count > 0) {
                        self.noImageLabel.hidden = true
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        let coordinate = mapCoordinate!.toLocationCoordinate2D()
        
        mapView.setCenterCoordinate(coordinate, animated: true)
        mapView.setRegion(MKCoordinateRegion(center: coordinate, span: coordinateSpan), animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        collectionViewFlowLayout.minimumInteritemSpacing = cellSpacing
        collectionViewFlowLayout.minimumLineSpacing = cellSpacing
        resizeCollectionLayout()
        
    }
    
    func resizeCollectionLayout() {
        let count:CGFloat = view.frame.width > view.frame.height ? 5.0 : 3.0
        let size:CGFloat = (view.frame.width - (count + 1) * cellSpacing) / count
        collectionViewFlowLayout.itemSize = CGSize(width: size, height: size)
    }
}

extension FlickrViewController : UICollectionViewDelegate, UICollectionViewDataSource{
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var result = 0;
        if let fc = fetchedResultsController{
            result = fc.sections![section].numberOfObjects
        }
        return result
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let fp = fetchedResultsController!.objectAtIndexPath(indexPath) as! FlickrPhoto
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(collectionCellIdentifier, forIndexPath: indexPath)
        
        if let imageView = cell.viewWithTag(100) as? UIImageView{
            if (fp.image != nil) {
                imageView.image = UIImage(data: fp.image!)
            }
            if let labelView = cell.viewWithTag(200) as? UILabel{
                labelView.hidden = fp.image != nil
            }
        }
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    
}

// MARK:  - Fetches
extension FlickrViewController{
    
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

// MARK:  - Delegate
extension FlickrViewController: NSFetchedResultsControllerDelegate{
    
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        //collectionView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            let set = NSIndexSet(index: sectionIndex)
            
            switch (type){
                
            case .Insert:
                collectionView.insertSections(set)
                
            case .Delete:
                collectionView.deleteSections(set)
                
            default:
                // irrelevant in our case
                break
                
            }
    }
    
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            
            
            switch(type){
                
            case .Insert:
                collectionView.insertItemsAtIndexPaths([newIndexPath!])
                
            case .Delete:
                collectionView.deleteItemsAtIndexPaths([indexPath!])
                
            case .Update:
                collectionView.reloadItemsAtIndexPaths([indexPath!])
                
            case .Move:
                collectionView.deleteItemsAtIndexPaths([indexPath!])
                collectionView.insertItemsAtIndexPaths([newIndexPath!])
            }
            
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        //tableView.endUpdates()
    }
}