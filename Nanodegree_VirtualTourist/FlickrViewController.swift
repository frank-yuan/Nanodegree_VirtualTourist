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
    private var contentCommandQueue = [ContentChangeCommand]()
    
    
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
        
        let fr = NSFetchRequest(entityName: Constants.EntityName.FlickrPhoto)
        fr.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        let pred = NSPredicate(format: "rMapCoord = %@", argumentArray: [self.mapCoordinate!])
        fr.predicate = pred
        // Create the FetchedResultsController
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fr,
                                                                   managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        if (fetchedResultsController?.fetchedObjects?.count > 0) {
            self.collectionView.reloadData()
        } else if mapCoordinate?.downloading == false {
            mapCoordinate?.downloadPhotos({ (error) in
                self.collectionView.reloadData()
            })
        }
        
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
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
    
    @IBAction func onButtonPressed() {
        if (collectionView.indexPathsForSelectedItems()?.count > 0) {
            CoreDataHelper.performCoreDataBackgroundOperation({ (workerContext) in
                var ids = [String]()
                for index in self.collectionView.indexPathsForSelectedItems()! {
                    if let cell = self.collectionView.cellForItemAtIndexPath(index) as? FlickrCollectionViewCell {
                        ids.append((cell.flickrPhoto?.id)!)
                    }
                }
                let fr = NSFetchRequest(entityName: "FlickrPhoto")
                fr.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                
                let pred = NSPredicate(format: "id = %@", argumentArray: ids)
                fr.predicate = pred
                let fetchResults = try! workerContext.executeFetchRequest(fr)
                // TODO: Why only one result
                for fetchResult in fetchResults {
                    workerContext.deleteObject(fetchResult as! NSManagedObject)
                }
            })
        }
        else {
            mapCoordinate?.downloadPhotos({ (error) in
                
            })
        }
        
    }
    func resizeCollectionLayout() {
        let count:CGFloat = view.frame.width > view.frame.height ? 5.0 : 3.0
        let size:CGFloat = (view.frame.width - (count + 1) * cellSpacing) / count
        collectionViewFlowLayout.itemSize = CGSize(width: size, height: size)
    }
    
    func updateButtonText() {
        newCollectionButton!.setTitle(collectionView.indexPathsForSelectedItems()?.count > 0 ? "Delete" :"New Collection", forState: .Normal)
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
        
        noImageLabel.hidden = true
        
        let fp = fetchedResultsController!.objectAtIndexPath(indexPath) as! FlickrPhoto
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(collectionCellIdentifier, forIndexPath: indexPath) as! FlickrCollectionViewCell
        
        cell.flickrPhoto = fp
        
        cell.selectedBackgroundView?.backgroundColor = UIColor.greenColor()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        updateButtonText()
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor.greenColor()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        updateButtonText()
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor.blueColor()
    }
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
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
    
    
    struct ContentChangeCommand {
        let type : NSFetchedResultsChangeType
        let indexPath : NSIndexPath?
        let newIndexPath : NSIndexPath?
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
            
           contentCommandQueue.append(ContentChangeCommand(type: type, indexPath: indexPath, newIndexPath: newIndexPath))
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({ 
            for command in self.contentCommandQueue {
                
                
                switch(command.type){
                    
                case .Insert:
                    self.collectionView.insertItemsAtIndexPaths([command.newIndexPath!])
                    
                case .Delete:
                    self.collectionView.deleteItemsAtIndexPaths([command.indexPath!])
                    
                case .Update:
                    self.collectionView.reloadItemsAtIndexPaths([command.indexPath!])
                    
                case .Move:
                    self.collectionView.deleteItemsAtIndexPaths([command.indexPath!])
                    self.collectionView.insertItemsAtIndexPaths([command.newIndexPath!])
                }
            }
            }, completion: nil)
        contentCommandQueue.removeAll()
        collectionView.reloadData()
    }
}