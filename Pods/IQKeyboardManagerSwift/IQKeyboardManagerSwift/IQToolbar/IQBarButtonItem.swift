//
//  IQBarButtonItem.swift
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


import UIKit
import Foundation

open class IQBarButtonItem: UIBarButtonItem {

    private static var _classInitialize: Void = classInitialize()
    
    public override init() {
        _ = IQBarButtonItem._classInitialize
          super.init()
      }

    public required init?(coder aDecoder: NSCoder) {
        _ = IQBarButtonItem._classInitialize
           super.init(coder: aDecoder)
       }

   
    private class func classInitialize() {

        let  appearanceProxy = self.appearance()

        let states : [UIControlState] = [.normal,.highlighted,.disabled,.selected,.application,.reserved];

        for state in states {

            appearanceProxy.setBackgroundImage(nil, for: state, barMetrics: .default)
            appearanceProxy.setBackgroundImage(nil, for: state, style: .done, barMetrics: .default)
            appearanceProxy.setBackgroundImage(nil, for: state, style: .plain, barMetrics: .default)
            appearanceProxy.setBackButtonBackgroundImage(nil, for: state, barMetrics: .default)
        }
        
        appearanceProxy.setTitlePositionAdjustment(UIOffset.zero, for: .default)
        appearanceProxy.setBackgroundVerticalPositionAdjustment(0, for: .default)
        appearanceProxy.setBackButtonTitlePositionAdjustment(UIOffset.zero, for: .default)
        appearanceProxy.setBackButtonBackgroundVerticalPositionAdjustment(0, for: .default)
    }
    
    open override var tintColor: UIColor? {
        didSet {

            #if swift(>=4)
                var textAttributes = [NSAttributedStringKey : Any]()
                
                if let attributes = titleTextAttributes(for: .normal) {
                
                    for (key, value) in attributes {
                
                        textAttributes[NSAttributedStringKey.init(key)] = value
                    }
                }
                
                textAttributes[NSAttributedStringKey.foregroundColor] = tintColor
                
                setTitleTextAttributes(textAttributes, for: .normal)

            #else

                var textAttributes = [String:Any]()
                