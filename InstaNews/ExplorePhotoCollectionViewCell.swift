//
//  ExplorePhotoCollectionViewCell.swift
//  InstaNews
//
//  Created by sergstav on 11/6/15.
//  Copyright © 2015 nscodegroup. All rights reserved.
//

import UIKit

class ExplorePhotoCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var countOfLikes: UILabel!
    
    var photo: AnyObject!
        {
        didSet
        {
            InstagramData.imageForPhoto(photo, size: "thumbnail") { (image) -> Void in
                self.imageView.image = image
            }
        }
    }
    
}
