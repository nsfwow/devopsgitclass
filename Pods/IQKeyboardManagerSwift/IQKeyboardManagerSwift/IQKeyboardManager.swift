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
                    
                    if textFieldViewController.isKind(of: disabledClass) {
                        isEnabled = false
                        break
                    }
                }
                
                //Special Controllers
                if isEnabled == true {
                    
                    let classNameString = NSStringFromClass(type(of:textFieldViewController.self))
                    
                    //_UIAlertControllerTextFieldViewController
                    if (classNameString.contains("UIAlertController") && classNameString.hasSuffix("TextFieldViewController")) {
                        isEnabled = false
                    }
                }
            }
        }
        
        return isEnabled
    }
    
    /**
    To set keyboard distance from textField. can't be less than zero. Default is 10.0.
    */
    open var keyboardDistanceFromTextField: CGFloat {
        
        set {
            _privateKeyboardDistanceFromTextField =  max(0, newValue)
            showLog("keyboardDistanceFromTextField: \(_privateKeyboardDistanceFromTextField)")
        }
        get {
            return _privateKeyboardDistanceFromTextField
        }
    }
    
    /**
     Boolean to know if keyboard is showing.
     */
    open var keyboardShowing: Bool {
        
        get {
            return _privateIsKeyboardShowing
        }
    }
    
    /**
     moved distance to the top used to maintain distance between keyboard and textField. Most of the time this will be a positive value.
     */
    open var movedDistance: CGFloat {
        
        get {
            return _privateMovedDistance
        }
    }

    /**
    Prevent keyboard manager to slide up the rootView to more than keyboard height. Default is YES.
    */
    open var preventShowingBottomBlankSpace = true
    
    /**
    Returns the default singleton instance.
    */
    @objc open class func sharedManager() -> IQKeyboardManager {
        
        struct Static {
            //Singleton instance. Initializing keyboard manger.
            static let kbManager = IQKeyboardManager()
        }
        
        /** @return Returns the default singleton instance. */
        return Static.kbManager
    }
    
    ///-------------------------
    /// MARK: IQToolbar handling
    ///-------------------------
    
    /**
    Automatic add the IQToolbar functionality. Default is YES.
    */
    open var enableAutoToolbar = true {
        
        didSet {

            privateIsEnableAutoToolbar() ?addToolbarIfRequired():removeToolbarIfRequired()

            let enableToolbar = enableAutoToolbar ? "Yes" : "NO"

            showLog("enableAutoToolbar: \(enableToolbar)")
        }
    }
    
    fileprivate func privateIsEnableAutoToolbar() -> Bool {
        
        var enableToolbar = enableAutoToolbar
        
        if let textFieldViewController = _textFieldView?.viewController() {
            
            if enableToolbar == false {
                
                //If found any toolbar enabled classes then return.
                for enabledClass in enabledToolbarClasses {
                    
                    if textFieldViewController.isKind(of: enabledClass) {
                        enableToolbar = true
                        break
                    }
                }
            }
            
            if enableToolbar == true {
                
                //If found any toolbar disabled classes then return.
                for disabledClass in disabledToolbarClasses {
                    
                    if textFieldViewController.isKind(of: disabledClass) {
                        enableToolbar = false
                        break
                    }
                }
                
                //Special Controllers
                if enableToolbar == true {
                    
                    let classNameString = NSStringFromClass(type(of:textFieldViewController.self))
                    
                    //_UIAlertControllerTextFieldViewController
                    if (classNameString.contains("UIAlertController") && classNameString.hasSuffix("TextFieldViewController")) {
                        enableToolbar = false
                    }
                }
            }
        }

        return enableToolbar
    }

    /**
     /**
     IQAutoToolbarBySubviews:   Creates Toolbar according to subview's hirarchy of Textfield's in view.
     IQAutoToolbarByTag:        Creates Toolbar according to tag property of TextField's.
     IQAutoToolbarByPosition:   Creates Toolbar according to the y,x position of textField in it's superview coordinate.
     
     Default is IQAutoToolbarBySubviews.
     */
    AutoToolbar managing behaviour. Default is IQAutoToolbarBySubviews.
    */
    open var toolbarManageBehaviour = IQAutoToolbarManageBehaviour.bySubviews

    /**
    If YES, then uses textField's tintColor property for IQToolbar, otherwise tint color is black. Default is NO.
    */
    open var shouldToolbarUsesTextFieldTintColor = false
    
    /**
    This is used for toolbar.tintColor when textfield.keyboardAppearance is UIKeyboardAppearanceDefault. If shouldToolbarUsesTextFieldTintColor is YES then this property is ignored. Default is nil and uses black color.
    */
    open var toolbarTintColor : UIColor?

    /**
     This is used for toolbar.barTintColor. Default is nil and uses white color.
     */
    open var toolbarBarTintColor : UIColor?

    /**
     IQPreviousNextDisplayModeDefault:      Show NextPrevious when there are more than 1 textField otherwise hide.
     IQPreviousNextDisplayModeAlwaysHide:   Do not show NextPrevious buttons in any case.
     IQPreviousNextDisplayModeAlwaysShow:   Always show nextPrevious buttons, if there are more than 1 textField then both buttons will be visible but will be shown as disabled.
     */
    open var previousNextDisplayMode = IQPreviousNextDisplayMode.Default

    /**
     Toolbar done button icon, If nothing is provided then check toolbarDoneBarButtonItemText to draw done button.
     */
    open var toolbarDoneBarButtonItemImage : UIImage?
    
    /**
     Toolbar done button text, If nothing is provided then system default 'UIBarButtonSystemItemDone' will be used.
     */
    open var toolbarDoneBarButtonItemText : String?

    /**
    If YES, then it add the textField's placeholder text on IQToolbar. Default is YES.
    */
    @available(*,deprecated, message: "This is renamed to `shouldShowToolbarPlaceholder` for more clear naming.")
    open var shouldShowTextFieldPlaceholder: Bool {
        
        set {
            shouldShowToolbarPlaceholder =  newValue
        }
        get {
            return shouldShowToolbarPlaceholder
        }
    }
    open var shouldShowToolbarPlaceholder = true

    /**
    Placeholder Font. Default is nil.
    */
    open var placeholderFont: UIFont?
    
    
    ///--------------------------
    /// MARK: UITextView handling
    ///--------------------------
    
    /** used to adjust contentInset of UITextView. */
    fileprivate var         startingTextViewContentInsets = UIEdgeInsets.zero
    
    /** used to adjust scrollIndicatorInsets of UITextView. */
    fileprivate var         startingTextViewScrollIndicatorInsets = UIEdgeInsets.zero
    
    /** used with textView to detect a textFieldView contentInset is changed or not. (Bug ID: #92)*/
    fileprivate var         isTextViewContentInsetChanged = false
        

    ///---------------------------------------
    /// MARK: UIKeyboard appearance overriding
    ///---------------------------------------

    /**
    Override the keyboardAppearance for all textField/textView. Default is NO.
    */
    open var overrideKeyboardAppearance = false
    
    /**
    If overrideKeyboardAppearance is YES, then all the textField keyboardAppearance is set using this property.
    */
    open var keyboardAppearance = UIKeyboardAppearance.default

    
    ///-----------------------------------------------------------
    /// MARK: UITextField/UITextView Next/Previous/Resign handling
    ///-----------------------------------------------------------
    
    
    /**
    Resigns Keyboard on touching outside of UITextField/View. Default is NO.
    */
    open var shouldResignOnTouchOutside = false {
        
        didSet {
            _tapGesture.isEnabled = privateShouldResignOnTouchOutside()
            
            let shouldResign = shouldResignOnTouchOutside ? "Yes" : "NO"
            
            showLog("shouldResignOnTouchOutside: \(shouldResign)")
        }
    }
    
    /** TapGesture to resign keyboard on view's touch. It's a readonly property and exposed only for adding/removing dependencies if your added gesture does have collision with this one */
    fileprivate var _tapGesture: UITapGestureRecognizer!
    open var resignFirstResponderGesture: UITapGestureRecognizer {
        get {
            return _tapGesture
        }
    }
    
    /*******************************************/
    
    fileprivate func privateShouldResignOnTouchOutside() -> Bool {
        
        var shouldResign = shouldResignOnTouchOutside
        
        if let textFieldViewController = _textFieldView?.viewController() {
            
            if shouldResign == false {
                
                //If viewController is kind of enable viewController class, then assuming shouldResignOnTouchOutside is enabled.
                for enabledClass in enabledTouchResignedClasses {
                    
                    if textFieldViewController.isKind(of: enabledClass) {
                        shouldResign = true
                        break
                    }
                }
            }
            
            if shouldResign == true {
                
                //If viewController is kind of disable viewController class, then assuming shouldResignOnTouchOutside is disable.
                for disabledClass in disabledTouchResignedClasses {
                    
                    if textFieldViewController.isKind(of: disabledClass) {
                        shouldResign = false
                        break
                    }
                }
                
                //Special Controllers
                if shouldResign == true {
                    
                    let classNameString = NSStringFromClass(type(of:textFieldViewController.self))
                    
                    //_UIAlertControllerTextFieldViewController
                    if (classNameString.contains("UIAlertController") && classNameString.hasSuffix("TextFieldViewController")) {
                        shouldResign = false
                    }
                }
            }
        }
        
        return shouldResign
    }
    
    /**
    Resigns currently first responder field.
    */
    @discardableResult open func resignFirstResponder()-> Bool {
        
        if let textFieldRetain = _textFieldView {
            
            //Resigning first responder
            let isResignFirstResponder = textFieldRetain.resignFirstResponder()
            
            //  If it refuses then becoming it as first responder again.    (Bug ID: #96)
            if isResignFirstResponder == false {
                //If it refuses to resign then becoming it first responder again for getting notifications callback.
                textFieldRetain.becomeFirstResponder()
                
                showLog("Refuses to resign first responder: \(String(describing: _textFieldView?._IQDescription()))")
            }
            
            return isResignFirstResponder
        }
        
        return false
    }
    
    /**
    Returns YES if can navigate to previous responder textField/textView, otherwise NO.
    */
    @objc open var canGoPrevious: Bool {
        //Getting all responder view's.
        if let textFields = responderViews() {
            if let  textFieldRetain = _textFieldView {
                
                //Getting index of current textField.
                if let index = textFields.index(of: textFieldRetain) {
                    
                    //If it is not first textField. then it's previous object canBecomeFirstResponder.
                    if index > 0 {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    /**
    Returns YES if can navigate to next responder textField/textView, otherwise NO.
    */
    @objc open var canGoNext: Bool {
        //Getting all responder view's.
        if let textFields = responderViews() {
            if let  textFieldRetain = _textFieldView {
                //Getting index of current textField.
                if let index = textFields.index(of: textFieldRetain) {
                    
                    //If it is not first textField. then it's previous object canBecomeFirstResponder.
                    if index < textFields.count-1 {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    /**
    Navigate to previous responder textField/textView.
    */
    @objc @discardableResult open func goPrevious()-> Bool {
        
        //Getting all responder view's.
        if let  textFieldRetain = _textFieldView {
            if let textFields = responderViews() {
                //Getting index of current textField.
                if let index = textFields.index(of: textFieldRetain) {
                    
                    //If it is not first textField. then it's previous object becomeFirstResponder.
                    if index > 0 {
                        
                        let nextTextField = textFields[index-1]
                        
                        let isAcceptAsFirstResponder = nextTextField.becomeFirstResponder()
                        
                        //  If it refuses then becoming previous textFieldView as first responder again.    (Bug ID: #96)
                        if isAcceptAsFirstResponder == false {
                            //If next field refuses to become first responder then restoring old textField as first responder.
                            textFieldRetain.becomeFirstResponder()
                            
                            showLog("Refuses to become first responder: \(nextTextField._IQDescription())")
                        }
                        
                        return isAcceptAsFirstResponder
                    }
                }
            }
        }
        
        return false
    }
    
    /**
    Navigate to next responder textField/textView.
    */
    @objc @discardableResult open func goNext()-> Bool {

        //Getting all responder view's.
        if let  textFieldRetain = _textFieldView {
            if let textFields = responderViews() {
                //Getting index of current textField.
                if let index = textFields.index(of: textFieldRetain) {
                    //If it is not last textField. then it's next object becomeFirstResponder.
                    if index < textFields.count-1 {
                        
                        let nextTextField = textFields[index+1]
                        
                        let isAcceptAsFirstResponder = nextTextField.becomeFirstResponder()
                        
                        //  If it refuses then becoming previous textFieldView as first responder again.    (Bug ID: #96)
                        if isAcceptAsFirstResponder == false {
                            //If next field refuses to become first responder then restoring old textField as first responder.
                            textFieldRetain.becomeFirstResponder()
                            
                            showLog("Refuses to become first responder: \(nextTextField._IQDescription())")
                        }
                        
                        return isAcceptAsFirstResponder
                    }
                }
            }
        }

        return false
    }
    
    /**	previousAction. */
    @objc internal func previousAction (_ barButton : IQBarButtonItem) {
        
        //If user wants to play input Click sound.
        if shouldPlayInputClicks == true {
            //Play Input Click Sound.
            UIDevice.current.playInputClick()
        }
        
        if canGoPrevious == true {
            
            if let textFieldRetain = _textFieldView {
                let isAcceptAsFirstResponder = goPrevious()
                
                if isAcceptAsFirstResponder &&
                    barButton.invocation.target != nil &&
                    barButton.invocation.action != nil {
                    
                    UIApplication.shared.sendAction(barButton.invocation.action!, to: barButton.invocation.target, from: textFieldRetain, for: UIEvent())
                }
            }
        }
    }
    
    /**	nextAction. */
    @objc internal func nextAction (_ barButton : IQBarButtonItem) {
        
        //If user wants to play input Click sound.
        if shouldPlayInputClicks == true {
            //Play Input Click Sound.
            UIDevice.current.playInputClick()
        }
        
        if canGoNext == true {
            
            if let textFieldRetain = _textFieldView {
                let isAcceptAsFirstResponder = goNext()
                
                if isAcceptAsFirstResponder &&
                    barButton.invocation.target != nil &&
                    barButton.invocation.action != nil {
                    
                    UIApplication.shared.sendAction(barButton.invocation.action!, to: barButton.invocation.target, from: textFieldRetain, for: UIEvent())
                }
            }
        }
    }
    
    /**	doneAction. Resigning current textField. */
    @objc internal func doneAction (_ barButton : IQBarButtonItem) {
        
        //If user wants to play input Click sound.
        if shouldPlayInputClicks == true {
            //Play Input Click Sound.
            UIDevice.cur