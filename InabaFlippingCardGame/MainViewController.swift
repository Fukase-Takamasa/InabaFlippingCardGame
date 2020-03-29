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

    @IBOutlet weak var fightWithYourselfButton: UIButton!
    @IBOutlet weak var playWithCpuButton: UIButton!
    @IBOutlet weak var createNewGameButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        
        //other
        createNewGameButton.rx.tap.subscribe{ _ in
            let start = Date()
            HUD.show(.progress)
            for i in 1...30 {
                self.db.collection("currentGameTableData").document("cardData\(i)").setData([
                    "imageName": "ina\(i > 15 ? (i - 15) : (i))",  //←3項演算子
                    "isOpened": false,
                    "isMatched": false,
                    "id": i
                ], merge: true) { err in
                    self.CompOrErr(err: err, i: i, start)
                }
            }
        }.disposed(by: dispopseBag)
    }
    
    func CompOrErr(err: Error?, i: Int, _ start: Date) {
        if let err = err {
            print("index(\(i))errです: \(err)")
        }else {
            print("setData Succesful (\(i))")
            if i == 30 {
                let elapsedTime = Date().timeIntervalSince(start)
                print("30 Cards data set completed!")
                print("処理時間: \(elapsedTime)")
                HUD.flash(.success, delay: 1) { (Bool) in
                    let vc = PlayGameViewController.instantiate()
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

extension PlayGameViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    
}

