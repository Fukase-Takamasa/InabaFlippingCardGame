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
    
    //（画像名、isOpenedのBool値、isMatchedのBool値）
    var inabaCards: [(UIImage, Bool, Bool, Int)] = []
    var flipCount = 1
    var flippedCard = [0, 0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInabaCard()

        CollectionViewUtil.registerCell(collectionView, identifier: CardCell.reusableIdentifier)
    }
    
    func setInabaCard() {
        inabaCards = [
            (UIImage(named: "ina1")!, false, false, 1),
            (UIImage(named: "ina2")!, false, false, 2),
            (UIImage(named: "ina3")!, false, false, 3),
            (UIImage(named: "ina4")!, false, false, 4),
            (UIImage(named: "ina5")!, false, false, 5),
            (UIImage(named: "ina6")!, false, false, 6),
            (UIImage(named: "ina7")!, false, false, 7),
            (UIImage(named: "ina8")!, false, false, 8),
            (UIImage(named: "ina9")!, false, false, 9),
            (UIImage(named: "ina10")!, false, false, 10),
            (UIImage(named: "ina11")!, false, false, 11),
            (UIImage(named: "ina12")!, false, false, 12),
            (UIImage(named: "ina13")!, false, false, 13),
            (UIImage(named: "ina14")!, false, false, 14),
            (UIImage(named: "ina15")!, false, false, 15),
            (UIImage(named: "ina1")!, false, false, 1),
            (UIImage(named: "ina2")!, false, false, 2),
            (UIImage(named: "ina3")!, false, false, 3),
            (UIImage(named: "ina4")!, false, false, 4),
            (UIImage(named: "ina5")!, false, false, 5),
            (UIImage(named: "ina6")!, false, false, 6),
            (UIImage(named: "ina7")!, false, false, 7),
            (UIImage(named: "ina8")!, false, false, 8),
            (UIImage(named: "ina9")!, false, false, 9),
            (UIImage(named: "ina10")!, false, false, 10),
            (UIImage(named: "ina11")!, false, false, 11),
            (UIImage(named: "ina12")!, false, false, 12),
            (UIImage(named: "ina13")!, false, false, 13),
            (UIImage(named: "ina14")!, false, false, 14),
            (UIImage(named: "ina15")!, false, false, 15),
        ]
    }
}

extension PlayGameViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = CollectionViewUtil.createCell(collectionView, identifier: CardCell.reusableIdentifier, indexPath) as! CardCell
        if inabaCards[indexPath.row].2 {
            print("生成時: isMatchedがtrue")
            cell.imageView.image = inabaCards[indexPath.row].0
            inabaCards[indexPath.row].1 = true
        }else {
            print("生成時: isMatchedがfalse")
            if indexPath.row % 2 == 0 {
                if self.inabaCards[indexPath.row].1 {
                    cell.imageView.image = inabaCards[indexPath.row].0
                }else {
                    cell.imageView.image = UIImage(named: "CardBackImageRed")
                }
            }else {
                if self.inabaCards[indexPath.row].1 {
                    cell.imageView.image = inabaCards[indexPath.row].0
                }else {
                    cell.imageView.image = UIImage(named: "CardBackImageBlue")
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if inabaCards[indexPath.row].1 == false {
            self.inabaCards[indexPath.row].1 = true
            if self.flipCount == 2 {
                self.flippedCard[1] = indexPath.row
                //フリップ２回目　２枚がマッチしてるかジャッジ
                if (inabaCards[flippedCard[0]].3) == (inabaCards[flippedCard[1]].3) {
                    print("マッチした！")
                    print("マッチ結果: \(inabaCards[flippedCard[0]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    //マッチした！両方のisOpenedをtrueにする
                    inabaCards[flippedCard[0]].2 = true
                    inabaCards[flippedCard[1]].2 = true
                    flipCount = 1
                }else {
                    print("マッチしませんでした")
                    print("マッチ結果: \(inabaCards[flippedCard[1]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    //マッチしてないので、両方閉じる
                    inabaCards[flippedCard[0]].1 = false
                    inabaCards[flippedCard[1]].1 = false
                    flippedCard = [0,0]
                    flipCount = 1
                }
            }else {
                self.flipCount += 1
                self.flippedCard[0] = indexPath.row
            }
        }
        
        collectionView.reloadData()

//        let matchPair = inabaCards.filter{ $0.3 == (inabaCards[indexPath.row].3)}
//        print("matchPair: \(matchPair)")
//        let pieceOfPairFirst = matchPair[0].1
//        let pieceOfPairSecond = matchPair[1].1
//        if pieceOfPairFirst == pieceOfPairSecond {
//            //ペアーが揃った場合の処理　２枚とも開けたままにする
//
//        }else {
//            //ペアーが揃っていない場合の処理　２枚とも閉じる
//
//        }
        
        
//        else {
//            self.inabaCards[indexPath.row].1 = false
//        }
        
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
