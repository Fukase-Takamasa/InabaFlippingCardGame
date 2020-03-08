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

class MainViewController: UIViewController, StoryboardInstantiatable {
    
    let dispopseBag = DisposeBag()

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //other
        startButton.rx.tap.subscribe{ _ in
            let vc = PlayGameViewController.instantiate()
            self.present(vc, animated: true, completion: nil)
//            self.navigationController?.pushViewController(vc, animated: true)
            
        }.disposed(by: dispopseBag)
    }


}

