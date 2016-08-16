//
//  PageViewController.swift
//  Nanodegree_VirtualTourist
//
//  Created by Xuan Yuan (Frank) on 8/16/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import UIKit
import CoreData

class PageViewController: UIPageViewController {

    var currentIndex:Int!
    var fetchedResultsController : NSFetchedResultsController? {
        didSet {
            excuteSearch()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        if let viewController = instantiateViewController(currentIndex ?? 0) {
            let viewControllers = [viewController]
            setViewControllers(viewControllers,
                               direction: .Forward,
                               animated: false,
                               completion: nil)
        }
    }
    
    func instantiateViewController(index: Int) -> ImageViewController? {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("ImageViewController") as! ImageViewController
        vc.flickrPhoto = fetchedResultsController?.fetchedObjects![index] as? FlickrPhoto
        vc.pageIndex = index
        return vc
    }


}
extension PageViewController {
    func excuteSearch() {
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }catch let e as NSError{
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}
extension PageViewController : UIPageViewControllerDataSource {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! ImageViewController).pageIndex
        if index > 0 {
            index = index - 1
            if let flickrPhoto = (fetchedResultsController?.fetchedObjects![index]) as? FlickrPhoto{
            
                if flickrPhoto.image != nil{
                    return instantiateViewController(index)
                } else {
                    flickrPhoto.startDownload()
                }
            }
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! ImageViewController).pageIndex
        if index < presentationCountForPageViewController(pageViewController) - 1 {
            
            index = index + 1
            
            if let flickrPhoto = (fetchedResultsController?.fetchedObjects![index]) as? FlickrPhoto{
            
                if flickrPhoto.image != nil{
                    return instantiateViewController(index)
                } else {
                    flickrPhoto.startDownload()
                }
            }
        }
        return nil
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        
        return (fetchedResultsController?.fetchedObjects?.count)!
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
}
