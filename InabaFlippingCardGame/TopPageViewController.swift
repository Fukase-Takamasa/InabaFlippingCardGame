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

    @IBOutlet weak var fightWithYourselfButton: UIButton!
    @IBOutlet weak var playWithCpuButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()

        TableViewUtil.registerCell(tableView, identifier: TopPageRoomListCell.reusableIdentifier)
        
        //other
//        createNewGameButton.rx.tap.subscribe{ _ in
//            let start = Date()
//            HUD.show(.progress)
//            for i in 1...30 {
//                self.db.collection("currentGameTableData").document("cardData\(i)").setData([
//                    "imageName": "ina\(i > 15 ? (i - 15) : (i))",  //←3項演算子
//                    "isOpened": false,
//                    "isMatched": false,
//                    "id": i
//                ], merge: true) { err in
//                    self.CompOrErr(err: err, i: i, start)
//                }
//            }
//        }.disposed(by: dispopseBag)
    }
    
    func CompOrErr(err: Error?, i: Int, _ start: Date) {
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
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
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
            case 0:
                cell.roomStateLabel.text = "参加する"
                cell.roomStateLabelBaseView.backgroundColor = UIColor.systemTeal
            case 1:
                cell.roomStateLabel.text = "観戦する"
                cell.roomStateLabelBaseView.backgroundColor = UIColor.systemOrange
            case 5:
                cell.roomStateLabel.text = "観戦する"
                cell.roomStateLabelBaseView.backgroundColor = UIColor.systemOrange
            default:
                cell.roomStateLabel.text = "参加する"
                cell.roomStateLabelBaseView.backgroundColor = UIColor.systemTeal
            }
            cell.roomNameLabel.text = "ルーム10\(indexPath.row + 1)"
            return cell
        }
    }
    
}

