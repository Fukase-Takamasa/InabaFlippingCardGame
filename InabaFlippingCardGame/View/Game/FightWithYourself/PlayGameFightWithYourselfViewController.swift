//
//  PlayGameFightWithYourselfViewController.swift
//  InabaFlippingCardGame
//
//  Created by 深瀬 貴将 on 2020/04/09.
//  Copyright © 2020 fukase. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Instantiate
import InstantiateStandard

class PlayGameFightWithYourselfViewController: UIViewController, StoryboardInstantiatable {

    struct CardData {
        var imageName: String
        var isOpened: Bool
        var isMatched: Bool
    }
    
    let disposeBag = DisposeBag()
    var inabaCards: [CardData] = []
    var flipCount = 1
    var flippedCard = [0, 0]
    var turnCount = 50
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var turnCountLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CollectionViewUtil.registerCell(collectionView, identifier: CardCell.reusableIdentifier)
        turnCountLabel.text = String(turnCount)
        createRandomCardsForLocalPlayMode()
        
        //Rxメソッド
        backButton.rx.tap.subscribe({ _ in
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
    }
    
    func createRandomCardsForLocalPlayMode() {
        for i in (1...30).shuffled() {
            inabaCards += [CardData(imageName: "ina\(i > 15 ? i - 15 : i)", isOpened: false, isMatched: false)]
        }
    }
    
}

extension PlayGameFightWithYourselfViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return inabaCards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = CollectionViewUtil.createCell(collectionView, identifier: CardCell.reusableIdentifier, indexPath) as! CardCell
        if inabaCards[indexPath.row].isMatched || inabaCards[indexPath.row].isOpened {
            cell.imageView.contentMode = .scaleAspectFit
            print("生成時: isMatchedがtrue")
            cell.imageView.image = UIImage(named: inabaCards[indexPath.row].imageName)!
        }else {
            cell.imageView.contentMode = .scaleToFill
            print("生成時: isMatchedがfalse")
            if indexPath.row % 2 == 0 {
                cell.imageView.image = UIImage(named: "CardBackImageRed")
            }else {
                cell.imageView.image = UIImage(named: "CardBackImageBlue")
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("inabaCards: \(inabaCards)")
        
        if inabaCards[indexPath.row].isOpened == false {
            self.inabaCards[indexPath.row].isOpened = true
            //フリップ1回目　カードをめくり、カウントを＋1と　めくったカードのindexを記録
            if self.flipCount == 1 {
                self.flipCount += 1
                self.flippedCard[0] = indexPath.row
            }else {
                turnCount -= 1
                //フリップ２回目　２枚がマッチしてるかジャッジ
                self.flippedCard[1] = indexPath.row
                if (inabaCards[flippedCard[0]].imageName) == (inabaCards[flippedCard[1]].imageName) {
                    print("マッチした！")
                    print("マッチ結果: \(inabaCards[flippedCard[0]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    //マッチした！両方のカードのisMatchedをtrueにする
                    inabaCards[flippedCard[0]].isMatched = true
                    inabaCards[flippedCard[1]].isMatched = true
                    self.flipCount = 1
                    self.flippedCard = [0,0]
                    turnCountLabel.text = String(turnCount)
                }else {
                    print("マッチしませんでした")
                    print("マッチ結果: \(inabaCards[flippedCard[1]]), \(inabaCards[flippedCard[1]])")
                    print("flippedCard: \(flippedCard)")
                    collectionView.isUserInteractionEnabled = false
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                        //マッチしてないので、両方閉じる
                        self.inabaCards[self.flippedCard[0]].isOpened = false
                        self.inabaCards[self.flippedCard[1]].isOpened = false
                        self.flipCount = 1
                        self.flippedCard = [0,0]
                        self.turnCountLabel.text = String(self.turnCount)
                        collectionView.isUserInteractionEnabled = true
                        collectionView.reloadData()
                    }
                }
            }
        }
        collectionView.reloadData()
    }
}

extension PlayGameFightWithYourselfViewController: UICollectionViewDelegateFlowLayout {
    //セクションの外側余白
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    //セルサイズ
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (self.collectionView.bounds.width / 6) - (1.4 * (6 - 1))
        let cellHeight = (self.collectionView.bounds.height / 5) - (2 * (5 - 1))
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    //列間の余白（□□□
    //
    //　　　　　　□□□）
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    //行間の余白（□ ＜ー＞　□）？？
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
