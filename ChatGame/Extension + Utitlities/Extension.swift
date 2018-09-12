//
//  Extension.swift
//  ChatGame
//
//  Created by Cuong on 9/10/18.
//  Copyright © 2018 quoccuong. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWith(_ urlString: String) {
        
        self.image = nil
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = cachedImage
            return
        }
        
        // otherwise fire a new download
         if let url = URL(string: urlString) {
            
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
                if error != nil {
                    print(error)
                    return
                }
            
                DispatchQueue.main.async {
                    
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                        self.image = downloadedImage

                    }
                }
            
                }.resume()
            
        }
    }
}
