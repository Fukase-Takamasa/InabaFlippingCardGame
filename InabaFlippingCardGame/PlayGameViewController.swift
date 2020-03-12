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
    
    let disposeBag = DisposeBag()
    var defaultStore: Firestore!
    var inabaCards: [CardData] = []
//    var dataBaseListener: ListenerRegistration?
    var flipCount = 1
    var flippedCard = [0, 0]
    var isUserTouchEnabled = true
    var randomNumbers: [Int] = []
    
    @IBOutlet weak var setCardButton: UIButton!
    @IBOutlet weak var quitButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CollectionViewUtil.registerCell(collectionView, identifier: CardCell.reusableIdentifier)
        
        //other
        setCardButton.rx.tap.subscribe{ _ in
        }.disposed(by: disposeBag)
        quitButton.rx.tap.subscribe{ _ in
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        //Firestore
        defaultStore = Firestore.firestore()
        defaultStore.collection("currentGameTableData").addSnapshotListener({ (snapShot, error) in
            print("snapShot流れた")
            if let snapShot = snapShot {
                snapShot.documentChanges.forEach{diff in
                    print("documentChanges")
                    print("diff: \(diff)")
                }
            }
            if let snapShot = snapShot {
                self.inabaCards = snapShot.documents.map{ data -> CardData in
                    let data = data.data()
                    return CardData(imageName: data["imageName"] as! String, isOpened: data["isOpened"] as! Bool, isMatched: data["isMatched"] as! Bool)
                }
                self.collectionView.reloadData()
            }else {
                print("snapShotListener Error: \(error)")
            }
        })
    }
    
//    func setAllCardData() {
//        for i in 1...15 {
//            randomNumbers += [i]
//        }
//        randomNumbers.shuffle()
//        for (index, random) in randomNumbers.enumerated() {
//            defaultStore.collection("currentGameTableData").document("cardData\(index)").setData([
//                "imageName": "ina\(random)"
//            ], merge: true) { err in
//                print(index)
//                if let err = err {
//                    print("errです: \(err)")
//                }else {
//                    print("setData Succesful")
//                }
//            }
//            defaultStore.collection("currentGameTableData").document("cardData\(index + 15)").setData([
//                "imageName": "ina\(random)"
//            ], merge: true) { err in
//                print(index)
//                if let err = err {
//                    print("errです: \(err)")
//                }else {
//                    print("setData Succesful(+15)")
//                }
//            }
//        }
//    }
        
//        defaultStore.collection("currentGameTableData").document("cardData\(1)").setData([
//            "imageName": "ina\(30)"
//        ], merge: true) { err in
//            //            print(index)
//            if let err = err {
//                print("errです: \(err)")
//            }else {
//                print("setData Succesful")
//            }
//        }

}

extension PlayGameViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return inabaCards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = CollectionViewUtil.createCell(collectionView, identifier: CardCell.reusableIdentifier, indexPath) as! CardCell
        if inabaCards[indexPath.row].isMatched {
            print("生成時: isMatchedがtrue")
            cell.imageView.image = UIImage(named: inabaCards[indexPath.row].imageName)!
            inabaCards[indexPath.row].isOpened = true
        }else {
            print("生成時: isMatchedがfalse")
            if indexPath.row % 2 == 0 {
                if self.inabaCards[indexPath.row].isOpened {
                    cell.imageView.image = UIImage(named: inabaCards[indexPath.row].imageName)!
                }else {
                    cell.imageView.image = UIImage(named: "CardBackImageRed")
                }
            }else {
                if self.inabaCards[indexPath.row].isOpened {
                    cell.imageView.image = UIImage(named: inabaCards[indexPath.row].imageName)!
                }else {
                    cell.imageView.image = UIImage(named: "CardBackImageBlue")
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if inabaCards[indexPath.row].isOpened == false {
            //
            defaultStore.collection("currentGameTableData").document("cardData\(indexPath.row + 1)").setData([
//                "imageName": "ina\(indexPath.row + 1)",
//                "isOpened": true
                "row": (indexPath.row)
            ], merge: true) { err in
                print("indexPath.row: \(indexPath.row)のisOpenedをtrueにした")
                if let err = err {
                    print("errです: \(err)")
                }else {
                    print("setData Succesful")
                }
            }
        }else {
            defaultStore.collection("currentGameTableData").document("cardData\(indexPath.row + 1)").setData([
//                "imageName": "ina\(indexPath.row + 1)",
                "isOpened": false
            ], merge: true) { err in
                print("indexPath.row: \(indexPath.row)のisOpenedをfalseにした")
                if let err = err {
                    print("errです: \(err)")
                }else {
                    print("setData Succesful")
                }
            }
        }
        collectionView.reloadData()
    }
//            self.inabaCards[indexPath.row].isOpened = true
//            if self.flipCount == 2 {
//                self.flippedCard[1] = indexPath.row
//                //フリップ２回目　２枚がマッチしてるかジャッジ
//                if (inabaCards[flippedCard[0]].imageName) == (inabaCards[flippedCard[1]].imageName) {
//                    print("マッチした！")
//                    print("マッチ結果: \(inabaCards[flippedCard[0]]), \(inabaCards[flippedCard[1]])")
//                    print("flippedCard: \(flippedCard)")
//                    //マッチした！両方のisOpenedをtrueにする
//                    //
//                    inabaCards[flippedCard[0]].isMatched = true
//                    //
//                    inabaCards[flippedCard[1]].isMatched = true
//                    self.flipCount = 1
//                    self.flippedCard = [0,0]
//                }else {
//                    print("マッチしませんでした")
//                    print("マッチ結果: \(inabaCards[flippedCard[1]]), \(inabaCards[flippedCard[1]])")
//                    print("flippedCard: \(flippedCard)")
//                    collectionView.isUserInteractionEnabled = false
//                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
//                        //マッチしてないので、両方閉じる
//                        self.inabaCards[self.flippedCard[0]].isOpened = false
//                        self.inabaCards[self.flippedCard[1]].isOpened = false
//                        self.flipCount = 1
//                        self.flippedCard = [0,0]
//                        collectionView.isUserInteractionEnabled = true
//                        collectionView.reloadData()
//                    }
//                }
//            }else {
//                self.flipCount += 1
//                self.flippedCard[0] = indexPath.row
//            }

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
