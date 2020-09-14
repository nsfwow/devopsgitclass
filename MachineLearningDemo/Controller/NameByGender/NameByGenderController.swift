
//
//  ViewController.swift
//  GenderByName
//
//  Created by Rafael Aguilera on 11/21/17.
//  Copyright © 2017 Rafael Aguilera. All rights reserved.
//

import UIKit

class NameByGenderController: UIViewController, UITextFieldDelegate {

    //MARK: Properties
    
    //MARK: Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var getGenderButton: UIButton!
    @IBOutlet weak var nextDemoButton: UIButton!
    
    //MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        Helper.makeButtonRounded(button: getGenderButton)
        Helper.makeButtonRounded(button: nextDemoButton)
        nameTextField.delegate = self
    }

    //MARK: Actions
    @IBAction func didTapGetGenderButton(_ sender: UIButton) {
        guard (nameTextField.text?.isEmpty)! else{
            genderLabel.text = predictGenderFromName(name: (nameTextField.text)!)
            return
        }
    }
    
    //MARK: Methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard (nameTextField.text?.isEmpty)! else{
            genderLabel.text = predictGenderFromName(name: (nameTextField.text)!)
            return true
        }
        return true
    }
    
    func features(string:String) -> [String:Double]{
        guard !string.isEmpty else{return[:]}
        let string = string.lowercased()
        var keys = [String]()
        keys.append("firsLetter1=\(string.prefix(1))")
        keys.append("firsLetter2=\(string.prefix(2))")
        keys.append("firsLetter3=\(string.prefix(3))")
        keys.append("lastLetter1=\(string.suffix(1))")
        keys.append("lastLetter1=\(string.suffix(2))")
        keys.append("lastLetter1=\(string.suffix(3))")
        return keys.reduce([String:Double](), { (result, key) -> [String:Double] in
            var result = result
            result[key] = 1.0
            return result
        })
    }
    
    func predictGenderFromName(name:String) -> String?{
        let namesFeatures = features(string: name)
        let model = GenderByName()
        if let prediction = try? model.prediction(input: namesFeatures){
            if prediction.classLabel == "F"{
                return "Female"
            }else{
                return "Male"
            }
        }
        return nil
    }
}
