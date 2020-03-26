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
    var db: Firestore!
    var inabaCards: [CardData] = []
    var flipCount = 1
    var flippedCard = [0, 0]
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CollectionViewUtil.registerCell(collectionView, identifier: CardCell.reusableIdentifier)
        
        //Firestore
        db = Firestore.firestore()
        
        db.collection("currentGameTableData")
            //DB内のデータをidで昇順ソートしてから、取得
            .order(by: "id")
            .addSnapshotListener({ (snapShot, error) in
                print("snapShot流れた")
//                if let snapShot = snapShot {
//                    snapShot.documentChanges.forEach{diff in
//                        print("documentChanges")
//                        print("diff: \(diff)")
//                    }
//                }
                if let snapShot = snapShot {
                    self.inabaCards = snapShot.documents.map{ data -> CardData in
                        let data = data.data()
                        return CardData(imageName: data["imageName"] as! String, isOpened: data["isOpened"] as! Bool, isMatched: data["isMatched"] as! Bool)
                    }
                    self.collectionView.reloadData()
                }else {
                    print("snapShotListener Error: \(String(describing: error))")
                }
            })
    }
}

extension PlayGameViewController {

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
        print("inabaCards: \(inabaCards)")

        if inabaCards[indexPath.row].isOpened == false {
            if flipCount == 1 {
                print("flipCount: \(self.flipCount)")
                flipCount += 1
                flippedCard[0] = indexPath.row
                db.collection("currentGameTableData").document("cardData\(flippedCard[0] + 1)").setData([
                    "isOpened": true
                ], merge: true) { err in
                    print("indexPath.row: \(self.flippedCard[0])のisOpenedをtrueにした")
                    if let err = err {
                        print("errです: \(err)")
                    }else {
                        print("setData Succesful")
                    }
                }
            }else {
                print("flipCount: \(self.flipCount)")
                flippedCard[1] = indexPath.row
                //フリップ２回目　２枚がマッチしてるかジャッジ
                if (inabaCards[flippedCard[0]].imageName) == (inabaCards[flippedCard[1]].imageName) {
                    print("マッチした！")
                    print("マッチ結果: \(inabaCards[flippedCard[0]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    //マッチした！両方のisOpenedをtrueにする
                    db.collection("currentGameTableData").document("cardData\(flippedCard[0] + 1)").setData([
                        "isOpened": true,
                        "isMatched": true
                    ], merge: true) { err in
                        print("indexPath.row: \(self.flippedCard[0])のisOpenedをtrue, isMatchedをtrueにした")
                        if let err = err {
                            print("errです: \(err)")
                        }else {
                            print("setData Succesful")
                        }
                    }
                    db.collection("currentGameTableData").document("cardData\(flippedCard[1] + 1)").setData([
                        "isOpened": true,
                        "isMatched": true
                    ], merge: true) { err in
                        print("indexPath.row: \(self.flippedCard[1])のisOpenedをtrue, isMatchedをtrueにした")
                        if let err = err {
                            print("errです: \(err)")
                        }else {
                            print("setData Succesful")
                        }
                    }
                    self.flipCount = 1
                    self.flippedCard = [0,0]
                }else {
                    print("マッチしなかったorz")
                    print("マッチ結果: \(inabaCards[flippedCard[1]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    collectionView.isUserInteractionEnabled = false
                    
                    //ここで一旦　isOpened: trueだけ送信する
                    print("ここで一旦　isOpened: trueだけ送信する")
                    db.collection("currentGameTableData").document("cardData\(flippedCard[0] + 1)").setData([
                        "isOpened": true,
                    ], merge: true) { err in
                        print("indexPath.row: \(self.flippedCard[0])のisOpenedをtrue, isMatchedをtrueにした")
                        if let err = err {
                            print("errです: \(err)")
                        }else {
                            print("setData Succesful")
                        }
                    }
                    db.collection("currentGameTableData").document("cardData\(flippedCard[1] + 1)").setData([
                        "isOpened": true,
                    ], merge: true) { err in
                        print("indexPath.row: \(self.flippedCard[1])のisOpenedをtrue, isMatchedをtrueにした")
                        if let err = err {
                            print("errです: \(err)")
                        }else {
                            print("setData Succesful")
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                        print("遅延処理内のflippedCard: \(self.flippedCard)")
                        //マッチしてないので、2秒後に両方閉じる
                        self.db.collection("currentGameTableData").document("cardData\(self.flippedCard[0] + 1)").setData([
                            "isOpened": false,
                        ], merge: true) { err in
                            print("indexPath.row: \(self.flippedCard[0])のisOpenedをtrue, isMatchedをtrueにした")
                            if let err = err {
                                print("errです: \(err)")
                            }else {
                                print("setData Succesful")
                            }
                        }
                        self.db.collection("currentGameTableData").document("cardData\(self.flippedCard[1] + 1)").setData([
                            "isOpened": false,
                        ], merge: true) { err in
                            print("indexPath.row: \(self.flippedCard[1])のisOpenedをtrue, isMatchedをtrueにした")
                            if let err = err {
                                print("errです: \(err)")
                            }else {
                                print("setData Succesful")
                            }
                        }
                        self.flipCount = 1
                        self.flippedCard = [0,0]
                        collectionView.isUserInteractionEnabled = true
                    }
                }
            }
        }

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
