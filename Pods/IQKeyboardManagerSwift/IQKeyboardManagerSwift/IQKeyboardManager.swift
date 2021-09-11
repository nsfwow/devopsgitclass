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
            UIDevice.current.playInputClick()
        }
        
        if let textFieldRetain = _textFieldView {
            //Resign textFieldView.
            let isResignedFirstResponder = resignFirstResponder()
            
            if isResignedFirstResponder &&
                barButton.invocation.target != nil &&
                barButton.invocation.action != nil{
                
                UIApplication.shared.sendAction(barButton.invocation.action!, to: barButton.invocation.target, from: textFieldRetain, for: UIEvent())
            }
        }
    }
    
    /** Resigning on tap gesture.   (Enhancement ID: #14)*/
    @objc internal func tapRecognized(_ gesture: UITapGestureRecognizer) {
        
        if gesture.state == UIGestureRecognizerState.ended {

            //Resigning currently responder textField.
            _ = resignFirstResponder()
        }
    }
    
    /** Note: returning YES is guaranteed to allow simultaneous recognition. returning NO is not guaranteed to prevent simultaneous recognition, as the other gesture's delegate may return YES. */
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    /** To not detect touch events in a subclass of UIControl, these may have added their own selector for specific work */
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //  Should not recognize gesture if the clicked view is either UIControl or UINavigationBar(<Back button etc...)    (Bug ID: #145)
        
        for ignoreClass in touchResignedGestureIgnoreClasses {
            
            if touch.view?.isKind(of: ignoreClass) == true {
                return false
            }
        }

        return true
    }
    
    ///-----------------------
    /// MARK: UISound handling
    ///-----------------------

    /**
    If YES, then it plays inputClick sound on next/previous/done click.
    */
    open var shouldPlayInputClicks = true
    
    
    ///---------------------------
    /// MARK: UIAnimation handling
    ///---------------------------

    /**
    If YES, then calls 'setNeedsLayout' and 'layoutIfNeeded' on any frame update of to viewController's view.
    */
    open var layoutIfNeededOnUpdate = false

    ///-----------------------------------------------
    /// @name InteractivePopGestureRecognizer handling
    ///-----------------------------------------------
    
    /**
     If YES, then always consider UINavigationController.view begin point as {0,0}, this is a workaround to fix a bug #464 because there are no notification mechanism exist when UINavigationController.view.frame gets changed internally.
     */
    open var shouldFixInteractivePopGestureRecognizer = true
    
#if swift(>=3.2)
    ///------------------------------------
    /// MARK: Safe Area
    ///------------------------------------

    /**
     If YES, then library will try to adjust viewController.additionalSafeAreaInsets to automatically handle layout guide. Default is NO.
     */
    open var canAdjustAdditionalSafeAreaInsets = false
