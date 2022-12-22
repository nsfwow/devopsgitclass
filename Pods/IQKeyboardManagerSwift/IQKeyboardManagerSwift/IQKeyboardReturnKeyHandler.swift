
//
//  IQKeyboardReturnKeyHandler.swift
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
import UIKit

/**
Manages the return key to work like next/done in a view hierarchy.
*/
open class IQKeyboardReturnKeyHandler: NSObject , UITextFieldDelegate, UITextViewDelegate {
    
    
    ///---------------
    /// MARK: Settings
    ///---------------
    
    /**
    Delegate of textField/textView.
    */
    open weak var delegate: (UITextFieldDelegate & UITextViewDelegate)?
    
    /**
    Set the last textfield return key type. Default is UIReturnKeyDefault.
    */
    open var lastTextFieldReturnKeyType : UIReturnKeyType = UIReturnKeyType.default {
        
        didSet {
            
            for infoDict in textFieldInfoCache {
                
                if let view = infoDict[kIQTextField] as? UIView {
                    updateReturnKeyTypeOnTextField(view)
                }
            }
        }
    }
    
    ///--------------------------------------
    /// MARK: Initialization/Deinitialization
    ///--------------------------------------

    public override init() {
        super.init()
    }
    
    /**
    Add all the textFields available in UIViewController's view.
    */
    public init(controller : UIViewController) {
        super.init()
        
        addResponderFromView(controller.view)
    }

    deinit {
        
        for infoDict in textFieldInfoCache {
            
            if let textField = infoDict[kIQTextField] as? UITextField {

                if let returnKeyType = infoDict[kIQTextFieldReturnKeyType] as? UIReturnKeyType {
                    textField.returnKeyType = returnKeyType
                }
                
                textField.delegate = infoDict[kIQTextFieldDelegate] as? UITextFieldDelegate

            } else if let textView = infoDict[kIQTextField] as? UITextView {

                if let returnKeyType = infoDict[kIQTextFieldReturnKeyType] as? UIReturnKeyType {
                    textView.returnKeyType = returnKeyType
                }
                
                textView.delegate = infoDict[kIQTextFieldDelegate] as? UITextViewDelegate
            }
        }
        
        textFieldInfoCache.removeAll()
    }
    

    ///------------------------
    /// MARK: Private variables
    ///------------------------
    fileprivate var textFieldInfoCache          =   [[AnyHashable : Any]]()
    fileprivate let kIQTextField                =   "kIQTextField"
    fileprivate let kIQTextFieldDelegate        =   "kIQTextFieldDelegate"
    fileprivate let kIQTextFieldReturnKeyType   =   "kIQTextFieldReturnKeyType"

    
    ///------------------------
    /// MARK: Private Functions
    ///------------------------
    fileprivate func textFieldViewCachedInfo(_ textField : UIView) -> [AnyHashable : Any]? {
        
        for infoDict in textFieldInfoCache {
            
            if let view = infoDict[kIQTextField] as? UIView {

                if view == textField {
                    return infoDict
                }
            }
        }
        
        return nil
    }

    fileprivate func updateReturnKeyTypeOnTextField(_ view : UIView)
    {
        var superConsideredView : UIView?
        
        //If find any consider responderView in it's upper hierarchy then will get deepResponderView. (Bug ID: #347)
        for disabledClass in IQKeyboardManager.sharedManager().toolbarPreviousNextAllowedClasses {
            
            superConsideredView = view.superviewOfClassType(disabledClass)
            
            if superConsideredView != nil {
                break
            }
        }

        var textFields : [UIView]?
        
        //If there is a tableView in view's hierarchy, then fetching all it's subview that responds.
        if let unwrappedTableView = superConsideredView {     //   (Enhancement ID: #22)
            textFields = unwrappedTableView.deepResponderViews()
        } else {  //Otherwise fetching all the siblings
            
            textFields = view.responderSiblings()
            
            //Sorting textFields according to behaviour
            switch IQKeyboardManager.sharedManager().toolbarManageBehaviour {
                //If needs to sort it by tag
            case .byTag:        textFields = textFields?.sortedArrayByTag()
                //If needs to sort it by Position
            case .byPosition:   textFields = textFields?.sortedArrayByPosition()
            default:    break
            }
        }
        
        if let lastView = textFields?.last {
            
            if let textField = view as? UITextField {
                
                //If it's the last textField in responder view, else next
                textField.returnKeyType = (view == lastView)    ?   lastTextFieldReturnKeyType : UIReturnKeyType.next
            } else if let textView = view as? UITextView {
                
                //If it's the last textField in responder view, else next
                textView.returnKeyType = (view == lastView)    ?   lastTextFieldReturnKeyType : UIReturnKeyType.next
            }
        }
    }
    

    ///----------------------------------------------
    /// MARK: Registering/Unregistering textFieldView
    ///----------------------------------------------

    /**
    Should pass UITextField/UITextView intance. Assign textFieldView delegate to self, change it's returnKeyType.
    
    @param textFieldView UITextField/UITextView object to register.
    */
    open func addTextFieldView(_ view : UIView) {
        
        var dictInfo = [AnyHashable : Any]()
        
        dictInfo[kIQTextField] = view
        
        if let textField = view as? UITextField {
            
            dictInfo[kIQTextFieldReturnKeyType] = textField.returnKeyType
            
            if let textFieldDelegate = textField.delegate {
                dictInfo[kIQTextFieldDelegate] = textFieldDelegate
            }
            textField.delegate = self
            
        } else if let textView = view as? UITextView {
            
            dictInfo[kIQTextFieldReturnKeyType] = textView.returnKeyType
            
            if let textViewDelegate = textView.delegate {
                dictInfo[kIQTextFieldDelegate] = textViewDelegate
            }
            
            textView.delegate = self
        }
        
        textFieldInfoCache.append(dictInfo)
    }
    
    /**
    Should pass UITextField/UITextView intance. Restore it's textFieldView delegate and it's returnKeyType.
    
    @param textFieldView UITextField/UITextView object to unregister.
    */
    open func removeTextFieldView(_ view : UIView) {
        
        if let infoDict = textFieldViewCachedInfo(view) {
            
            if let textField = view as? UITextField {
                
                if let returnKeyType = infoDict[kIQTextFieldReturnKeyType] as? UIReturnKeyType {
                    textField.returnKeyType = returnKeyType
                }
                
                textField.delegate = infoDict[kIQTextFieldDelegate] as? UITextFieldDelegate
            } else if let textView = view as? UITextView {
                
                if let returnKeyType = infoDict[kIQTextFieldReturnKeyType] as? UIReturnKeyType {
                    textView.returnKeyType = returnKeyType
                }
                
                textView.delegate = infoDict[kIQTextFieldDelegate] as? UITextViewDelegate
            }
            
            if let index = textFieldInfoCache.index(where: { $0[kIQTextField] as! UIView == view}) {

                textFieldInfoCache.remove(at: index)
            }
        }
    }
    
    /**
    Add all the UITextField/UITextView responderView's.
    
    @param UIView object to register all it's responder subviews.
    */