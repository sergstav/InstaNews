//
//  ExploreCollectionViewController.swift
//  InstaNews
//
//  Created by sergstav on 11/6/15.
//  Copyright © 2015 nscodegroup. All rights reserved.
//

import UIKit
import SimpleAuth

class ExploreCollectionViewController: UICollectionViewController
{
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var accessToken: String!
    private var photoDictionaries = [AnyObject]()
    var data: [[String: String!]] = []
    private let leftAndRightPadding: CGFloat = 32.0
    private let numberOfItemsPerRow: CGFloat = 3.0
    private let heightAdjustment: CGFloat = 30.0
    
    struct Storyboard {
        static let explorePhotoCell = "ExplorePhotoCell"
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //Configure searchBar
        self.navigationItem.titleView = self.searchBar
        self.searchBar.delegate = self
        
        //Configure collectionView
        self.collectionView?.backgroundColor = UIColor.whiteColor()
        let width = (CGRectGetWidth(collectionView!.frame) - leftAndRightPadding) / numberOfItemsPerRow
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSizeMake(width, width + heightAdjustment)
        
        authInstagram()
        
    }
    
    // MARK: - Helpers
    
    func authInstagram()
    {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let token = userDefaults.objectForKey("accessToken") as? String
        {
            self.accessToken = token
            print("Already logged in")
            
            //Load photos
            
            fetchPhotos()
        }
            
        else
        {
            
            SimpleAuth.authorize("instagram") { (responseObject, error) -> Void in
                if let response = responseObject as? NSDictionary
                {
                    let credentials = response["credentials"] as! NSDictionary
                    let accessToken = credentials["token"] as! String
                    
                    self.accessToken = accessToken
                    
                    userDefaults.setObject(self.accessToken, forKey: "accessToken")
                    userDefaults.synchronize()
                    
                    //load photos
                    self.fetchPhotos()
                }
            }
            
        }

    }
    
    
    //https://api.instagram.com/v1/tags/{tag-name}/media/recent?access_token=ACCESS-TOKEN
    func urlWithSearchText(searchText : String) -> NSURL
    {
        let escapedSearchText = searchText.stringByReplacingOccurrencesOfString(" ", withString: "")
        let urlString = "https://api.instagram.com/v1/tags/\(escapedSearchText)/media/recent?access_token=\(self.accessToken)"
        
        let url = NSURL(string: urlString)!
        
        return url
    }
    
    func fetchPhotos()
    {
        let session = NSURLSession.sharedSession()
        
        let url: NSURL
        
        if !self.searchBar.text!.isEmpty
        {
            url = self.urlWithSearchText(self.searchBar.text!)
        }
        
        else
        {
            url = self.urlWithSearchText("neymar")
        }
        
        let request = NSURLRequest(URL: url)
        
        let task = session.downloadTaskWithRequest(request) { (localfile, response, error) -> Void in
            if error == nil
            {
                let data = NSData(contentsOfURL: localfile!)
                
                do
                {
                    let responseDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                    
                    self.photoDictionaries = responseDictionary.valueForKeyPath("data") as! [AnyObject]
                    
                    for result in self.photoDictionaries
                    {
                        let likes = result.valueForKeyPath("likes.count")!.stringValue
                        let comment = result.valueForKeyPath("comments.count")!.stringValue
                        let obj = ["comments" : comment, "likes" : likes]
                        
                        self.data.append(obj)
                    }
                    
                    self.orderedByLikes()
                }
                
                catch let error
                {
                    print(error)
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.collectionView?.reloadData()
            })
            
        }
        
        task.resume()
    }
    
    func orderBy(key: String)
    {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) { () -> Void in
            //sort on background thread
            
            self.data.sortInPlace
                {
                    item1, item2 in
                    let value1 = Double(item1[key]!)
                    let value2 = Double(item2[key]!)
                    
                    return value1 > value2
            }
            
            //update UI in foreground
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.collectionView?.reloadData()
            })
        }
    }
    
    func orderedByLikes()
    {
        orderBy("likes")
    }
    
    func orderedByComment()
    {
        orderBy("comments")
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
       return self.photoDictionaries.count
        
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Storyboard.explorePhotoCell, forIndexPath: indexPath) as! ExplorePhotoCollectionViewCell
    
        // Configure the cell
        
        let photoDictionary = photoDictionaries[indexPath.item]
        
        cell.photo = photoDictionary
        
        cell.likes = NSNumberFormatter.localizedStringFromNumber(Int((data[indexPath.row]["likes"])!)!, numberStyle: NSNumberFormatterStyle.DecimalStyle)
    
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        let photo = self.photoDictionaries[indexPath.row] as! NSDictionary
        
        let viewController = DetailPhotoViewController()
        viewController.modalPresentationStyle = UIModalPresentationStyle.Custom
        
        viewController.transitioningDelegate = self
        
        viewController.photo = photo
        
        self.presentViewController(viewController, animated: true, completion: nil);
        
    }

}

//MARK: - UISearchBarDelegate

extension ExploreCollectionViewController : UISearchBarDelegate
{
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        if !searchBar.text!.isEmpty
        {
            searchBar.resignFirstResponder()
            fetchPhotos()
        }
    }
}

//MARK: - UIViewControllerTransitioningDelegate

extension ExploreCollectionViewController :UIViewControllerTransitioningDelegate
{
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return PresentDetailTransition()
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissDetailTransition()
    }
}
