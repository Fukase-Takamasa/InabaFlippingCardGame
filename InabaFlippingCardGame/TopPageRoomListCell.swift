//
//  TopPageRoomListCell.swift
//  InabaFlippingCardGame
//
//  Created by 深瀬 貴将 on 2020/03/29.
//  Copyright © 2020 fukase. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Instantiate
import InstantiateStandard

class TopPageRoomListCell: UITableViewCell, Reusable {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var roomStateLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
