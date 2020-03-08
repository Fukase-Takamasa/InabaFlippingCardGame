//
//  PlayGameViewController.swift
//  InabaFlippingCardGame
//
//  Created by 深瀬貴将 on 2020/03/07.
//  Copyright © 2020 fukase. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Instantiate
import InstantiateStandard
import PKHUD

class PlayGameViewController: UIViewController, StoryboardInstantiatable {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        CollectionViewUtil.registerCell(collectionView, identifier: CardCell.reusableIdentifier)
    }
}

extension PlayGameViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = CollectionViewUtil.createCell(collectionView, identifier: CardCell.reusableIdentifier, indexPath) as! CardCell
//        switch indexPath.row {
//        case 0...4:
//            cell.imageView.image = UIImage(named: "CardBackImageRed")
//        case 5...9:
//            cell.imageView.image = UIImage(named: "CardBackImageBlue")
//        case 10...14:
//            cell.imageView.image = UIImage(named: "CardBackImageRed")
//        case 15...19:
//            cell.imageView.image = UIImage(named: "CardBackImageBlue")
//        case 20...24:
//            cell.imageView.image = UIImage(named: "CardBackImageRed")
//        case 25...29:
//            cell.imageView.image = UIImage(named: "CardBackImageBlue")
//        default:
//            break
//        }
        if indexPath.row % 2 == 0 {
            cell.imageView.image = UIImage(named: "CardBackImageRed")
        }else {
            cell.imageView.image = UIImage(named: "CardBackImageBlue")
        }
        return cell
    }
}

extension PlayGameViewController: UICollectionViewDelegateFlowLayout {
    //セクションの外側余白
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    //セルサイズ
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (self.collectionView.bounds.width / 6) - (1.4 * (6 - 1))
        let cellHeight = (self.collectionView.bounds.height / 6) - (1 * (5 - 1))
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    //列間の余白（□□□
    //
    //　　　　　　□□□）
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    //行間の余白（□ ＜ー＞　□）？？
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
