//
//  InstagramData.swift
//  InstaNews
//
//  Created by sergstav on 11/6/15.
//  Copyright © 2015 nscodegroup. All rights reserved.
//

import UIKit
import SAMCache

class InstagramData
{
    static func imageForPhoto(photoDictionary: AnyObject, size: String, completion: (image: UIImage) -> Void )
    {
        let photoID = photoDictionary["id"] as! String
        let key = "\(photoID) - \(size)"
        
        if let image = SAMCache.sharedCache().imageForKey(key)
        {
            completion(image: image)
        }
        
        else
        {
            
            let urlString = photoDictionary.valueForKeyPath("images.\(size).url") as! String
            
            let url = NSURL(string: urlString)!
            
            let session = NSURLSession.sharedSession()
            
            let request = NSURLRequest(URL: url)
            
            let task = session.downloadTaskWithRequest(request) { (localFile, response, error) -> Void in
                if error == nil
                {
                    let data = NSData(contentsOfURL: localFile!)
                    let image = UIImage(data: data!)
                    
                    SAMCache.sharedCache().setImage(image, forKey: key)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(image: image!)
                    })
                }
            }
            
            task.resume()
        }
        
    }
}