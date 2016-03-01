//
//  RMWebViewController.swift
//  Remix
//
//  Created by fong tinyik on 2/13/16.
//  Copyright © 2016 fong tinyik. All rights reserved.
//

import UIKit

class RMActivityViewController: RxWebViewController, UIGestureRecognizerDelegate, BmobPayDelegate, ModalTransitionDelegate {
   
    var tr_presentTransition: TRViewControllerTransitionDelegate?
    
    var activity: BmobObject!
    var registeredActivitiesIds: [String] = []
    var ongoingTransactionId: String!
    var ongoingTransactionPrice: Double!
    var ongoingTransactionRemarks = "No comments."
    var currentUser = BmobUser.getCurrentObject()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       let containerView = UIView(frame: CGRectMake(0, DEVICE_SCREEN_HEIGHT - 114 , DEVICE_SCREEN_WIDTH, 50))
        containerView.backgroundColor = .clearColor()
        self.view.addSubview(containerView)
        let toolBar = UIView.loadFromNibNamed("RMToolBarView") as! RMToolBarView
        toolBar.backgroundColor = .blackColor()
        toolBar.registerButton.addTarget(self, action: "prepareForActivityRegistration", forControlEvents: .TouchUpInside)
        toolBar.showComments.addTarget(self, action: "showCommentsVC", forControlEvents: .TouchUpInside)
        toolBar.frame = containerView.bounds
        containerView.addSubview(toolBar)
        toolBar.clipsToBounds = true
        fetchOrdersInformation()
    }
    
    func fetchOrdersInformation() {
        let query = BmobQuery(className: "Orders")
        query.whereKey("CustomerObjectId", equalTo: currentUser.objectId)
        query.findObjectsInBackgroundWithBlock { (orders, error) -> Void in
            if error == nil {
                for order in orders {
                    print(order.objectId)
                    self.registeredActivitiesIds.append(order.objectForKey("ParentActivityObjectId") as! String)
                }
            }
        }
    }
    
    func showCommentsVC() {
        let storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let commentsVC = storyBoard.instantiateViewControllerWithIdentifier("CommentsVC") as! CommentsTableViewController
        commentsVC.presentingActivity = self.activity
        let naviController = UINavigationController(rootViewController: commentsVC)
        self.tr_presentViewController(naviController, method: TRPresentTransitionMethod.PopTip(visibleHeight: 400))

    }
    
    func prepareForActivityRegistration() {
 
        if registeredActivitiesIds.contains(activity.objectId) {
            let alert = UIAlertController(title: "报名提示", message: "你已报名了这个活动，请进入我的订单查看。", preferredStyle: .Alert)
            let action = UIAlertAction(title: "立即查看", style: .Default, handler: { (action) -> Void in
                self.presentSettingsVC()
            })
            let cancel = UIAlertAction(title: "继续逛逛", style: .Cancel, handler: nil)
            alert.addAction(action)
            alert.addAction(cancel)
            self.presentViewController(alert, animated: true, completion: nil)
            
        }else{
            if let _isRegOpen = activity.objectForKey("isRegistrationOpen") as? Bool {
                if _isRegOpen == true {
                    if checkPersonalInfoIntegrity() {
                        
                        
                        if let _needInfo = activity.objectForKey("isRequireRemarks") as? Bool {
                            if _needInfo == true {
                                let prompt = activity.objectForKey("AdditionalPrompt") as? String
                                let alert = UIAlertController(title: "附加信息", message: "除了你的基本信息外，此活动需要以下附加的报名信息: \n" + prompt!, preferredStyle: .Alert)
                                let action = UIAlertAction(title: "继续报名", style: .Default, handler: { (action) -> Void in
                                    self.ongoingTransactionRemarks = alert.textFields![0].text!
                                    self.registerForActivity()
                                })
                                let cancel = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
                                alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                                    textField.placeholder = "请输入附加报名信息"
                                    
                                })
                                alert.addAction(action)
                                alert.addAction(cancel)
                                self.presentViewController(alert, animated: true, completion: nil)
                                
                            }else{
                                registerForActivity()
                            }
                        }else{
                            registerForActivity()
                        }
                        
                        
                    }else{
                        let alert = UIAlertController(title: "完善信息", message: "请先进入账户设置完善个人信息后再继续报名参加活动。", preferredStyle: .Alert)
                        let action = UIAlertAction(title: "去设置", style: .Default, handler: { (action) -> Void in
                            self.presentSettingsVC()
                        })
                        let cancel = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
                        alert.addAction(action)
                        alert.addAction(cancel)
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    
                }else{
                    let alert = UIAlertController(title: "提示", message: "这个活动太火爆啦！参与活动人数已满(Ｔ▽Ｔ)再看看别的活动吧~下次记得早早下手哦。", preferredStyle: .Alert)
                    let action = UIAlertAction(title: "好吧", style: .Default, handler: nil)
                    alert.addAction(action)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }else{
                let alert = UIAlertController(title: "提示", message: "这个活动太火爆啦！参与活动人数已满(Ｔ▽Ｔ)再看看别的活动吧~下次记得早早下手哦。", preferredStyle: .Alert)
                let action = UIAlertAction(title: "好吧", style: .Default, handler: nil)
                alert.addAction(action)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
        }

    }
    
    func checkPersonalInfoIntegrity() -> Bool {
        currentUser = BmobUser.getCurrentUser()
        if currentUser.objectForKey("LegalName") == nil || currentUser.objectForKey("LegalName") as! String == "" {
            return false
        }
        
        if currentUser.objectForKey("School") == nil || currentUser.objectForKey("School") as! String == ""{
            return false
        }
        
        if currentUser.objectForKey("username") == nil || currentUser.objectForKey("username") as! String == ""{
            return false
        }
        
        if currentUser.objectForKey("email") == nil || currentUser.objectForKey("email") as! String == ""{
            return false
        }
        
        return true
    }

    
    func presentSettingsVC() {
        let storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let settingsVC = storyBoard.instantiateViewControllerWithIdentifier("SettingsVC")
        let navigationController = UINavigationController(rootViewController: settingsVC)
        self.navigationController?.presentViewController(navigationController, animated: true, completion: nil)
        
    }
    
    func registerForActivity() {
        
        
      
        let orgName = activity.objectForKey("Org") as? String
        
        if let price = activity.objectForKey("Price") as? Double {
            if price != 0 {
                ongoingTransactionId = activity.objectId
                ongoingTransactionPrice = price
                
                let alert = UIAlertController(title: "Remix报名确认", message: "确定要报名参加这个活动吗？(●'◡'●)ﾉ♥", preferredStyle: .Alert)
                let action = UIAlertAction(title: "确认", style: .Default, handler: { (action) -> Void in
                    let bPay = BmobPay()
                    bPay.delegate = self
                    bPay.price = NSNumber(double: price)
                    bPay.productName = orgName! + "活动报名费"
                    bPay.body = (self.activity.objectForKey("ItemName") as! String) + "用户姓名" + (self.currentUser.objectForKey("LegalName") as! String)
                    bPay.appScheme = "BmobPay"
                    bPay.payInBackgroundWithBlock({ (isSuccessful, error) -> Void in
                        if isSuccessful == false {
                            let alert = UIAlertController(title: "支付状态", message: "支付失败！请检查网络连接。", preferredStyle: .Alert)
                            let action = UIAlertAction(title: "好的", style: .Default, handler: nil)
                            alert.addAction(action)
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                    })
                })
                let cancel = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
                alert.addAction(action)
                alert.addAction(cancel)
                self.presentViewController(alert, animated: true, completion: nil)

                
            }else{
                ongoingTransactionId = activity.objectId
                ongoingTransactionPrice = 0
                let alert = UIAlertController(title: "Remix报名确认", message: "确定要报名参加这个活动吗？(●'◡'●)ﾉ♥", preferredStyle: .Alert)
                let action = UIAlertAction(title: "确认", style: .Default, handler: { (action) -> Void in
                    self.paySuccess()
                })
                let cancel = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
                alert.addAction(action)
                alert.addAction(cancel)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
            
        }else{
            ongoingTransactionId = activity.objectId
            ongoingTransactionPrice = 0
            let alert = UIAlertController(title: "Remix报名确认", message: "确定要报名参加这个活动吗？(●'◡'●)ﾉ♥", preferredStyle: .Alert)
            let action = UIAlertAction(title: "确认", style: .Default, handler: { (action) -> Void in
                self.paySuccess()
            })
            let cancel = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            alert.addAction(action)
            alert.addAction(cancel)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        
    }
    
    func paySuccess() {
        let newOrder = BmobObject(className: "Orders")
        newOrder.setObject(ongoingTransactionId, forKey: "ParentActivityObjectId")
        newOrder.setObject(ongoingTransactionPrice, forKey: "Amount")
        newOrder.setObject(currentUser.objectId, forKey: "CustomerObjectId")
        newOrder.setObject(ongoingTransactionRemarks, forKey: "Remarks")
        newOrder.setObject(true, forKey: "isVisibleToUsers")
        newOrder.saveInBackgroundWithResultBlock { (isSuccessful, error) -> Void in
            if isSuccessful {
                self.fetchOrdersInformation()
                let alert = UIAlertController(title: "支付状态", message: "报名成功！Remix已经把你的基本信息发送给了活动主办方。请进入 \"我的订单\" 查看", preferredStyle: .Alert)
                let cancel = UIAlertAction(title: "继续逛逛", style: .Cancel, handler: nil)
                let action = UIAlertAction(title: "立即查看", style: .Default) { (action) -> Void in
                    self.presentSettingsVC()
                }
                alert.addAction(action)
                alert.addAction(cancel)
                self.presentViewController(alert, animated: true, completion: nil)
            }else {
                let alert = UIAlertController(title: "支付状态", message: "Something is wrong. 这是一个极小概率的错误。不过别担心，如果已经被扣款, 请联系Remix客服让我们为你解决。（181-4977-0476）", preferredStyle: .Alert)
                let cancel = UIAlertAction(title: "稍后在说", style: .Cancel, handler: nil)
                let action = UIAlertAction(title: "立即拨打", style: .Default) { (action) -> Void in
                    UIApplication.sharedApplication().openURL(NSURL(string: "tel://18149770476")!)
                }
                alert.addAction(action)
                alert.addAction(cancel)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    func payFailWithErrorCode(errorCode: Int32) {
        
        let alert = UIAlertController(title: "支付状态", message: "支付失败。", preferredStyle: .Alert)
        let action = UIAlertAction(title: "好的", style: .Default, handler: nil)
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    


    
    
}