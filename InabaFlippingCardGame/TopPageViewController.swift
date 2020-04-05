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

class TopPageViewController: UIViewController, StoryboardInstantiatable {
    
    struct Rooms {
        var roomName: String
        var playerCount: Int
    }
    
    enum AlertType {
        case error
        case full
        case comingSoon
    }
    
    let dispopseBag = DisposeBag()
    let uuidString = UUID().uuidString
    var db: Firestore!
    var alertType: AlertType?
    var rooms: [Rooms] = []
    var start = Date()
    var myPlayerName = "名無しさん"

    @IBOutlet weak var playerNameTextField: UITextField!
    @IBOutlet weak var fightWithYourselfButton: UIButton!
    @IBOutlet weak var playWithCpuButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TableViewUtil.registerCell(tableView, identifier: TopPageRoomListCell.reusableIdentifier)

        db = Firestore.firestore()
        //ロビーに表示するオンラインルーム一覧情報の自動更新を設定
        db.collection("rooms").addSnapshotListener{ snapshot, err in
            guard let snapshot = snapshot else {
                print("snapshotListener Error: \(String(describing: err))"); return
            }
            self.rooms = snapshot.documents.map { data -> Rooms in
                return Rooms(roomName: data.documentID, playerCount: data.data().count - 1)
            }
            self.tableView.reloadData()
        }
        
        //Rxメソッド
        tableView.rx.itemSelected.subscribe(onNext: { [unowned self] indexPath in
            HUD.show(.progress)
            //処理時間を計測するため、tableViewタップ時に処理開始時間を更新
            self.start = Date()
            if indexPath.section == 0 {
                self.showAlert(type: .comingSoon)
                self.tableView.deselectRow(at: indexPath, animated: true)
            }else {
                self.db.collection("rooms").document("room\(indexPath.row + 1)").getDocument { (docListSnapshot, err) in
                    guard let docList = docListSnapshot?.data() else {
                        if let err = err {
                            print("getDocument Error: \(String(describing: err))")
                        }else { print("docListが空です") }
                        self.showAlert(type: .error)
                        return
                    }
                    print("docList取得成功 データ数: \(docList.count)")
                    print("docList中身: \(docList)")
                    if docList.count > 2 {
                        print("ルームが満室です。")
                        self.showAlert(type: .full)
                    }else {
                        print("ルームに入室可能です\n接続を開始します。")
                        self.db.collection("rooms")
                            .document("room\(indexPath.row + 1)")
                            .setData([
                                "\(self.uuidString)": self.myPlayerName,
                                "currentFlippingPlayer": "player1"
                            ], merge: true) { err in
                                if docList.count == 1 {
                                    self.setCardData(indexPath: indexPath)
                                }else {
                                    self.goToGamePage(indexPath: indexPath)
                                }
                        }
                    }
                    
                }
            }
        }).disposed(by: dispopseBag)
        
        playerNameTextField.delegate = self
        playerNameTextField.rx.controlEvent(.editingChanged).asDriver()
            .drive(onNext: { _ in
                self.myPlayerName = self.playerNameTextField.text ?? "名無しさん"
                if self.playerNameTextField.text == "" {
                    self.myPlayerName = "名無しさん"
                }
            }).disposed(by: dispopseBag)
        playerNameTextField.rx.controlEvent(.editingDidEnd).asDriver()
            .drive(onNext: {
                if self.playerNameTextField.text == "" {
                    self.playerNameTextField.text = "ニックネーム未設定"
                    self.myPlayerName = "名無しさん"
                }
            }).disposed(by: dispopseBag)
        
        fightWithYourselfButton.rx.tap.subscribe{ _ in
            let vc = PlayGameViewController.instantiate()
            vc.gameType = .fightWithYourself
            self.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: dispopseBag)
        
        playWithCpuButton.rx.tap.subscribe{ _ in
            self.showAlert(type: .comingSoon)
        }.disposed(by: dispopseBag)
    }
    
    func setCardData(indexPath: IndexPath) {
        for (i, random) in (1...30).shuffled().enumerated() {
            self.db.collection("rooms")
                .document("room\(indexPath.row + 1)")
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
                        self.setCardsCompOrErr(i + 1, indexPath, err)
                    }
            }
        }
    }
    
    func setCardsCompOrErr( _ i: Int, _ indexPath: IndexPath, _ err: Error?) {
        if let err = err {
            print("index(\(i)) setCardDataErrです: \(err)")
        }else {
            print("setData Succesful (\(i))")
            if i == 30 {
                print("30 Cards data set completed!")
                self.goToGamePage(indexPath: indexPath)
            }
        }
    }
    
    func goToGamePage(indexPath: IndexPath) {
        HUD.flash(.success, delay: 1) { (Bool) in
            let vc = PlayGameViewController.instantiate()
            vc.roomNumber = (indexPath.row + 1)
            vc.myUUID = self.uuidString
            vc.gameType = .fireStoreOnline
            self.tableView.deselectRow(at: indexPath, animated: true)
            print("処理時間: \(Date().timeIntervalSince(self.start - 1))秒")
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func showAlert(type: AlertType?) {
        HUD.hide()
        var alert: UIAlertController!
        switch alertType {
            //後で余裕があれば、他のルームに自動で接続し直しますか？を作る　それでも他の部屋が満室なら自動で新しい部屋を作成し、新しい部屋を作成しました　のアラートを出す
        case .full:
            alert = UIAlertController(title: "このルームは満室です", message: "ルームを変更するか「＋今すぐ作成」\nをお試しください", preferredStyle: .alert)
        case .error:
            alert = UIAlertController(title: "接続に失敗しました", message: "通信状況を確認するか、時間を空けてまたお試しください", preferredStyle: .alert)
        case .comingSoon:
            alert = UIAlertController(title: "この機能は準備中です", message: "乞うご期待!", preferredStyle: .alert)
        case .none:
            break
        }
        let ok = UIAlertAction(title: "OK", style: .default) { (UIAlertAction) in }
        alert.addAction(ok)
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

