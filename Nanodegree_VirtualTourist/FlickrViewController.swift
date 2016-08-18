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
    enum State{
        case Normal
        case Delete
    }
    
    @IBOutlet weak var mapView : MKMapView!
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout : UICollectionViewFlowLayout!
    @IBOutlet weak var noImageLabel : UILabel!
    @IBOutlet weak var newCollectionButton : UIButton!
    @IBOutlet weak var deleteBarItem : UIBarButtonItem!
    
    
    private let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.112872, longitudeDelta: 0.109863)
    private let collectionCellIdentifier = "FlickrImageCell"
    private let imagePreviewSegue = "showImage"
    private let cellSpacing:CGFloat = 0.5
    private var contentCommandQueue = [ContentChangeCommand]()
    private var currentState = State.Normal
    
    
    
    var mapCoordinate : MapCoordinate?
    
    var fetchedResultsController : NSFetchedResultsController?{
        didSet{
            fetchedResultsController?.delegate = self
            executeSearch()
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
        
        configureUI()
        
        if (fetchedResultsController?.fetchedObjects?.count > 0) {
            self.collectionView.reloadData()
        } else {
            newCollectionButton.enabled = false
            // find same object in background context
            let id = mapCoordinate?.id
            CoreDataHelper.performCoreDataBackgroundOperation({ (workerContext) in
                let mc = MapCoordinate.getObjectInContext(workerContext, byId: id!)
                if mc?.downloading == false {
                    mc?.downloadPhotosInPrivateQueue({ (error) in })
                }
            })
        }
        
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if collectionView.indexPathsForSelectedItems()?.count > 0 {
            let index = collectionView.indexPathsForSelectedItems()?.first
            let vc = segue.destinationViewController as! PageViewController
            vc.currentIndex = index?.row
            vc.fetchedResultsController = fetchedResultsController
        }
    }
    
    func resizeCollectionLayout() {
        let count:CGFloat = view.frame.width > view.frame.height ? 5.0 : 3.0
        let size:CGFloat = (view.frame.width - (count + 1) * cellSpacing) / count
        collectionViewFlowLayout.itemSize = CGSize(width: size, height: size)
    }
    
    func isDeleteState() -> Bool {
        return currentState == State.Delete
    }
    
    func configureUI() {
        noImageLabel.hidden = fetchedResultsController?.fetchedObjects!.count != 0
        deleteBarItem.title = isDeleteState() ? "Cancel" : "Delete"
        newCollectionButton!.setTitle( isDeleteState() ? "Delete" : "New Collection", forState: .Normal)
        newCollectionButton.enabled = false
        if isDeleteState() {
            newCollectionButton.enabled = true
        } else if !anyImageDownloading() && fetchedResultsController?.fetchedObjects?.count > 0 {
            newCollectionButton.enabled = true
        }
    }
    
    func onStateChanged() {
        
        switch currentState{
        case .Normal:
            if (collectionView.indexPathsForSelectedItems()?.count > 0) {
                let indexPaths = collectionView.indexPathsForSelectedItems()
                for ip in indexPaths! {
                    collectionView.deselectItemAtIndexPath(ip, animated: false)
                }
            }
            collectionView.allowsMultipleSelection = false
        case .Delete:
            collectionView.allowsMultipleSelection = true
            break
        }
    }
    
    func deleteSelectedImages() {
        if (collectionView.indexPathsForSelectedItems()?.count > 0) {
            var ids = [String]()
            for index in self.collectionView.indexPathsForSelectedItems()! {
                if let cell = self.collectionView.cellForItemAtIndexPath(index) as? FlickrCollectionViewCell {
                    ids.append((cell.flickrPhoto?.id)!)
                }
            }
            
            let workerContext = fetchedResultsController?.managedObjectContext
            let fr = NSFetchRequest(entityName: "FlickrPhoto")
            fr.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
            
            let pred = NSPredicate(format: "id IN %@", argumentArray: [ids])
            fr.predicate = pred
            let fetchResults = try! workerContext!.executeFetchRequest(fr)
            for fetchResult in fetchResults {
                workerContext!.deleteObject(fetchResult as! NSManagedObject)
            }
            CoreDataHelper.saveStack()
        }
    }
    
    
    func anyImageDownloading() -> Bool {
        for item in (fetchedResultsController?.fetchedObjects)! {
            if ((item as! FlickrPhoto).image == nil) {
                return true
            }
        }
        return false
    }
    
    @IBAction func onButtonPressed() {
        if isDeleteState() {
            deleteSelectedImages()
        } else {
            newCollectionButton.enabled = false
            mapCoordinate!.clearImages()
            let id = mapCoordinate?.id
            CoreDataHelper.performCoreDataBackgroundOperation { (workerContext) in
                let mc = MapCoordinate.getObjectInContext(workerContext, byId: id!)
                mc?.downloadPhotosInPrivateQueue({ (error) in })
            }
        }
    }
    
    @IBAction func onDeletePressed() {
        switch currentState{
        case .Normal:
            currentState = State.Delete
        case .Delete:
            currentState = State.Normal
        }
        onStateChanged()
        configureUI()
    }
}

// MARK:  - Collection View Delegates
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
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(collectionCellIdentifier, forIndexPath: indexPath) as! FlickrCollectionViewCell
        
        cell.backgroundColor = Constants.UI.CollectionViewBackgroundColor.normal
        cell.flickrPhoto = fp
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? FlickrCollectionViewCell {
            if cell.imageView.image != nil {
                return true
            }
        }
        return false
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        if isDeleteState() {
            cell?.backgroundColor = Constants.UI.CollectionViewBackgroundColor.highlighted
        } else {
            performSegueWithIdentifier(imagePreviewSegue, sender: self)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = Constants.UI.CollectionViewBackgroundColor.normal
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

// MARK:  - Fetch Results Controller Delegate
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
        configureUI()
    }
}