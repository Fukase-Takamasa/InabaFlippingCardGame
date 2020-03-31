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
    var roomNumber = 0
    var myUUID = ""
    var myPlayerNumber = 0
    var isMyTurn = false
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "ルーム\(roomNumber)"
        
        CollectionViewUtil.registerCell(collectionView, identifier: CardCell.reusableIdentifier)
        
        //Firestore
        db = Firestore.firestore()
        
        db.collection("rooms")
            .document("ルーム\(roomNumber)")
            .getDocument { (doc, err) in
                if let doc = doc?.data() {
                    print("doc.count: \(doc.count - 1)")
                    self.myPlayerNumber = doc.count - 1
                    if self.myPlayerNumber < 2 {
                        print("あなたは先攻です")
                        self.label.text = "あなたは先攻です"
                        self.collectionView.isUserInteractionEnabled = true
                    }else {
                        print("あなたは後攻です")
                        self.label.text = "あなたは後攻です"
                        self.collectionView.isUserInteractionEnabled = false
                    }
                }else {
                    print("err: \(String(describing: err))")
                }
        }
        
        db.collection("rooms")
            .document("ルーム\(roomNumber)")
            .addSnapshotListener({(snapshot, err) in
                if let snapshot = snapshot?.data() {
                    self.isMyTurn = (snapshot["turn"] as! Int) == self.myPlayerNumber ? true : false
                    if self.isMyTurn {
                        self.collectionView.isUserInteractionEnabled = true
                        print("俺のターン！どろぉう！！！！（自分のターンです）")
                    }else {
                        self.collectionView.isUserInteractionEnabled = false
                        print("今日はこの辺にしといてやるか...（相手のターンになった）")
                    }
                }
            })
        
        db.collection("rooms").document("ルーム\(roomNumber)").collection("cardData")
            .order(by: "id")
            .addSnapshotListener({ (snapShot, err) in
                print("snapShot流れた")
                if let snapShot = snapShot {
                    self.inabaCards = snapShot.documents.map{ data -> CardData in
                        let data = data.data()
                        return CardData(imageName: data["imageName"] as! String, isOpened: data["isOpened"] as! Bool, isMatched: data["isMatched"] as! Bool)
                    }
                    self.collectionView.reloadData()
                }else {
                    print("Error: \(String(describing: err))")
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
        if inabaCards[indexPath.row].isMatched || inabaCards[indexPath.row].isOpened {
            print("生成時: isMatchedがtrue")
            cell.imageView.image = UIImage(named: inabaCards[indexPath.row].imageName)!
        }else {
            print("生成時: isMatchedがfalse")
            if indexPath.row % 2 == 0 {
                cell.imageView.image = UIImage(named: "CardBackImageRed")
            }else {
                cell.imageView.image = UIImage(named: "CardBackImageBlue")
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
                db.collection("rooms").document("ルーム\(roomNumber)").collection("cardData").document("cardData\(flippedCard[0] + 1)").setData([
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
                    self.label.text = "マッチしました！！\n続けてあなたのターンです"
                    print("マッチ結果: \(inabaCards[flippedCard[0]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    //マッチした！isOpenedをtrueにする
                    db.collection("rooms").document("ルーム\(roomNumber)").collection("cardData").document("cardData\(flippedCard[1] + 1)").setData([
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
                    self.label.text = "マッチしませんでした...\nカードを覚えておきましょう♪"
                    print("マッチ結果: \(inabaCards[flippedCard[1]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    collectionView.isUserInteractionEnabled = false
                    //ここで一旦　isOpened: trueだけ送信する
                    print("ここで一旦　isOpened: trueだけ送信する")
                    db.collection("rooms").document("ルーム\(roomNumber)").collection("cardData").document("cardData\(flippedCard[1] + 1)").setData([
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
                        self.db.collection("rooms").document("ルーム\(self.roomNumber)").collection("cardData").document("cardData\(self.flippedCard[0] + 1)").setData([
                            "isOpened": false,
                        ], merge: true) { err in
                            print("indexPath.row: \(self.flippedCard[0])のisOpenedをtrue, isMatchedをtrueにした")
                            if let err = err {
                                print("errです: \(err)")
                            }else {
                                print("setData Succesful")
                            }
                        }
                        self.db.collection("rooms").document("ルーム\(self.roomNumber)").collection("cardData").document("cardData\(self.flippedCard[1] + 1)").setData([
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
                        self.db.collection("rooms")
                            .document("ルーム\(self.roomNumber)")
                            .setData(["turn": self.myPlayerNumber == 1 ? 2 : 1], merge: true)
                        print("相手のターンです")
                        collectionView.isUserInteractionEnabled = false
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
