
//
//  Helper.Swift
//  Croma
//
//  Created by Rafael Aguilera on 11/13/17.
//  Copyright © 2017 Rafael Aguilera. All rights reserved.
//

import Foundation
import UIKit

//MARK: Helper Functions
class Helper{
    // Helper function to make an imageview circular
    static func makeImageViewCircle(imageView: UIImageView){
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
    }
    
    static func makeButtonRounded(button:UIButton){
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
    }
    
    static func intToMoney(amount: Int) -> String.SubSequence{
        let numberString = "\(amount)"
        let suff = numberString.suffix(2)
        var result = numberString.dropLast(2)
        result += "." + suff
        return result
    }
    
}