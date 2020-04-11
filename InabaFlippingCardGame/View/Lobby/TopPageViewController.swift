//
//  TopPageViewController.swift
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

struct Rooms {
    var documentID: String
    var roomName: String
    var playerCount: Int
}

enum AlertType {
    case full
    case error
    case comingSoon
    case newRoomName
}

class TopPageViewController: UIViewController, StoryboardInstantiatable {
    
    let dispopseBag = DisposeBag()
    var uuidString = UUID().uuidString
    var db: Firestore!
    var alertType: AlertType?
    var rooms: [Rooms] = []
    var start = Date()

    @IBOutlet weak var playerNameTextField: UITextField!
    @IBOutlet weak var fightWithYourselfButton: UIButton!
    @IBOutlet weak var playWithCpuButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TableViewUtil.registerCell(tableView, identifier: TopPageRoomListCell.reusableIdentifier)
        playerNameTextField.delegate = self
        //placeHolderテキストの色を深緑の背景でも見やすいように　少し明るい色に変更
        playerNameTextField.attributedPlaceholder = NSAttributedString(string: "ニックネーム未設定", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightText])
        playerNameTextField.tintColor = .systemOrange

        db = Firestore.firestore()
        //ロビーに表示するオンラインルーム一覧情報の自動更新を設定
        db.collection("rooms").order(by: "defaultRoom").addSnapshotListener{ snapshot, err in
            guard let snapshot = snapshot else {
                print("snapshotListener Error: \(String(describing: err))"); return
            }
            self.rooms = snapshot.documents.map { data -> Rooms in
                guard let roomName = data.data()["roomName"] else {
                    print("roomNameアンラップ失敗")
                    return Rooms(documentID: "nil", roomName: "nil", playerCount: 0)
                }
                return Rooms(documentID: data.documentID, roomName: roomName as! String, playerCount: data.data().count - 3)
            }
            self.tableView.reloadData()
        }
        
        //RxメソッドとFirestore
        tableView.rx.itemSelected.subscribe(onNext: { [unowned self] indexPath in
            let row = indexPath.row
            //セルタップするごとに新しい値を生成
            self.uuidString = UUID().uuidString
            HUD.show(.progress)
            //処理時間を計測するため、tableViewタップ時に処理開始時間を更新
            self.start = Date()
            if indexPath.section == 0 {
                self.showAlert(type: .newRoomName)
            }else {
                self.db.collection("rooms").document(self.rooms[row].documentID).getDocument { (docListSnapshot, err) in
                    guard let docList = docListSnapshot?.data() else {
                        if let err = err {
                            print("getDocument Error: \(String(describing: err))")
                        }else { print("docListが空です") }
                        self.showAlert(type: .error)
                        return
                    }
                    print("docList取得成功 データ数: \(docList.count - 3)")
                    print("docList中身: \(docList)")
                    if (docList.count - 3) > 1 {
                        print("ルームが満室です。")
                        self.showAlert(type: .full)
                    }else {
                        print("ルームに入室可能です\n接続を開始します。")
                        self.connectToExistingRoom(self.rooms[row].documentID, self.rooms[row].roomName, docList.count - 3)
                    }
                }
            }
        }).disposed(by: dispopseBag)
        
        fightWithYourselfButton.rx.tap.subscribe{ _ in
            let vc = PlayGameFightWithYourselfViewController.instantiate()
//            vc.modalPresentationStyle = .fullScreen
            self.navigationController?.pushViewController(vc, animated: true)
//            self.present(vc, animated: true)
        }.disposed(by: dispopseBag)
        
        playWithCpuButton.rx.tap.subscribe{ _ in
            self.showAlert(type: .comingSoon)
        }.disposed(by: dispopseBag)
    }
    
    func createNewRoom(_ documentID: String, _ roomName: String) {
        self.db.collection("rooms")
            .document(documentID)
            .setData([
                "roomName": roomName,
                "defaultRoom": false,
                "currentFlippingPlayer": "player1",
                "\(self.uuidString)": self.playerNameTextField.text == "" ? "名無しさん" : self.playerNameTextField.text ?? "名無しさん",
            ], merge: true) { err in
                //Firestoreのデータ構造作り替えるまで、仮で乱数のdocumentIDにUUIDを代用（ルーム名を被った値をユーザーが入力する可能性があるため）
                self.setCardData(documentID, roomName)
        }
    }
    
    func connectToExistingRoom(_ documentID: String, _ roomName: String, _ playerCount: Int) {
        self.db.collection("rooms")
            .document(documentID)
            .setData([
                "currentFlippingPlayer": "player1",
                "\(self.uuidString)": self.playerNameTextField.text == "" ? "名無しさん" : self.playerNameTextField.text ?? "名無しさん",
            ], merge: true) { err in
                if playerCount < 1 {
                    self.setCardData(documentID, roomName)
                }else {
                    self.goToGamePage(documentID, roomName)
                }
        }
    }
    
    func setCardData(_ documentID: String, _ roomName: String) {
        for (i, random) in (1...30).shuffled().enumerated() {
            self.db.collection("rooms")
                .document("\(documentID)")
                .collection("cardData")
                .document("cardData\(i + 1)")
                .setData([
                    "imageName": "ina\(random > 15 ? (random - 15) : (random))",
                    "isOpened": false,
                    "isMatched": false,
                    "id": i + 1,
                    "correctedPlayer": ""
                ], merge: true) { err in
                    if let err = err {
                        print("setCardData Error: \(String(describing: err))")
                    }else {
                        self.setCardsCompOrErr(documentID, roomName, i + 1, err)
                    }
            }
        }
    }
    
    func setCardsCompOrErr(_ documentID: String, _ roomName: String , _ i: Int, _ err: Error?) {
        if let err = err {
            print("index(\(i)) setCardDataErr: \(err)")
        }else {
            print("setData Succesful (\(i))")
            if i == 30 {
                print("30 Cards data set completed!")
                self.goToGamePage(documentID, roomName)
            }
        }
    }
    
    //documentIDを引数にしている理由　ルーム新規作成時は作成者のUUIDを代用してるが、既存ルームのIDはsnapshotから取得するため、両パターンに備えて引数にしている
    func goToGamePage(_ documentID: String, _ roomName: String) {
        HUD.flash(.success, delay: 1) { (Bool) in
            let vc = PlayGameViewController.instantiate()
            vc.roomDocumentID = documentID
            vc.roomName = roomName
            vc.myUUID = self.uuidString
            print("処理時間: \(Date().timeIntervalSince(self.start - 1))秒")
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func showAlert(type: AlertType?) {
        HUD.hide()
        alertType = type
        var alert: UIAlertController!
        let ok = UIAlertAction(title: "OK", style: .default) { (UIAlertAction) in }
        switch alertType {
            //後で余裕があれば、他のルームに自動で接続し直しますか？を作る　それでも他の部屋が満室なら自動で新しい部屋を作成し、新しい部屋を作成しました　のアラートを出す
        case .full:
            alert = UIAlertController(title: "このルームは満室です", message: "ルームを変更するか「＋今すぐ作成」\nをお試しください", preferredStyle: .alert)
            alert.addAction(ok)
        case .error:
            alert = UIAlertController(title: "接続に失敗しました", message: "通信状況を確認するか、時間を空けてまたお試しください", preferredStyle: .alert)
            alert.addAction(ok)
        case .comingSoon:
            alert = UIAlertController(title: "この機能は準備中です", message: "乞うご期待!", preferredStyle: .alert)
            alert.addAction(ok)
        case .newRoomName:
            alert = UIAlertController(title: "ルーム名を入力", message: "好きなルーム名を入力してください", preferredStyle: .alert)
            var alertTextField = UITextField()
            alert.addTextField { (UITextField) in
                UITextField.placeholder = "ルーム名を入力"
                alertTextField = UITextField }
            let create = UIAlertAction(title: "作成", style: .default) { (UIAlertAction) in
                guard let roomName = alertTextField.text else {
                    print("alertTextField.textがnil"); return }
                //ここで入力値を拾ってdb通信
                HUD.show(.progress)
                self.createNewRoom("\(self.uuidString)Room", roomName)
            }
            let cancel = UIAlertAction(title: "キャンセル", style: .cancel) { (UIAlertAction) in }
            alert.addAction(create)
            alert.addAction(cancel)
        case .none:
            break
        }
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension TopPageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "新しいルームを作る"
        }else {
            return "だれかのゲームに参加する"
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else {
            return rooms.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let cell = TableViewUtil.createCell(tableView, identifier: TopPageRoomListCell.reusableIdentifier, indexPath) as! TopPageRoomListCell
        if section == 0 {
            cell.roomNameLabel.text = " ＋ 今すぐ作成"
            cell.playerCountLabel.text = ""
            cell.roomStateLabelBaseView.isHidden = true
            return cell
        }else {
            cell.roomStateLabelBaseView.isHidden = false
            cell.roomNameLabel.text = rooms[row].roomName
            cell.playerCountLabel.text = "\(rooms[row].playerCount)/2人"
            if rooms[row].playerCount < 2 {
                cell.roomStateLabel.text = "参加する"
                cell.roomStateLabelBaseView.backgroundColor = UIColor.systemTeal
            }else {
                cell.roomStateLabel.text = "満室"
                cell.roomStateLabelBaseView.backgroundColor = UIColor.systemOrange
            }
            
            //デフォの区切り線を使いつつ、セルが無いところはフッターで埋めて区切り線を見えなくする
            tableView.tableFooterView = UIView()
            return cell
        }
    }
    
}

extension TopPageViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

