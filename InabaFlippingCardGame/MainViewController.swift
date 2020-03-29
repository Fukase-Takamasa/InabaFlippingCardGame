//
//  ViewController.swift
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

class MainViewController: UIViewController, StoryboardInstantiatable {
    
    let dispopseBag = DisposeBag()
    var db: Firestore!
    var loadedIndex = 0

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        
        //other
        startButton.rx.tap.subscribe{ _ in
            let start = Date()
            HUD.show(.progress)
            for i in 1...30 {
                var imageIndex = i
                if i > 15 {
                    imageIndex -= 15
                }
                self.db.collection("currentGameTableData").document("cardData\(i)").setData([
                    "imageName": "ina\(imageIndex)",
                    "isOpened": false,
                    "isMatched": false,
                    "id": i
                ], merge: true) { err in
                    self.CompOrErr(err: err, i: i, start: start)
                }
            }
        }.disposed(by: dispopseBag)
    }
    
//            self.db.collection("currentGameTableData")
//                .document("cardData\(1)").setData(["imageName": "ina\(1)", "isOpened": false, "isMatched": false, "id": 1], merge: true) { err in
//                    self.CompOrErr(err: err, i: 1, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(2)").setData(["imageName": "ina\(2)", "isOpened": false, "isMatched": false, "id": 2], merge: true) { err in
//                    self.CompOrErr(err: err, i: 2, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(3)").setData(["imageName": "ina\(3)", "isOpened": false, "isMatched": false, "id": 3], merge: true) { err in
//                    self.CompOrErr(err: err, i: 3, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(4)").setData(["imageName": "ina\(4)", "isOpened": false, "isMatched": false, "id": 4], merge: true) { err in
//                    self.CompOrErr(err: err, i: 4, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(5)").setData(["imageName": "ina\(5)", "isOpened": false, "isMatched": false, "id": 5], merge: true) { err in
//                    self.CompOrErr(err: err, i: 5, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(6)").setData(["imageName": "ina\(6)", "isOpened": false, "isMatched": false, "id": 6], merge: true) { err in
//                    self.CompOrErr(err: err, i: 6, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(7)").setData(["imageName": "ina\(7)", "isOpened": false, "isMatched": false, "id": 7], merge: true) { err in
//                    self.CompOrErr(err: err, i: 7, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(8)").setData(["imageName": "ina\(8)", "isOpened": false, "isMatched": false, "id": 8], merge: true) { err in
//                    self.CompOrErr(err: err, i: 8, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(9)").setData(["imageName": "ina\(9)", "isOpened": false, "isMatched": false, "id": 9], merge: true) { err in
//                    self.CompOrErr(err: err, i: 9, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(10)").setData(["imageName": "ina\(10)", "isOpened": false, "isMatched": false, "id": 10], merge: true) { err in
//                    self.CompOrErr(err: err, i: 10, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(11)").setData(["imageName": "ina\(11)", "isOpened": false, "isMatched": false, "id": 11], merge: true) { err in
//                    self.CompOrErr(err: err, i: 11, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(12)").setData(["imageName": "ina\(12)", "isOpened": false, "isMatched": false, "id": 12], merge: true) { err in
//                    self.CompOrErr(err: err, i: 12, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(13)").setData(["imageName": "ina\(13)", "isOpened": false, "isMatched": false, "id": 13], merge: true) { err in
//                    self.CompOrErr(err: err, i: 13, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(14)").setData(["imageName": "ina\(14)", "isOpened": false, "isMatched": false, "id": 14], merge: true) { err in
//                    self.CompOrErr(err: err, i: 14, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(15)").setData(["imageName": "ina\(15)", "isOpened": false, "isMatched": false, "id": 15], merge: true) { err in
//                    self.CompOrErr(err: err, i: 15, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(16)").setData(["imageName": "ina\(1)", "isOpened": false, "isMatched": false, "id": 16], merge: true) { err in
//                    self.CompOrErr(err: err, i: 16, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(17)").setData(["imageName": "ina\(2)", "isOpened": false, "isMatched": false, "id": 17], merge: true) { err in
//                    self.CompOrErr(err: err, i: 17, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(18)").setData(["imageName": "ina\(3)", "isOpened": false, "isMatched": false, "id": 18], merge: true) { err in
//                    self.CompOrErr(err: err, i: 18, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(19)").setData(["imageName": "ina\(4)", "isOpened": false, "isMatched": false, "id": 19], merge: true) { err in
//                    self.CompOrErr(err: err, i: 19, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(20)").setData(["imageName": "ina\(5)", "isOpened": false, "isMatched": false, "id": 20], merge: true) { err in
//                    self.CompOrErr(err: err, i: 20, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(21)").setData(["imageName": "ina\(6)", "isOpened": false, "isMatched": false, "id": 21], merge: true) { err in
//                    self.CompOrErr(err: err, i: 21, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(22)").setData(["imageName": "ina\(7)", "isOpened": false, "isMatched": false, "id": 22], merge: true) { err in
//                    self.CompOrErr(err: err, i: 22, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(23)").setData(["imageName": "ina\(8)", "isOpened": false, "isMatched": false, "id": 23], merge: true) { err in
//                    self.CompOrErr(err: err, i: 23, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(24)").setData(["imageName": "ina\(9)", "isOpened": false, "isMatched": false, "id": 24], merge: true) { err in
//                    self.CompOrErr(err: err, i: 24, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(25)").setData(["imageName": "ina\(10)", "isOpened": false, "isMatched": false, "id": 25], merge: true) { err in
//                    self.CompOrErr(err: err, i: 25, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(26)").setData(["imageName": "ina\(11)", "isOpened": false, "isMatched": false, "id": 26], merge: true) { err in
//                    self.CompOrErr(err: err, i: 26, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(27)").setData(["imageName": "ina\(12)", "isOpened": false, "isMatched": false, "id": 27], merge: true) { err in
//                    self.CompOrErr(err: err, i: 27, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(28)").setData(["imageName": "ina\(13)", "isOpened": false, "isMatched": false, "id": 28], merge: true) { err in
//                    self.CompOrErr(err: err, i: 28, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(29)").setData(["imageName": "ina\(14)", "isOpened": false, "isMatched": false, "id": 29], merge: true) { err in
//                    self.CompOrErr(err: err, i: 29, start: start)}
//            self.db.collection("currentGameTableData")
//                .document("cardData\(30)").setData(["imageName": "ina\(15)", "isOpened": false, "isMatched": false, "id": 30], merge: true) { err in
//                    self.CompOrErr(err: err, i: 30, start: start)}

    
    @IBAction func setData(_ sender: Any) {
        HUD.show(.progress)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            HUD.flash(.success, delay: 1.5) { (Bool) in
                HUD.hide()
            }
        }
        for i in 1...15 {
            db.collection("currentGameTableData").document("cardData\(i)").setData([
                "imageName": "ina\(i)",
                "isOpened": false,
                "isMatched": false,
                "id": i
            ], merge: true) { err in
                print(i)
                if let err = err {
                    print("errです: \(err)")
                }else {
                    print("setData Succesful (\(i))")
                }
            }
            db.collection("currentGameTableData").document("cardData\(i + 15)").setData([
                "imageName": "ina\(i)",
                "isOpened": false,
                "isMatched": false,
                "id": (i + 15)
            ], merge: true) { err in
                print(i + 15)
                if let err = err {
                    print("errです: \(err)")
                }else {
                    print("setData Succesful(\(i + 15))")
                }
            }
            if (i + 15) == 30 {
                print("loaded completed")
            }
        }
    }
    
    
    
    func CompOrErr(err: Error?, i: Int, start: Date) {
        print(i)
        if let err = err {
            print("errです: \(err)")
        }else {
            print("setData Succesful (\(i))")
            self.loadedIndex += 1
            if self.loadedIndex == 30 {
                let elapsed = Date().timeIntervalSince(start)
                print("処理時間: \(elapsed)")
                self.loadedIndex = 0
                print("30 Cards data set completed!")
                HUD.flash(.success, delay: 1) { (Bool) in
                    let vc = PlayGameViewController.instantiate()
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

