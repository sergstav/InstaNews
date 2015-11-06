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
    private let leftAndRightPadding: CGFloat = 32.0
    private let numberOfItemsPerRow: CGFloat = 3.0
    private let heightAdjustment: CGFloat = 30.0
    
    struct Storyboard {
        static let explorePhotoCell = "ExplorePhotoCell"
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
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
            url = self.urlWithSearchText("football")
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
                    print(self.photoDictionaries)
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
        
    
        return cell
    }

}
