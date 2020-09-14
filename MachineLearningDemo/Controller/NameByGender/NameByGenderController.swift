
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