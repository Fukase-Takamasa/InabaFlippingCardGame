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
    var roomDocumentID = ""
    var roomName = ""
    var myUUID = ""
    var myPlayerNumber = 0
    var isMyTurn = false
    var playerCount = 1
    var lastPlayerCount = 1
    var opponentPlayerName: Any = ""
    var myScore = 0
    var opponentScore = 0
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var playerJoinedLabel: UILabel!
    @IBOutlet weak var playerCountLabel: UILabel!
    @IBOutlet weak var navigationMessageLabel: UILabel!
    @IBOutlet weak var scoreCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CollectionViewUtil.registerCell(collectionView, identifier: CardCell.reusableIdentifier)
        self.navigationItem.title = roomName
        playerJoinedLabel.text = ""
        //            scoreCountLabel.text = "\(myScore)　　　\(opponentScore)"
        //Firestore
        db = Firestore.firestore()
        
        //Rxメソッド
        backButton.rx.tap.subscribe({ _ in
            self.showConnectionWillDisconnectAlert()
        }).disposed(by: disposeBag)
        
        //ルームに入った直後に1回だけ自分のプレーヤー番号を取得
        db.collection("rooms")
            .document(roomDocumentID)
            .getDocument { (doc, err) in
                if let doc = doc?.data() {
                    self.playerCount = doc.count - 3
                    print("playerCount: \(self.playerCount)")
                    self.playerCountLabel.text = "現在の参加人数\n\(self.playerCount)人"
                    self.myPlayerNumber = self.playerCount
                    if self.myPlayerNumber < 2 {
                        print("あなたは先攻です\n他のユーザーの参加を待っています")
                        self.navigationMessageLabel.text = "あなたは先攻です\n他のユーザーの参加を待っています"
                    }else {
                        print("あなたは後攻です\nゲームが開始されました")
                        self.navigationMessageLabel.text = "あなたは後攻です\nゲームが開始されました"
                    }
                }else {
                    print("getDocument Error: \(String(describing: err))")
                }
        }
        //自分/相手ターンの切り替わりと参加人数の取得、反映
        db.collection("rooms").document(roomDocumentID)
            .addSnapshotListener({(snapshot, err) in
                guard let snapshot = snapshot?.data() else {
                    print("PlayerData snapShotListener Error: \(String(describing: err))")
                    return
                }
                //プレーヤーの入退室を表示　相手が退室後の先攻後攻の切り替えも行う
                self.playerCount = snapshot.count - 3
                if self.lastPlayerCount != self.playerCount {
                    let bool = self.lastPlayerCount < self.playerCount ? true : false
                    self.playerJoinedOrLeftTheGame(snapshot: snapshot, joined: bool)
                    self.lastPlayerCount = self.playerCount
                }
                //参加人数の表示と、自分/相手ターンの切り替え
                self.playerCountLabel.text = "現在の参加人数\n\(snapshot.count - 3)人"
                if (snapshot.count - 3) == 2 {
                    self.isMyTurn = (snapshot["currentFlippingPlayer"] as! String) == ("player\(self.myPlayerNumber)") ? true : false
                    if self.isMyTurn {
                        self.collectionView.isUserInteractionEnabled = true
                        print("あなたのターンです")
                        self.navigationMessageLabel.text = "あなたのターンです"
                    }else {
                        self.collectionView.isUserInteractionEnabled = false
                        print("相手のターンです")
                        self.navigationMessageLabel.text = "相手のターンです"
                    }
                }else {
                    self.myPlayerNumber = 1
                    print("参加者が1人のため、他のユーザーの参加を待っています")
                }
            })
        //遷移前にセットしたカードデータを取得、以降カードをめくるごとに通知を受ける
        db.collection("rooms").document(roomDocumentID).collection("cardData")
            .order(by: "id")
            .addSnapshotListener({ (snapShot, err) in
                var player1Score = 0
                var player2Score = 0
                print("snapShot流れた")
                if let snapShot = snapShot {
                    self.inabaCards = snapShot.documents.map{ data -> CardData in
                        let data = data.data()
                        if data["correctedPlayer"] as? String ?? "" == "player1" {
                            player1Score += 1
                        }else if data["correctedPlayer"] as? String ?? "" == "player2" {
                            player2Score += 1
                        }
                        return CardData(imageName: data["imageName"] as! String, isOpened: data["isOpened"] as! Bool, isMatched: data["isMatched"] as! Bool)
                    }
                    if self.myPlayerNumber == 1 {
                        self.scoreCountLabel.text = "\(player1Score / 2)　　　\(player2Score / 2)"
                    }else {
                        self.scoreCountLabel.text = "\(player2Score / 2)　　　\(player1Score / 2)"
                    }
                    self.collectionView.reloadData()
                }else {
                    print("CardData snapShotListener Error: \(String(describing: err))")
                }
            })
    }
    
    func playerJoinedOrLeftTheGame(snapshot: [String: Any], joined: Bool) {
        let opponentPlayerData = snapshot.first{
            ($0.key != self.myUUID) && ($0.key != "currentFlippingPlayer") && ($0.key != "defaultRoom") && ($0.key != "roomName")
        }
        let newOpponentPlayerName = opponentPlayerData?.value as? String ?? "名無しさん"
        if joined {
            UIView.animate(withDuration: 1) {
                if self.myPlayerNumber <= 2{
                    self.playerJoinedLabel.text = "\(newOpponentPlayerName)が参加しました"
                }else {
                    self.playerJoinedLabel.text = "\(newOpponentPlayerName)のゲームに参加しました"
                }
            }
        }else {
            UIView.animate(withDuration: 1) {
                self.playerJoinedLabel.text = "\(self.opponentPlayerName)が退室しました"
            }
            opponentPlayerName = ""
            print("あなたは先攻です\n他のユーザーの参加を待っています")
            self.navigationMessageLabel.text = "あなたは先攻です\n他のユーザーの参加を待っています"
            self.collectionView.isUserInteractionEnabled = false
        }
        self.opponentPlayerName = newOpponentPlayerName
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 1) {
                self.playerJoinedLabel.text = ""
            }
        }
    }
    
    func showConnectionWillDisconnectAlert() {
        let alert = UIAlertController(title: "ロビーに戻るとゲームデータは破棄されます。よろしいですか？", message: "キャンセルを押すとゲームを再開します", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { (UIAlertAction) in
            HUD.show(.progress)
            self.db.collection("rooms").document(self.roomDocumentID).updateData(["\(self.myUUID)": FieldValue.delete(),]){ err in
                if let err = err {
                    print("削除エラー: \(err)")
                    HUD.hide()
                    self.navigationController?.popViewController(animated: true)
                }else {
                    print("削除完了")
                    HUD.hide()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        let cancel = UIAlertAction(title: "キャンセル", style: .cancel) { (UIAlertAction) in
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
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
                db.collection("rooms").document(roomDocumentID).collection("cardData").document("cardData\(flippedCard[0] + 1)").setData([
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
                    self.myScore += 1
                    self.navigationMessageLabel.text = "マッチしました！！\n続けてあなたのターンです"
                    print("マッチ結果: \(inabaCards[flippedCard[0]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    //マッチした！両方のカードのisOpened / isMatchedをtrueにする
                    db.collection("rooms").document(roomDocumentID).collection("cardData").document("cardData\(flippedCard[1] + 1)").setData([
                        "isOpened": true,
                        "isMatched": true,
                        "correctedPlayer": "player\(myPlayerNumber)"
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
                    print("マッチしませんでした\nカードを覚えておきましょう♪")
                    self.navigationMessageLabel.text = "マッチしませんでした\nカードを覚えておきましょう♪"
                    print("マッチ結果: \(inabaCards[flippedCard[1]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    collectionView.isUserInteractionEnabled = false
                    //ここで一旦　isOpened: trueだけ送信する
                    print("ここで一旦　isOpened: trueだけ送信する")
                    db.collection("rooms").document(roomDocumentID).collection("cardData").document("cardData\(flippedCard[1] + 1)").setData([
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
                        self.db.collection("rooms").document(self.roomDocumentID).collection("cardData").document("cardData\(self.flippedCard[0] + 1)").setData([
                            "isOpened": false,
                        ], merge: true) { err in
                            print("indexPath.row: \(self.flippedCard[0])のisOpenedをtrue, isMatchedをtrueにした")
                            if let err = err {
                                print("errです: \(err)")
                            }else {
                                print("setData Succesful")
                            }
                        }
                        self.db.collection("rooms").document(self.roomDocumentID).collection("cardData").document("cardData\(self.flippedCard[1] + 1)").setData([
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
                        self.db.collection("rooms").document(self.roomDocumentID).setData([
                            "currentFlippingPlayer": "player\(self.myPlayerNumber)" == "player1" ? "player2" : "player1"], merge: true)
                        self.navigationMessageLabel.text = "相手のターンです"
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
