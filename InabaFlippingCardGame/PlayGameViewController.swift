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
    
    enum GameType {
        case fightWithYourself
        case playWithCpu
        case fireStoreOnline
    }
    
    struct CardData {
        var imageName: String
        var isOpened: Bool
        var isMatched: Bool
    }
    
    let disposeBag = DisposeBag()
    var gameType: GameType?
    var db: Firestore!
    var inabaCards: [CardData] = []
    var flipCount = 1
    var flippedCard = [0, 0]
    var roomNumber = 0
    var myUUID = ""
    var myPlayerNumber = 0
    var isMyTurn = false
    var playerCount = 1
    var lastPlayerCount = 1
    var opponentPlayerName = ""
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
        
        //ゲームタイプによって処理を分岐
        switch gameType {
        case .fightWithYourself:
            self.navigationItem.title = "自分との戦い部屋"
            createRandomCardsForLocalPlayMode()
        case .playWithCpu:
            self.navigationItem.title = "CPUと戦う部屋"
            createRandomCardsForLocalPlayMode()
        case .fireStoreOnline:
            self.navigationItem.title = "ルーム\(roomNumber)"
            playerJoinedLabel.text = ""
            scoreCountLabel.text = "\(myScore)　　　\(opponentScore)"
            //Firestore
            db = Firestore.firestore()
            //Rxメソッド
            backButton.rx.tap.subscribe({ _ in
                self.showConnectionWillDisconnectAlert()
            }).disposed(by: disposeBag)
            //ルームに入った直後に1回だけ自分のプレーヤー番号を取得
            db.collection("rooms")
                .document("room\(roomNumber)")
                .getDocument { (doc, err) in
                    if let doc = doc?.data() {
                        print("doc.count: \(doc.count - 1)")
                        self.playerCount = doc.count - 1
                        self.playerCountLabel.text = "現在の参加人数\n\(doc.count - 1)人"
                        self.myPlayerNumber = doc.count - 1
                        if self.myPlayerNumber < 2 {
                            print("あなたは先攻です\n他のユーザーの参加を待っています")
                            self.navigationMessageLabel.text = "あなたは先攻です\n他のユーザーの参加を待っています"
                            self.collectionView.isUserInteractionEnabled = true
                        }else {
                            print("あなたは後攻です\nゲームが開始されました")
                            self.navigationMessageLabel.text = "あなたは後攻です\nゲームが開始されました"
                            self.collectionView.isUserInteractionEnabled = false
                        }
                    }else {
                        print("getDocument Error: \(String(describing: err))")
                    }
            }
            //自分/相手ターンの切り替わりと参加人数の取得、反映
            db.collection("rooms").document("room\(roomNumber)")
                .addSnapshotListener({(snapshot, err) in
                    guard let snapshot = snapshot?.data() else {
                        print("room\(self.roomNumber) PlayerData snapShotListener Error: \(String(describing: err))")
                        return
                    }
                    //プレーヤーの入退室を表示　相手が退室後の先攻後攻の切り替えも行う
                    self.playerCount = snapshot.count - 1
                    if self.lastPlayerCount != self.playerCount {
                        let bool = self.lastPlayerCount < self.playerCount ? true : false
                        self.playerJoinedOrLeftTheGame(snapshot: snapshot, joined: bool)
                        self.lastPlayerCount = self.playerCount
                    }
                    //参加人数の表示と、自分/相手ターンの切り替え
                    self.playerCountLabel.text = "現在の参加人数\n\(snapshot.count - 1)人"
                    if snapshot.count > 2 {
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
                        print("参加者が1人のため、他のユーザーの参加を待っています")
                    }
                })
            //遷移前にセットしたカードデータを取得、以降カードをめくるごとに通知を受ける
            db.collection("rooms").document("room\(roomNumber)").collection("cardData")
                .order(by: "id")
                .addSnapshotListener({ (snapShot, err) in
                    self.scoreCountLabel.text = "\(self.myScore)　　　\(self.opponentScore)"
                    print("snapShot流れた")
                    if let snapShot = snapShot {
                        self.inabaCards = snapShot.documents.map{ data -> CardData in
                            let data = data.data()
                            return CardData(imageName: data["imageName"] as! String, isOpened: data["isOpened"] as! Bool, isMatched: data["isMatched"] as! Bool)
                        }
                        self.collectionView.reloadData()
                    }else {
                        print("room\(self.roomNumber) CardData snapShotListener Error: \(String(describing: err))")
                    }
                })
            
        case .none:
            break
        }
    }
    
    func playerJoinedOrLeftTheGame(snapshot: [String: Any], joined: Bool) {
        let otherPlayerData = snapshot.first{ ($0.key != self.myUUID) && ($0.key != "currentFlippingPlayer") }
        let playerName = otherPlayerData?.value ?? "名前なし"
        if joined {
            UIView.animate(withDuration: 1) {
                self.playerJoinedLabel.text = "\(playerName)が参加しました"
            }
            let otherPlayerData = snapshot.first{ ($0.key != self.myUUID) && ($0.key != "currentFlippingPlayer") }
            opponentPlayerName = (otherPlayerData?.value ?? "名前なし") as! String
        }else {
            UIView.animate(withDuration: 1) {
                self.playerJoinedLabel.text = "\(self.opponentPlayerName)が退室しました"
            }
            opponentPlayerName = ""
            print("あなたは先攻です\n他のユーザーの参加を待っています")
            self.navigationMessageLabel.text = "あなたは先攻です\n他のユーザーの参加を待っています"
            self.collectionView.isUserInteractionEnabled = true
        }
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
            self.db.collection("rooms").document("room\(self.roomNumber)").updateData(["\(self.myUUID)": FieldValue.delete(),]){ err in
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
    
    func createRandomCardsForLocalPlayMode() {
        for i in 1...30 {
            inabaCards += [CardData(imageName: "ina\(i > 15 ? i - 15 : i)", isOpened: false, isMatched: false)]
        }
        inabaCards.shuffle()
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

        switch gameType {
        case .fightWithYourself:
            if inabaCards[indexPath.row].isOpened == false {
                self.inabaCards[indexPath.row].isOpened = true
                //フリップ1回目　カードをめくり、カウントを＋1と　めくったカードのindexを記録
                if self.flipCount == 1 {
                    self.flipCount += 1
                    self.flippedCard[0] = indexPath.row
                }else {
                    //フリップ２回目　２枚がマッチしてるかジャッジ
                    self.flippedCard[1] = indexPath.row
                    if (inabaCards[flippedCard[0]].imageName) == (inabaCards[flippedCard[1]].imageName) {
                        print("マッチした！")
                        print("マッチ結果: \(inabaCards[flippedCard[0]]), \(inabaCards[flippedCard[1]])")
                        print("flippedCard: \(flippedCard)")
                        //マッチした！両方のカードのisMatchedをtrueにする
                        inabaCards[flippedCard[0]].isMatched = true
                        inabaCards[flippedCard[1]].isMatched = true
                        self.flipCount = 1
                        self.flippedCard = [0,0]
                    }else {
                        print("マッチしませんでした")
                        print("マッチ結果: \(inabaCards[flippedCard[1]]), \(inabaCards[flippedCard[1]])")
                        print("flippedCard: \(flippedCard)")
                        collectionView.isUserInteractionEnabled = false
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                            //マッチしてないので、両方閉じる
                            self.inabaCards[self.flippedCard[0]].isOpened = false
                            self.inabaCards[self.flippedCard[1]].isOpened = false
                            self.flipCount = 1
                            self.flippedCard = [0,0]
                            collectionView.isUserInteractionEnabled = true
                            collectionView.reloadData()
                        }
                    }
                }
            }
            collectionView.reloadData()
        case .playWithCpu:
            break
        case .fireStoreOnline:
            if inabaCards[indexPath.row].isOpened == false {
                if flipCount == 1 {
                    print("flipCount: \(self.flipCount)")
                    flipCount += 1
                    flippedCard[0] = indexPath.row
                    db.collection("rooms").document("room\(roomNumber)").collection("cardData").document("cardData\(flippedCard[0] + 1)").setData([
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
                        db.collection("rooms").document("room\(roomNumber)").collection("cardData").document("cardData\(flippedCard[1] + 1)").setData([
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
                        print("マッチしませんでした\nカードを覚えておきましょう♪")
                        self.navigationMessageLabel.text = "マッチしませんでした\nカードを覚えておきましょう♪"
                        print("マッチ結果: \(inabaCards[flippedCard[1]]), \(inabaCards[flippedCard[1]])")
                        print("flippedCard: \(flippedCard)")
                        collectionView.isUserInteractionEnabled = false
                        //ここで一旦　isOpened: trueだけ送信する
                        print("ここで一旦　isOpened: trueだけ送信する")
                        db.collection("rooms").document("room\(roomNumber)").collection("cardData").document("cardData\(flippedCard[1] + 1)").setData([
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
                            self.db.collection("rooms").document("room\(self.roomNumber)").collection("cardData").document("cardData\(self.flippedCard[0] + 1)").setData([
                                "isOpened": false,
                            ], merge: true) { err in
                                print("indexPath.row: \(self.flippedCard[0])のisOpenedをtrue, isMatchedをtrueにした")
                                if let err = err {
                                    print("errです: \(err)")
                                }else {
                                    print("setData Succesful")
                                }
                            }
                            self.db.collection("rooms").document("room\(self.roomNumber)").collection("cardData").document("cardData\(self.flippedCard[1] + 1)").setData([
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
                                .document("room\(self.roomNumber)")
                                .setData(["currentFlippingPlayer": "player\(self.myPlayerNumber)" == "player1" ? "player2" : "player1"], merge: true)
                            self.navigationMessageLabel.text = "相手のターンです"
                            collectionView.isUserInteractionEnabled = false
                        }
                    }
                }
            }
        case .none:
            break
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
