
<p align="center">
  <img src="https://raw.githubusercontent.com/hackiftekhar/IQKeyboardManager/master/Demo/Resources/icon.png" alt="Icon"/>
</p>
<H1 align="center">IQKeyboardManager</H1>
<p align="center">
  <img src="https://img.shields.io/github/license/hackiftekhar/IQKeyboardManager.svg"
  alt="GitHub license"/>


[![Build Status](https://travis-ci.org/hackiftekhar/IQKeyboardManager.svg)](https://travis-ci.org/hackiftekhar/IQKeyboardManager)
[![Coverage Status](http://img.shields.io/coveralls/hackiftekhar/IQKeyboardManager/master.svg)](https://coveralls.io/r/hackiftekhar/IQKeyboardManager?branch=master)
[![Code Health](https://landscape.io/github/hackiftekhar/IQKeyboardManager/master/landscape.svg?style=flat)](https://landscape.io/github/hackiftekhar/IQKeyboardManager/master)


Often while developing an app, We ran into an issues where the iPhone keyboard slide up and cover the `UITextField/UITextView`. `IQKeyboardManager` allows you to prevent issues of the keyboard sliding up and cover `UITextField/UITextView` without needing you to enter any code and no additional setup required. To use `IQKeyboardManager` you simply need to add source files to your project.


#### Key Features

[![Issue Stats](http://issuestats.com/github/hackiftekhar/iqkeyboardmanager/badge/pr?style=flat)](http://issuestats.com/github/hackiftekhar/iqkeyboardmanager)
[![Issue Stats](http://issuestats.com/github/hackiftekhar/iqkeyboardmanager/badge/issue?style=flat)](http://issuestats.com/github/hackiftekhar/iqkeyboardmanager)

1) `**CODELESS**, Zero Lines Of Code`

2) `Works Automatically`

3) `No More UIScrollView`

4) `No More Subclasses`

5) `No More Manual Work`

6) `No More #imports`

`IQKeyboardManager` works on all orientations, and with the toolbar. There are also nice optional features allowing you to customize the distance from the text field, add the next/previous done button as a keyboard UIToolbar, play sounds when the user navigations through the form and more.


## Screenshot
[![IQKeyboardManager](https://raw.githubusercontent.com/hackiftekhar/IQKeyboardManager/v3.3.0/Screenshot/IQKeyboardManagerScreenshot.png)](http://youtu.be/6nhLw6hju2A)
[![Settings](https://raw.githubusercontent.com/hackiftekhar/IQKeyboardManager/v3.3.0/Screenshot/IQKeyboardManagerSettings.png)](http://youtu.be/6nhLw6hju2A)

## GIF animation
[![IQKeyboardManager](https://raw.githubusercontent.com/hackiftekhar/IQKeyboardManager/v3.3.0/Screenshot/IQKeyboardManager.gif)](http://youtu.be/6nhLw6hju2A)

## Video

<a href="http://youtu.be/WAYc2Qj-OQg" target="_blank"><img src="http://img.youtube.com/vi/WAYc2Qj-OQg/0.jpg"
alt="IQKeyboardManager Demo Video" width="480" height="360" border="10" /></a>

## Warning

- **If you're planning to build SDK/library/framework and wants to handle UITextField/UITextView with IQKeyboardManager then you're totally going on wrong way.** I would never suggest to add IQKeyboardManager as dependency/adding/shipping with any third-party library, instead of adding IQKeyboardManager you should implement your custom solution to achieve same result. IQKeyboardManager is totally designed for projects to help developers for their convenience, it's not designed for adding/dependency/shipping with any third-party library, because **doing this could block adoption by other developers for their projects as well(who are not using IQKeyboardManager and implemented their custom solution to handle UITextField/UITextView thought the project).**
- If IQKeybaordManager conflicts with other third-party library, then it's developer responsibility to enable/disable IQKeyboardManager when presenting/dismissing third-party library UI. Third-party libraries are not responsible to handle IQKeyboardManager.

## Requirements
[![Platform iOS](https://img.shields.io/badge/Platform-iOS-blue.svg?style=fla)]()

|                        | Language | Minimum iOS Target | Minimum Xcode Version |
|------------------------|----------|--------------------|-----------------------|
| IQKeyboardManager      | Obj-C    | iOS 8.0            | Xcode 8.2.1           |
| IQKeyboardManagerSwift | Swift    | iOS 8.0            | Xcode 8.2.1           |
| Demo Project           |          |                    | Xcode 9.0             |

**Note**
- 3.3.7 is the last iOS 7 supported version.

#### Swift versions support

| Swift       | Xcode | IQKeyboardManagerSwift |
|-------------|-------|------------------------|
| 4.X         | 9.0   | >= 5.0.0               |
| 4.0         | 9.0   | 5.0.0                  |
| 3.1         | 8.3   | 4.0.10                 |
| 3.0 (3.0.2) | 8.2   | 4.0.8                  |
| 2.2 or 2.3  | 7.3   | 4.0.5                  |
| 2.1.1       | 7.2   | 4.0.0                  |
| 2.0         | 7.0   | 3.3.3.1                |

**Note**
- `5.0.0` is backward compatible till Swift 3.

Installation
==========================

#### Installation with CocoaPods

[![CocoaPods](https://img.shields.io/cocoapods/v/IQKeyboardManager.svg)](http://cocoadocs.org/docsets/IQKeyboardManager)

***IQKeyboardManager (Objective-C):*** IQKeyboardManager is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile: ([#9](https://github.com/hackiftekhar/IQKeyboardManager/issues/9))

```ruby
`pod 'IQKeyboardManager'` #iOS8 and later

`pod 'IQKeyboardManager', '3.3.7'` #iOS7
```

***IQKeyboardManager (Swift):*** IQKeyboardManagerSwift is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile: ([#236](https://github.com/hackiftekhar/IQKeyboardManager/issues/236))

*Swift 4.0 (Xcode 9.0)*

```ruby
pod 'IQKeyboardManagerSwift'
```

*Or you can choose version you need based on Swift support table from [Requirements](README.md#requirements)*

```ruby
pod 'IQKeyboardManagerSwift', '5.0.0'
```

In AppDelegate.swift, just import IQKeyboardManagerSwift framework and enable IQKeyboardManager.

```swift
import IQKeyboardManagerSwift

@UIApplicationMain