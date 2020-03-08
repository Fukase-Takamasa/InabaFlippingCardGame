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
    
    var inabaCards: [(UIImage, Bool, Bool)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        CollectionViewUtil.registerCell(collectionView, identifier: CardCell.reusableIdentifier)
    }
    
    func setInabaCard() {
        inabaCards = [
            (UIImage(named: "ina1")!, false, false),
            (UIImage(named: "ina2")!, false, false),
            (UIImage(named: "ina3")!, false, false),
            (UIImage(named: "ina4")!, false, false),
            (UIImage(named: "ina5")!, false, false),
            (UIImage(named: "ina6")!, false, false),
            (UIImage(named: "ina7")!, false, false),
            (UIImage(named: "ina8")!, false, false),
            (UIImage(named: "ina9")!, false, false),
            (UIImage(named: "ina10")!, false, false),
            (UIImage(named: "ina11")!, false, false),
            (UIImage(named: "ina12")!, false, false),
            (UIImage(named: "ina13")!, false, false),
            (UIImage(named: "ina14")!, false, false),
            (UIImage(named: "ina15")!, false, false)
        ]
    }
}

extension PlayGameViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = CollectionViewUtil.createCell(collectionView, identifier: CardCell.reusableIdentifier, indexPath) as! CardCell
        if indexPath.row % 2 == 0 {
            if self.isOpenedBool[indexPath.row] {
                cell.imageView.image = UIImage(named: "ina9")
            }else {
                cell.imageView.image = UIImage(named: "CardBackImageRed")
            }
        }else {
            if self.isOpenedBool[indexPath.row] {
                cell.imageView.image = UIImage(named: "ina7")
            }else {
                cell.imageView.image = UIImage(named: "CardBackImageBlue")
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isOpenedBool[indexPath.row] {
            self.isOpenedBool[indexPath.row] = false
        }else {
            self.isOpenedBool[indexPath.row] = true
        }
        collectionView.reloadData()
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
        let cellHeight = (self.collectionView.bounds.height / 5) - (2 * (5 - 1))
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
