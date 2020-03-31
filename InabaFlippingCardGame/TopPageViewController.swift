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
    var thirtyNumbers: [Int] = []
    var myPlayerName = "名無しさん"

    @IBOutlet weak var playerNameTextField: UITextField!
    @IBOutlet weak var fightWithYourselfButton: UIButton!
    @IBOutlet weak var playWithCpuButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 1...30 {
            thirtyNumbers += [i]
        }

        db = Firestore.firestore()

        TableViewUtil.registerCell(tableView, identifier: TopPageRoomListCell.reusableIdentifier)
        
        //other
        playerNameTextField.delegate = self
        playerNameTextField.rx.controlEvent(.editingChanged).asDriver()
            .drive(onNext: { _ in
                self.myPlayerName = self.playerNameTextField.text ?? "名無しさん"
                if self.playerNameTextField.text == "" {
                    self.myPlayerName = "名無しさん"
                }
            }).disposed(by: dispopseBag)
        
        fightWithYourselfButton.rx.tap.subscribe{ _ in
            self.showAlert()
        }.disposed(by: dispopseBag)
        
        playWithCpuButton.rx.tap.subscribe{ _ in
            self.showAlert()
        }.disposed(by: dispopseBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [unowned self] indexPath in
            print("シャッフル前: \(self.thirtyNumbers)")
            let start = Date()
            if indexPath.section == 0 {
                self.showAlert()
                self.tableView.deselectRow(at: indexPath, animated: true)
            }else {
                //セルタップするごとに1~30の数字をシャッフル
                self.thirtyNumbers.shuffle()
                print("シャッフル後: \(self.thirtyNumbers)")
                HUD.show(.progress)
                self.db.collection("rooms")
                    .document("room\(indexPath.row + 1)")
                    .setData([
                        "\(self.uuidString)": self.myPlayerName,
                        "currentFlippingPlayer": "player1"
                    ], merge: true)
                for i in 1...30 {
                    let random = self.thirtyNumbers[i - 1]
                    self.db.collection("rooms")
                        .document("room\(indexPath.row + 1)")
                        .collection("cardData")
                        .document("cardData\(random)")
                        .setData([
                            "imageName": "ina\(i > 15 ? (i - 15) : (i))",  //←3項演算子
                            "isOpened": false,
                            "isMatched": false,
                            "id": random
                        ], merge: true) { err in
                            self.CompOrErr(err, i, start, indexPath)
                    }
                }
            }
        }).disposed(by: dispopseBag)

    }
    
    func CompOrErr(_ err: Error?, _ i: Int, _ start: Date, _ indexPath: IndexPath) {
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
                    vc.roomNumber = (indexPath.row + 1)
                    vc.myUUID = self.uuidString
                    self.tableView.deselectRow(at: indexPath, animated: true)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "この機能は準備中です", message: "乞うご期待!", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { (UIAlertAction) in
        }
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

extension TopPageViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

