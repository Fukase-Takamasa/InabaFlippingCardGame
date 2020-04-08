//
//  CardCell.swift
//  InabaFlippingCardGame
//
//  Created by 深瀬貴将 on 2020/03/08.
//  Copyright © 2020 fukase. All rights reserved.
//

import UIKit
import Instantiate
import InstantiateStandard
import RxSwift
import RxCocoa

class CardCell: UICollectionViewCell, Reusable {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        self.disposeBag = DisposeBag()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
