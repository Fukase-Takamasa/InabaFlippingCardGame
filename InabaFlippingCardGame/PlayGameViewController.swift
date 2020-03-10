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
import Firebase

class PlayGameViewController: UIViewController, StoryboardInstantiatable {
    
    struct CardData {
        var imageName: String
        var isOpened: Bool
        var isMatched: Bool
    }
    
    var defaultStore: Firestore!

    @IBOutlet weak var collectionView: UICollectionView!
    
    //（画像名、isOpenedのBool値、isMatchedのBool値）
//    var inabaCards: [(UIImage, Bool, Bool)] = []
    var newInabaCards: [CardData] = []
    var dataBaseListener: ListenerRegistration?
    var flipCount = 1
    var flippedCard = [0, 0]
    var isUserTouchEnabled = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CollectionViewUtil.registerCell(collectionView, identifier: CardCell.reusableIdentifier)
        
        self.dataBaseListener = Firestore.firestore().collection("currentGameTableData").addSnapshotListener({ (snapShot, error) in
            if let snapShot = snapShot {
                self.newInabaCards = snapShot.documents.map{ data -> CardData in
                    let data = data.data()
                    return CardData(imageName: data["imageName"] as! String, isOpened: data["isOpened"] as! Bool, isMatched: data["isMatched"] as! Bool)
                }
                self.collectionView.reloadData()
            }
        })
        
//        setInabaCard()
//        inabaCards.shuffle()

    }
    
//    func setInabaCard() {
//        inabaCards = [
//            (UIImage(named: "ina1")!, false, false),
//            (UIImage(named: "ina2")!, false, false),
//            (UIImage(named: "ina3")!, false, false),
//            (UIImage(named: "ina4")!, false, false),
//            (UIImage(named: "ina5")!, false, false),
//            (UIImage(named: "ina6")!, false, false),
//            (UIImage(named: "ina7")!, false, false),
//            (UIImage(named: "ina8")!, false, false),
//            (UIImage(named: "ina9")!, false, false),
//            (UIImage(named: "ina10")!, false, false),
//            (UIImage(named: "ina11")!, false, false),
//            (UIImage(named: "ina12")!, false, false),
//            (UIImage(named: "ina13")!, false, false),
//            (UIImage(named: "ina14")!, false, false),
//            (UIImage(named: "ina15")!, false, false),
//            (UIImage(named: "ina1")!, false, false),
//            (UIImage(named: "ina2")!, false, false),
//            (UIImage(named: "ina3")!, false, false),
//            (UIImage(named: "ina4")!, false, false),
//            (UIImage(named: "ina5")!, false, false),
//            (UIImage(named: "ina6")!, false, false),
//            (UIImage(named: "ina7")!, false, false),
//            (UIImage(named: "ina8")!, false, false),
//            (UIImage(named: "ina9")!, false, false),
//            (UIImage(named: "ina10")!, false, false),
//            (UIImage(named: "ina11")!, false, false),
//            (UIImage(named: "ina12")!, false, false),
//            (UIImage(named: "ina13")!, false, false),
//            (UIImage(named: "ina14")!, false, false),
//            (UIImage(named: "ina15")!, false, false)
//        ]
//    }
}

extension PlayGameViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return inabaCards.count
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
                if (inabaCards[flippedCard[0]].0) == (inabaCards[flippedCard[1]].0) {
                    print("マッチした！")
                    print("マッチ結果: \(inabaCards[flippedCard[0]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    //マッチした！両方のisOpenedをtrueにする
                    inabaCards[flippedCard[0]].2 = true
                    inabaCards[flippedCard[1]].2 = true
                    self.flipCount = 1
                    self.flippedCard = [0,0]
                }else {
                    print("マッチしませんでした")
                    print("マッチ結果: \(inabaCards[flippedCard[1]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    collectionView.isUserInteractionEnabled = false
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                        //マッチしてないので、両方閉じる
                        self.inabaCards[self.flippedCard[0]].1 = false
                        self.inabaCards[self.flippedCard[1]].1 = false
                        self.flipCount = 1
                        self.flippedCard = [0,0]
                        collectionView.isUserInteractionEnabled = true
                        collectionView.reloadData()
                    }
                }
            }else {
                self.flipCount += 1
                self.flippedCard[0] = indexPath.row
            }
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
