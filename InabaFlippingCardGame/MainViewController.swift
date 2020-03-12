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

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        
        //other
        startButton.rx.tap.subscribe{ _ in
            let vc = PlayGameViewController.instantiate()
            let navi = UINavigationController(rootViewController: vc)
            navi.modalPresentationStyle = .fullScreen
            self.present(navi, animated: true, completion: nil)
//            self.navigationController?.pushViewController(vc, animated: true)
            
        }.disposed(by: dispopseBag)
    }
    
    @IBAction func setData(_ sender: Any) {
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
        }
        
        
//        for i in 1...15 {
//                db.collection("currentGameTableData").document("cardData\(i)").setData([
////                    "imageName": "ina\(i)"
//                    "isOpened": false,
//                    "isMatched": false
//                ], merge: true) { err in
//                    print(i)
//                    if let err = err {
//                        print("errです: \(err)")
//                    }else {
//                        print("setData Succesful")
//                    }
//                }
//                db.collection("currentGameTableData").document("cardData\(i + 15)").setData([
////                    "imageName": "ina\(i)"
//                    "isOpened": false,
//                    "isMatched": false
//                ], merge: true) { err in
//                    print(i)
//                    if let err = err {
//                        print("errです: \(err)")
//                    }else {
//                        print("setData Succesful(+15)")
//                    }
//                }
//        }
        
    }
    

}