#endif

    ///------------------------------------
    /// MARK: Class Level disabling methods
    ///------------------------------------
    
    /**
     Disable distance handling within the scope of disabled distance handling viewControllers classes. Within this scope, 'enabled' property is ignored. Class should be kind of UIViewController.
     */
    open var disabledDistanceHandlingClasses  = [UIViewController.Type]()
    
    /**
     Enable distance handling within the scope of enabled distance handling viewControllers classes. Within this scope, 'enabled' property is ignored. Class should be kind of UIViewController. If same Class is added in disabledDistanceHandlingClasses list, then enabledDistanceHandlingClasses will be ignored.
     */
    open var enabledDistanceHandlingClasses  = [UIViewController.Type]()
    
    /**
     Disable automatic toolbar creation within the scope of disabled toolbar viewControllers classes. Within this scope, 'enableAutoToolbar' property is ignored. Class should be kind of UIViewController.
     */
    open var disabledToolbarClasses  = [UIViewController.Type]()
    
    /**
     Enable automatic toolbar creation within the scope of enabled toolbar viewControllers classes. Within this scope, 'enableAutoToolbar' property is ignored. Class should be kind of UIViewController. If same Class is added in disabledToolbarClasses list, then enabledToolbarClasses will be ignore.
     */
    open var enabledToolbarClasses  = [UIViewController.Type]()

    /**
     Allowed subclasses of UIView to add all inner textField, this will allow to navigate between textField contains in different superview. Class should be kind of UIView.
     */
    open var toolbarPreviousNextAllowedClasses  = [UIView.Type]()
    
    /**
     Disabled classes to ignore 'shouldResignOnTouchOutside' property, Class should be kind of UIViewController.
     */
    open var disabledTouchResignedClasses  = [UIViewController.Type]()
    
    /**
     Enabled classes to forcefully enable 'shouldResignOnTouchOutsite' property. Class should be kind of UIViewController. If same Class is added in disabledTouchResignedClasses list, then enabledTouchResignedClasses will be ignored.
     */
    open var enabledTouchResignedClasses  = [UIViewController.Type]()
    
    /**
     if shouldResignOnTouchOutside is enabled then you can customise the behaviour to not recognise gesture touches on some specific view subclasses. Class should be kind of UIView. Default is [UIControl, UINavigationBar]
     */
    open var touchResignedGestureIgnoreClasses  = [UIView.Type]()    

    ///-------------------------------------------
    /// MARK: Third Party Library support
    /// Add TextField/TextView Notifications customised Notifications. For example while using YYTextView https://github.com/ibireme/YYText
    ///-------------------------------------------
    
    /**
    Add/Remove customised Notification for third party customised TextField/TextView. Please be aware that the Notification object must be idential to UITextField/UITextView Notification objects and customised TextField/TextView support must be idential to UITextField/UITextView.
    @param didBeginEditingNotificationName This should be identical to UITextViewTextDidBeginEditingNotification
    @param didEndEditingNotificationName This should be identical to UITextViewTextDidEndEditingNotification
    */
    
    open func registerTextFieldViewClass(_ aClass: UIView.Type, didBeginEditingNotificationName : String, didEndEditingNotificationName : String) {
        
        registeredClasses.append(aClass)

        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldViewDidBeginEditing(_:)),    name: Notification.Name(rawValue: didBeginEditingNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldViewDidEndEditing(_:)),      name: Notification.Name(rawValue: didEndEditingNotificationName), object: nil)
    }
    
    open func unregisterTextFieldViewClass(_ aClass: UIView.Type, didBeginEditingNotificationName : String, didEndEditingNotificationName : String) {
        
        if let index = registeredClasses.index(where: { element in
            return element == aClass.self
        }) {
            registeredClasses.remove(at: index)
        }

        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: didBeginEditingNotificationName), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: didEndEditingNotificationName), object: nil)
    }
    
    /**************************************************************************************/
    ///------------------------
    /// MARK: Private variables
    ///------------------------

    /*******************************************/

    /** To save UITextField/UITextView object voa textField/textView notifications. */
    fileprivate weak var    _textFieldView: UIView?
    
    /** To save rootViewController.view.frame. */
    fileprivate var         _topViewBeginRect = CGRect.zero
    
    /** To save rootViewController */
    fileprivate weak var    _rootViewController: UIViewController?
    
#if swift(>=3.2)
    /** To save additionalSafeAreaInsets of rootViewController to tweak iOS11 Safe Area */
    fileprivate var         _initialAdditionalSafeAreaInsets = UIEdgeInsets.zero
#endif

    /** To save topBottomLayoutConstraint original constant */
    fileprivate var         _layoutGuideConstraintInitialConstant: CGFloat  = 0

    /** To save topBottomLayoutConstraint original constraint reference */
    fileprivate weak var    _layoutGuideConstraint: NSLayoutConstraint?

    /*******************************************/

    /** Variable to save lastScrollView that was scrolled. */
    fileprivate weak var    _lastScrollView: UIScrollView?
    
    /** LastScrollView's initial contentOffset. */
    fileprivate var         _startingContentOffset = CGPoint.zero
    
    /** LastScrollView's initial scrollIndicatorInsets. */
    fileprivate var         _startingScrollIndicatorInsets = UIEdgeInsets.zero
    
    /** LastScrollView's initial contentInsets. */
    fileprivate var         _startingContentInsets = UIEdgeInsets.zero
    
    /*******************************************/

    /** To save keyboardWillShowNotification. Needed for enable keyboard functionality. */
    fileprivate var         _kbShowNotification: Notification?
    
    /** To save keyboard size. */
    fileprivate var         _kbSize = CGSize.zero
    
    /** To save Status Bar size. */
    fileprivate var         _statusBarFrame = CGRect.zero
    
    /** To save keyboard animation duration. */
    fileprivate var         _animationDuration : TimeInterval = 0.25
    
    /** To mimic the keyboard animation */
    fileprivate var         _animationCurve = UIViewAnimationOptions.curveEaseOut
    
    /*******************************************/

    /** Boolean to maintain keyboard is showing or it is hide. To solve rootViewController.view.