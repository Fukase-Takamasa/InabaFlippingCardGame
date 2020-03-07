//
//  TableViewUtil.swift
//  InabaFlippingCardGame
//
//  Created by 深瀬貴将 on 2020/03/08.
//  Copyright © 2020 fukase. All rights reserved.
//

import Foundation
import UIKit

open class TableViewUtil {
    static func registerCell(_ tableView: UITableView, identifier: String) {
        tableView.register(UINib(nibName: identifier, bundle: nil), forCellReuseIdentifier: identifier)
    }
    
    static func createCell(_ tableView: UITableView, identifier: String, _ indexPath: IndexPath) -> (UITableViewCell) {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        return cell
    }
    
}
