//
//  IQKeyboardManager.swift
// https://github.com/hackiftekhar/IQKeyboardManager
// Copyright (c) 2013-16 Iftekhar Qurashi.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import Foundation
import CoreGraphics
import UIKit
import QuartzCore

///---------------------
/// MARK: IQToolbar tags
///---------------------

/**
Codeless drop-in universal library allows to prevent issues of keyboard sliding up and cover UITextField/UITextView. Neither need to write any code nor any setup required and much more. A generic version of KeyboardManagement. https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
*/

open class IQKeyboardManager: NSObject, UIGestureRecognizerDelegate {
    
    /**
    Default tag for toolbar with Done button   -1002.
    */
    fileprivate static let  kIQDoneButtonToolbarTag         =   -1002
    
    /**
    Default tag for toolbar with Previous/Next buttons -1005.
    */
    fileprivate static let  kIQPreviousNextButtonToolbarTag =   -1005
    
    ///---------------------------
    ///  MARK: UIKeyboard handling
    ///---------------------------
    
    /**
     Registered classes list with library.
     */
    fileprivate var registeredClasses  = [UIView.Type]()
    
    /**
    Enable/disable managing distance between keyboard and textField. Default is YES(Enabled when class loads in `+(void)load` method).
    */
    open var enable = false {
        
        didSet {
            //If not enable, enable it.
            if enable == true &&
                oldValue == false {
                //If keyboard is currently showing. Sending a fake notification for keyboardWillShow to adjust view according to keyboard.
                if _kbShowNotification != nil {
                    keyboardWillShow(_kbShowNotification)
                }
                showLog("Enabled")
            } else if enable == false &&
                oldValue == true {   //If not disable, desable it.
                keyboardWillHide(nil)
                showLog("Disabled")
            }
        }
    }
    
    fileprivate func privateIsEnabled()-> Bool {
        
        var isEnabled = enable
        
        if let textFieldViewController = _textFieldView?.viewController() {
            
            if isEnabled == false {
                
                //If viewController is kind of enable viewController class, then assuming it's enabled.
                for enabledClass in enabledDistanceHandlingClasses {
                    
                    if textFieldViewController.isKind(of: enabledClass) {
                        isEnabled = true
                        break
                    }
                }
            }
            
            if isEnabled == true {
                
                //If viewController is kind of disabled viewController class, then assuming it's disabled.
                for disabledClass in disabledDistanceHandlingClasses {
                    
                    if textFieldViewController.isKind