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

    /** Boolean to maintain keyboard is showing or it is hide. To solve rootViewController.view.frame calculations. */
    fileprivate var         _privateIsKeyboardShowing = false

    fileprivate var         _privateMovedDistance : CGFloat = 0.0
    
    /** To use with keyboardDistanceFromTextField. */
    fileprivate var         _privateKeyboardDistanceFromTextField: CGFloat = 10.0
    
    /**************************************************************************************/
    
    ///--------------------------------------
    /// MARK: Initialization/Deinitialization
    ///--------------------------------------
    
    /*  Singleton Object Initialization. */
    override init() {
        
        super.init()

        self.registerAllNotifications()

        //Creating gesture for @shouldResignOnTouchOutside. (Enhancement ID: #14)
        _tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapRecognized(_:)))
        _tapGesture.cancelsTouchesInView = false
        _tapGesture.delegate = self
        _tapGesture.isEnabled = shouldResignOnTouchOutside
        
        //Loading IQToolbar, IQTitleBarButtonItem, IQBarButtonItem to fix first time keyboard appearance delay (Bug ID: #550)
        let textField = UITextField()
        textField.addDoneOnKeyboardWithTarget(nil, action: #selector(self.doneAction(_:)))
        textField.addPreviousNextDoneOnKeyboardWithTarget(nil, previousAction: #selector(self.previousAction(_:)), nextAction: #selector(self.nextAction(_:)), doneAction: #selector(self.doneAction(_:)))
        
        disabledDistanceHandlingClasses.append(UITableViewController.self)
        disabledDistanceHandlingClasses.append(UIAlertController.self)
        disabledToolbarClasses.append(UIAlertController.self)
        disabledTouchResignedClasses.append(UIAlertController.self)
        toolbarPreviousNextAllowedClasses.append(UITableView.self)
        toolbarPreviousNextAllowedClasses.append(UICollectionView.self)
        toolbarPreviousNextAllowedClasses.append(IQPreviousNextView.self)
        touchResignedGestureIgnoreClasses.append(UIControl.self)
        touchResignedGestureIgnoreClasses.append(UINavigationBar.self)
    }
    
    /** Override +load method to enable KeyboardManager when class loader load IQKeyboardManager. Enabling when app starts (No need to write any code) */
    /** It doesn't work from Swift 1.2 */
//    override public class func load() {
//        super.load()
//        
//        //Enabling IQKeyboardManager.
//        IQKeyboardManager.sharedManager().enable = true
//    }
    
    deinit {
        //  Disable the keyboard manager.
        enable = false

        //Removing notification observers on dealloc.
        NotificationCenter.default.removeObserver(self)
    }
    
    /** Getting keyWindow. */
    fileprivate func keyWindow() -> UIWindow? {
        
        if let keyWindow = _textFieldView?.window {
            return keyWindow
        } else {
            
            struct Static {
                /** @abstract   Save keyWindow object for reuse.
                @discussion Sometimes [[UIApplication sharedApplication] keyWindow] is returning nil between the app.   */
                static weak var keyWindow : UIWindow?
            }

            /*  (Bug ID: #23, #25, #73)   */
            let originalKeyWindow = UIApplication.shared.keyWindow
            
            //If original key window is not nil and the cached keywindow is also not original keywindow then changing keywindow.
            if originalKeyWindow != nil &&
                (Static.keyWindow == nil || Static.keyWindow != originalKeyWindow) {
                Static.keyWindow = originalKeyWindow
            }

            //Return KeyWindow
            return Static.keyWindow
        }
    }

    ///-----------------------
    /// MARK: Helper Functions
    ///-----------------------
    
    /*  Helper function to manipulate RootViewController's frame with animation. */
    fileprivate func setRootViewFrame(_ frame: CGRect) {
        
        //  Getting topMost ViewController.
        var controller = _textFieldView?.topMostController()
        
        if controller == nil {
            controller = keyWindow()?.topMostWindowController()
        }
        
        if let unwrappedController = controller {
            
            var newFrame = frame
            //frame size needs to be adjusted on iOS8 due to orientation structure changes.
            newFrame.size = unwrappedController.view.frame.size
            
#if swift(>=3.2)
    
            var safeAreaNewInset = UIEdgeInsets.zero;

            if canAdjustAdditionalSafeAreaInsets {
        
                if #available(iOS 11, *) {
                    
                    if let textFieldView = _textFieldView {
                        safeAreaNewInset = _initialAdditionalSafeAreaInsets;
                        let viewMovement : CGFloat = _topViewBeginRect.maxY - newFrame.maxY;
                        
                        //Maintain keyboardDistanceFromTextField
                        var specialKeyboardDistanceFromTextField = textFieldView.keyboardDistanceFromTextField
                        
                        if textFieldView.isSearchBarTextField() {
                            
                            if  let searchBar = textFieldView.superviewOfClassType(UISearchBar.self) {
                                specialKeyboardDistanceFromTextField = searchBar.keyboardDistanceFromTextField
                            }
                        }
                        
                        let newKeyboardDistanceFromTextField = (specialKeyboardDistanceFromTextField == kIQUseDefaultKeyboardDistance) ? keyboardDistanceFromTextField : specialKeyboardDistanceFromTextField
                        
                        let textFieldDistance = textFieldView.frame.size.height + newKeyboardDistanceFromTextField;
                        safeAreaNewInset.bottom += min(viewMovement, textFieldDistance);
                    }
                }
            }
#endif

            //Used UIViewAnimationOptionBeginFromCurrentState to minimize strange animations.
            UIView.animate(withDuration: _animationDuration, delay: 0, options: UIViewAnimationOptions.beginFromCurrentState.union(_animationCurve), animations: { () -> Void in
                
#if swift(>=3.2)
                if self.canAdjustAdditionalSafeAreaInsets {
                    if #available(iOS 11, *) {
                        unwrappedController.additionalSafeAreaInsets = safeAreaNewInset;
                    }
                }
#endif

                //  Setting it's new frame
                unwrappedController.view.frame = newFrame
                self.showLog("Set \(String(describing: controller?._IQDescription())) frame to : \(newFrame)")
                
                //Animating content if needed (Bug ID: #204)
                if self.layoutIfNeededOnUpdate == true {
                    //Animating content (Bug ID: #160)
                    unwrappedController.view.setNeedsLayout()
                    unwrappedController.view.layoutIfNeeded()
                }
 
                
                }) { (animated:Bool) -> Void in}
        } else {  //  If can't get rootViewController then printing warning to user.
            showLog("You must set UIWindow.rootViewController in your AppDelegate to work with IQKeyboardManager")
        }
    }

    /* Adjusting RootViewController's frame according to interface orientation. */
    fileprivate func adjustFrame() {
        
        //  We are unable to get textField object while keyboard showing on UIWebView's textField.  (Bug ID: #11)
        if _textFieldView == nil {
            return
        }
        
        let textFieldView = _textFieldView!

        let startTime = CACurrentMediaTime()
        showLog("****** \(#function) started ******")

        //  Getting KeyWindow object.
        let optionalWindow = keyWindow()
        
        //  Getting RootViewController.  (Bug ID: #1, #4)
        var optionalRootController = _textFieldView?.topMostController()
        if optionalRootController == nil {
            optionalRootController = keyWindow()?.topMostWindowController()
        }
        
        //  Converting Rectangle according to window bounds.
        let optionalTextFieldViewRect = textFieldView.superview?.convert(textFieldView.frame, to: optionalWindow)

        if optionalRootController == nil ||
            optionalWindow == nil ||
            optionalTextFieldViewRect == nil {
            return
        }
        
        let rootController = optionalRootController!
        let window = optionalWindow!
        let textFieldViewRect = optionalTextFieldViewRect!
        
        //  Getting RootViewRect.
        var rootViewRect = rootController.view.frame
        //Getting statusBarFrame

        //Maintain keyboardDistanceFromTextField
        var specialKeyboardDistanceFromTextField = textFieldView.keyboardDistanceFromTextField
        
        if textFieldView.isSearchBarTextField() {
            
            if  let searchBar = textFieldView.superviewOfClassType(UISearchBar.self) {
                specialKeyboardDistanceFromTextField = searchBar.keyboardDistanceFromTextField
            }
        }
        
        let newKeyboardDistanceFromTextField = (specialKeyboardDistanceFromTextField == kIQUseDefaultKeyboardDistance) ? keyboardDistanceFromTextField : specialKeyboardDistanceFromTextField
        var kbSize = _kbSize
        kbSize.height += newKeyboardDistanceFromTextField

        let statusBarFrame = UIApplication.shared.statusBarFrame
        
        //  (Bug ID: #250)
        var layoutGuidePosition = IQLayoutGuidePosition.none
        
        if let viewController = textFieldView.viewController() {
            
            if let constraint = _layoutGuideConstraint {
                
                var layoutGuide : UILayoutSupport?
                if let itemLayoutGuide = constraint.firstItem as? UILayoutSupport {
                    layoutGuide = itemLayoutGuide
                } else if let itemLayoutGuide = constraint.secondItem as? UILayoutSupport {
                    layoutGuide = itemLayoutGuide
                }
                
                if let itemLayoutGuide : UILayoutSupport = layoutGuide {
                    
                    if (itemLayoutGuide === viewController.topLayoutGuide)    //If topLayoutGuide constraint
                    {
                        layoutGuidePosition = .top
                    }
                    else if (itemLayoutGuide === viewController.bottomLayoutGuide)    //If bottomLayoutGuice constraint
                    {
                        layoutGuidePosition = .bottom
                    }
                }
            }
        }
        
        let topLayoutGuide : CGFloat = statusBarFrame.height

        var move : CGFloat = 0.0
        //  Move positive = textField is hidden.
        //  Move negative = textField is showing.
        
        //  Checking if there is bottomLayoutGuide attached (Bug ID: #250)
        if layoutGuidePosition == .bottom {
            //  Calculating move position.
            move = textFieldViewRect.maxY-(window.frame.height-kbSize.height)
        } else {
            //  Calculating move position. Common for both normal and special cases.
            move = min(textFieldViewRect.minY-(topLayoutGuide+5), textFieldViewRect.maxY-(window.frame.height-kbSize.height))
        }
        
        showLog("Need to move: \(move)")

        var superScrollView : UIScrollView? = nil
        var superView = textFieldView.superviewOfClassType(UIScrollView.self) as? UIScrollView
        
        //Getting UIScrollView whose scrolling is enabled.    //  (Bug ID: #285)
        while let view = superView {
            
            if (view.isScrollEnabled && view.shouldIgnoreScrollingAdjustment == false) {
                superScrollView = view
                break
            }
            else {
                //  Getting it's superScrollView.   //  (Enhancement ID: #21, #24)
                superView = view.superviewOfClassType(UIScrollView.self) as? UIScrollView
            }
        }
        
        //If there was a lastScrollView.    //  (Bug ID: #34)
        if let lastScrollView = _lastScrollView {
            //If we can't find current superScrollView, then setting lastScrollView to it's original form.
            if superScrollView == nil {
                
                showLog("Restoring \(lastScrollView._IQDescription()) contentInset to : \(_startingContentInsets) and contentOffset to : \(_startingContentOffset)")

                UIView.animate(withDuration: _animationDuration, delay: 0, options: UIViewAnimationOptions.beginFromCurrentState.union(_animationCurve), animations: { () -> Void in
                    
                    lastScrollView.contentInset = self._startingContentInsets
                    lastScrollView.scrollIndicatorInsets = self._startingScrollIndicatorInsets
                    }) { (animated:Bool) -> Void in }
                
                if lastScrollView.shouldRestoreScrollViewContentOffset == true {
                    lastScrollView.setContentOffset(_startingContentOffset, animated: true)
                }
                
                _startingContentInsets = UIEdgeInsets.zero
                _startingScrollIndicatorInsets = UIEdgeInsets.zero
                _startingContentOffset = CGPoint.zero
                _lastScrollView = nil
            } else if superScrollView != lastScrollView {     //If both scrollView's are different, then reset lastScrollView to it's original frame and setting current scrollView as last scrollView.
                
                showLog("Restoring \(lastScrollView._IQDescription()) contentInset to : \(_startingContentInsets) and contentOffset to : \(_startingContentOffset)")
                
                UIView.animate(withDuration: _animationDuration, delay: 0, options: UIViewAnimationOptions.beginFromCurrentState.union(_animationCurve), animations: { () -> Void in
                    
                    lastScrollView.contentInset = self._startingContentInsets
                    lastScrollView.scrollIndicatorInsets = self._startingScrollIndicatorInsets
                    }) { (animated:Bool) -> Void in }
                
                if lastScrollView.shouldRestoreScrollViewContentOffset == true {
                    lastScrollView.setContentOffset(_startingContentOffset, animated: true)
                }

                _lastScrollView = superScrollView
                _startingContentInsets = superScrollView!.contentInset
                _startingScrollIndicatorInsets = superScrollView!.scrollIndicatorInsets
                _startingContentOffset = superScrollView!.contentOffset
                
                showLog("Saving New \(lastScrollView._IQDescription()) contentInset : \(_startingContentInsets) and contentOffset : \(_startingContentOffset)")
            }
            //Else the case where superScrollView == lastScrollView means we are on same scrollView after switching to different textField. So doing nothing, going ahead
        } else if let unwrappedSuperScrollView = superScrollView {    //If there was no lastScrollView and we found a current scrollView. then setting it as lastScrollView.
            _lastScrollView = unwrappedSuperScrollView
            _startingContentInsets = unwrappedSuperScrollView.contentInset
            _startingScrollIndicatorInsets = unwrappedSuperScrollView.scrollIndicatorInsets
            _startingContentOffset = unwrappedSuperScrollView.contentOffset

            showLog("Saving \(unwrappedSuperScrollView._IQDescription()) contentInset : \(_startingContentInsets) and contentOffset : \(_startingContentOffset)")
        }
        
        //  Special case for ScrollView.
        //  If we found lastScrollView then setting it's contentOffset to show textField.
        if let lastScrollView = _lastScrollView {
            //Saving
            var lastView = textFieldView
            var superScrollView = _lastScrollView
            
            while let scrollView = superScrollView {
                
                //Looping in upper hierarchy until we don't found any scrollView in it's upper hirarchy till UIWindow object.
                if move > 0 ? (move > (-scrollView.contentOffset.y - scrollView.contentInset.top)) : scrollView.contentOffset.y>0 {
                    
                    var tempScrollView = scrollView.superviewOfClassType(UIScrollView.self) as? UIScrollView
                    var nextScrollView : UIScrollView? = nil
                    while let view = tempScrollView {
                        
                        if (view.isScrollEnabled  && view.shouldIgnoreScrollingAdjustment == false) {
                            nextScrollView = view
                            break
                        } else {
                            tempScrollView = view.superviewOfClassType(UIScrollView.self) as? UIScrollView
                        }
                    }
                    
                    //Getting lastViewRect.
                    if let lastViewRect = lastView.superview?.convert(lastView.frame, to: scrollView) {
                        
                        //Calculating the expected Y offset from move and scrollView's contentOffset.
                        var shouldOffsetY = scrollView.contentOffset.y - min(scrollView.contentOffset.y,-move)
                        
                        //Rearranging the expected Y offset according to the view.
                        shouldOffsetY = min(shouldOffsetY, lastViewRect.origin.y /*-5*/)   //-5 is for good UI.//Commenting -5 (Bug ID: #69)

                        //[_textFieldView isKindOfClass:[UITextView class]] If is a UITextView type
                        //nextScrollView == nil    If processing scrollView is last scrollView in upper hierarchy (there is no other scrollView upper hierrchy.)
                        //[_textFieldView isKindOfClass:[UITextView class]] If is a UITextView type
                        //shouldOffsetY >= 0     shouldOffsetY must be greater than in order to keep distance from navigationBar (Bug ID: #92)
                        if textFieldView is UITextView == true &&
                            nextScrollView == nil &&
                            shouldOffsetY >= 0 {
                            var maintainTopLayout : CGFloat = 0
                            
                            if let navigationBarFrame = textFieldView.viewController()?.navigationController?.navigationBar.frame {
                                maintainTopLayout = navigationBarFrame.maxY
                            }
                            
                            maintainTopLayout += 10.0 //For good UI
                            
                            //  Converting Rectangle according to window bounds.
                            if let currentTextFieldViewRect = textFieldView.superview?.convert(textFieldView.frame, to: window) {

                                //Calculating expected fix distance which needs to be managed from navigation bar
                                let expectedFixDistance = currentTextFieldViewRect.minY - maintainTopLayout
                                
                                //Now if expectedOffsetY (superScrollView.contentOffset.y + expectedFixDistance) is lower than current shouldOffsetY, which means we're in a position where navigationBar up and hide, then reducing shouldOffsetY with expectedOffsetY (superScrollView.contentOffset.y + expectedFixDistance)
                                shouldOffsetY = min(shouldOffsetY, scrollView.contentOffset.y + expectedFixDistance)

                                //Setting move to 0 because now we don't want to move any view anymore (All will be managed by our contentInset logic.
                                move = 0
                            }
                            else {
                                //Subtracting the Y offset from the move variable, because we are going to change scrollView's contentOffset.y to shouldOffsetY.
                                move -= (shouldOffsetY-scrollView.contentOffset.y)
                            }
                        }
                        else
                        {
                            //Subtracting the Y offset from the move variable, because we are going to change scrollView's contentOffset.y to shouldOffsetY.
                            move -= (shouldOffsetY-scrollView.contentOffset.y)
                        }
                        
                        //Getting problem while using `setContentOffset:animated:`, So I used animation API.
                        UIView.animate(withDuration: _animationDuration, delay: 0, options: UIViewAnimationOptions.beginFromCurrentState.union(_animationCurve), animations: { () -> Void in
                        
                            self.showLog("Adjusting \(scrollView.contentOffset.y-shouldOffsetY) to \(scrollView._IQDescription()) ContentOffset")
                            
                            self.showLog("Remaining Move: \(move)")
                            
                            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: shouldOffsetY)
                            }) { (animated:Bool) -> Void in }
                    }
                    
                    //  Getting next lastView & superScrollView.
                    lastView = scrollView
                    superScrollView = nextScrollView
                } else {
                    break
                }
            }
            
            //Updating contentInset
            if let lastScrollViewRect = lastScrollView.superview?.convert(lastScrollView.frame, to: window) {
                
                let bottom : CGFloat = kbSize.height-newKeyboardDistanceFromTextField-(window.frame.height-lastScrollViewRect.maxY)
                
                // Update the insets so that the scroll vew doesn't shift incorrectly when the offset is near the bottom of the scroll view.
                var movedInsets = lastScrollView.contentInset
                
                movedInsets.bottom = max(_startingContentInsets.bottom, bottom)
                
                showLog("\(lastScrollView._IQDescription()) old ContentInset : \(lastScrollView.contentInset)")
                
                //Getting problem while using `setContentOffset:animated:`, So I used animation API.
                UIView.animate(withDuration: _animationDuration, delay: 0, options: UIViewAnimationOptions.beginFromCurrentState.union(_animationCurve), animations: { () -> Void in
                    lastScrollView.contentInset = movedInsets

                    var newInset = lastScrollView.scrollIndicatorInsets
                    newInset.bottom = movedInsets.bottom
                    lastScrollView.scrollIndicatorInsets = newInset

                    }) { (animated:Bool) -> Void in }

                showLog("\(lastScrollView._IQDescription()) new ContentInset : \(lastScrollView.contentInset)")
            }
        }
        //Going ahead. No else if.
        
        if layoutGuidePosition == .top {
            
            if let constraint = _layoutGuideConstraint {
                
                let constant = min(_layoutGuideConstraintInitialConstant, constraint.constant-move)
                
                UIView.animate(withDuration: _animationDuration, delay: 0, options: (_animationCurve.union(UIViewAnimationOptions.beginFromCurrentState)), animations: { () -> Void in
                    
                    constraint.constant = constant
                    self._rootViewController?.view.setNeedsLayout()
                    self._rootViewController?.view.layoutIfNeeded()
                    
                    }, completion: { (finished) -> Void in })
            }
            
        } else if layoutGuidePosition == .bottom {
            
            if let constraint = _layoutGuideConstraint {
                
                let constant = max(_layoutGuideConstraintInitialConstant, constraint.constant+move)
                
                UIView.animate(withDuration: _animationDuration, delay: 0, options: (_animationCurve.union(UIViewAnimationOptions.beginFromCurrentState)), animations: { () -> Void in
                    
                    constraint.constant = constant
                    self._rootViewController?.view.setNeedsLayout()
                    self._rootViewController?.view.layoutIfNeeded()
                    
                    }, completion: { (finished) -> Void in })
            }
            
        } else {
            
            //Special case for UITextView(Readjusting textView.contentInset when textView hight is too big to fit on screen)
            //_lastScrollView       If not having inside any scrollView, (now contentInset manages the full screen textView.
            //[_textFieldView isKindOfClass:[UITextView class]] If is a UITextView type
            if let textView = textFieldView as? UITextView {
                let textViewHeight = min(textView.frame.height, (window.frame.height-kbSize.height-(topLayoutGuide)))
                
                if (textView.frame.size.height-textView.contentInset.bottom>textViewHeight)
                {
                    UIView.animate(withDuration: _animationDuration, delay: 0, options: (_animationCurve.union(UIViewAnimationOptions.beginFromCurrentState)), animations: { () -> Void in
                        
                        self.showLog("\(textFieldView._IQDescription()) Old UITextView.contentInset : \(textView.contentInset)")
                        
                        //_isTextViewContentInsetChanged,  If frame is not change by library in past, then saving user textView properties  (Bug ID: #92)
                        if (self.isTextViewContentInsetChanged == false)
                        {
                            self.startingTextViewContentInsets = textView.contentInset
                            self.startingTextViewScrollIndicatorInsets = textView.scrollIndicatorInsets
                        }
                        
                        var newContentInset = textView.contentInset
                        newContentInset.bottom = textView.frame.size.height-textViewHeight
                        textView.contentInset = newContentInset
                        textView.scrollIndicatorInsets = newContentInset
                        self.isTextViewContentInsetChanged = true
                        
                        self.s