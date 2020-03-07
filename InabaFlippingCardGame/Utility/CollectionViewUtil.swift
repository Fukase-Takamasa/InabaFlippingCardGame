//
//  CollectionViewUtil.swift
//  InabaFlippingCardGame
//
//  Created by 深瀬貴将 on 2020/03/08.
//  Copyright © 2020 fukase. All rights reserved.
//

import Foundation
import Foundation
import UIKit

open class CollectionViewUtil {
    static func registerCell(_ collectionView: UICollectionView, identifier: String) {
        collectionView.register(UINib(nibName: identifier, bundle: nil), forCellWithReuseIdentifier: identifier)
    }
    
    static func createCell(_ collectionView: UICollectionView, identifier: String, _ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        return cell
    }
}
