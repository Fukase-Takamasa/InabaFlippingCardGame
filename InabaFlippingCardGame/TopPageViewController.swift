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
    
    let dispopseBag = DisposeBag()
    var db: Firestore!
    let uuidString = UUID().uuidString

    @IBOutlet weak var fightWithYourselfButton: UIButton!
    @IBOutlet weak var playWithCpuButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        db = Firestore.firestore()

        TableViewUtil.registerCell(tableView, identifier: TopPageRoomListCell.reusableIdentifier)
        
        //other
        fightWithYourselfButton.rx.tap.subscribe{ _ in
            self.showAlert()
        }.disposed(by: dispopseBag)
        
        playWithCpuButton.rx.tap.subscribe{ _ in
            self.showAlert()
        }.disposed(by: dispopseBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [unowned self] indexPath in
            let start = Date()
            if indexPath.section == 0 {
                self.showAlert()
            }else {
                HUD.show(.progress)
                self.db.collection("rooms")
                    .document("room\(indexPath.row + 1)")
                    .setData([
                        "\(self.uuidString)": "田中 太郎",
                        "currentFlippingPlayer": "player1"
                    ], merge: true)
                for i in 1...30 {
                    self.db.collection("rooms")
                        .document("room\(indexPath.row + 1)")
                        .collection("cardData")
                        .document("cardData\(i)")
                        .setData([
                            "imageName": "ina\(i > 15 ? (i - 15) : (i))",  //←3項演算子
                            "isOpened": false,
                            "isMatched": false,
                            "id": i
                        ], merge: true) { err in
                            self.CompOrErr(err: err, i: i, start, row: indexPath.row)
                    }
                }
            }
            
//            self.db.collection("test").getDocuments(completion: { (snapshot, err) in
//                if let snapshot = snapshot {
//                    print("snapshot: \(snapshot.documents[0]["name"])")
//                    if snapshot.isEmpty {
//                        print("snapshotはからです")
//                    }else {
//                        print("snapshotはからではない")
//                    }
//                }else {
//                    print("snapshotが存在しない")
//                }
//                if let err = err {
//                    print("err: \(err)")
//                }else {
//                    print("errが存在しない")
//                }
//            })
            

//            let start = Date()
//            HUD.show(.progress)
//            for i in 1...30 {
//                self.db.collection("ルーム\()").document("cardData\(i)").setData([
//                    "imageName": "ina\(i > 15 ? (i - 15) : (i))",  //←3項演算子
//                    "isOpened": false,
//                    "isMatched": false,
//                    "id": i
//                ], merge: true) { err in
//                    self.CompOrErr(err: err, i: i, start)
//                }
//            }
        }).disposed(by: dispopseBag)

    }
    
    func CompOrErr(err: Error?, i: Int, _ start: Date, row: Int) {
        if let err = err {
            print("index(\(i))errです: \(err)")
        }else {
            print("setData Succesful (\(i))")
            if i == 30 {
                let elapsedTime = Date().timeIntervalSince(start)
                print("30 Cards data set completed!")
                print("処理時間: \(elapsedTime)秒")
                HUD.flash(.success, delay: 1) { (Bool) in
                    let vc = PlayGameViewController.instantiate()
                    vc.roomNumber = (row + 1)
                    vc.myUUID = self.uuidString
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "この機能は準備中です", message: "乞うご期待!", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { (UIAlertAction) in}
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
            return 10
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TableViewUtil.createCell(tableView, identifier: TopPageRoomListCell.reusableIdentifier, indexPath) as! TopPageRoomListCell
        if indexPath.section == 0 {
            cell.roomNameLabel.text = " ＋ 今すぐ作成"
            cell.roomStateLabelBaseView.isHidden = true
            return cell
        }else {
            switch indexPath.row {
            case 9:
                cell.roomNameLabel.text = "ルーム1\(indexPath.row + 1)　　1/2人"
                cell.roomStateLabel.text = "参加する"
                cell.roomStateLabelBaseView.isHidden = false
            default:
                cell.roomNameLabel.text = "ルーム10\(indexPath.row + 1)　　0/2人"
                cell.roomStateLabel.text = "参加する"
                cell.roomStateLabelBaseView.backgroundColor = UIColor.systemTeal
            }
            cell.roomStateLabelBaseView.isHidden = false
            return cell
        }
    }
    
}

