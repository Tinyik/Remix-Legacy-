//
//  SettingsViewController.swift
//  Remix
//
//  Created by fong tinyik on 2/6/16.
//  Copyright © 2016 fong tinyik. All rights reserved.
//

import UIKit
import MessageUI
import SafariServices

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate, ModalTransitionDelegate {
   
    
    @IBOutlet weak var blurredAvatarView: UIImageView!
    
    @IBOutlet weak var firstTableView: UITableView!
    
    
    
    var tr_presentTransition: TRViewControllerTransitionDelegate?
    let currentUser = BmobUser.getCurrentUser()
    override func viewDidLoad() {
        super.viewDidLoad()
     
        self.navigationController?.navigationBar.translucent = false
        let closeButton = UIButton(frame: CGRectMake(0,0,27,27))
        closeButton.setImage(UIImage(named: "close"), forState: .Normal)
        closeButton.addTarget(self, action: "popCurrentVC", forControlEvents: .TouchUpInside)
        closeButton.alpha = 0.9
        let backItem = UIBarButtonItem(customView: closeButton)
        self.navigationItem.leftBarButtonItem = backItem
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        blurredAvatarView.contentMode = .ScaleAspectFill
        blurredAvatarView.clipsToBounds = true
        let blurEffect = UIBlurEffect(style: .Dark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = blurredAvatarView.frame
        visualEffectView.frame.size.width = view.frame.size.width
        blurredAvatarView.addSubview(visualEffectView)
        firstTableView.scrollEnabled = true
        firstTableView.separatorInset = UIEdgeInsetsZero
        
//        let avatarURL = NSURL(string:(BmobUser.getCurrentUser().objectForKey("Avatar") as! BmobFile).url)
//        let manager = SDWebImageManager()
//        manager.downloadImageWithURL(avatarURL, options: SDWebImageOptions.RetryFailed, progress: nil) { (avatar, error, cacheType, finished, url) -> Void in
//              self.avatarController = ZCSAvatarCaptureController()
//              self.avatarController.delegate = self
//              self.avatarController.image = avatar
//              self.blurredAvatarView.image = avatar
//              self.avatarView.addSubview(self.avatarController.view)
//            
//            
//        }

      
    }
    
   
    
//    func imageSelected(image: UIImage!) {
//        let avatarData = UIImagePNGRepresentation(image)
//        let newAvatar = BmobFile(fileName: "Avatar", withFileData: avatarData!)
//        currentUser.setObject(newAvatar, forKey: "Avatar")
//        currentUser.saveInBackground()
//        blurredAvatarView.image = image
//    }
//    
//    func imageSelectionCancelled() {
//        print("Canc")
//    }
    
    func popCurrentVC() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("detailedIdentifier") as! DetailedSettingsCell
            if indexPath.row == 0 {
           
                cell.titleLabel.text = "向我们推荐活动"
                cell.detailsLabel.text = "你的推荐将出现在 首页-社区推荐 中"
              
                return cell
            }else {
                
                cell.titleLabel.text = "向我们推荐魔都好去处"
                cell.detailsLabel.text = "你的推荐将出现在 首页-好去处 中"
                return cell
            }
            
        
        }
    
        if indexPath.section == 1 {
     let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier") as! SettingsCell
        switch indexPath.row {
        case 0: cell.label.text = "告诉朋友"
        case 1: cell.label.text = "反馈"
        case 2: cell.label.text = "加入我们"
        default: break
        }
       
        return cell
        }
        
    
            let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier") as! SettingsCell
            switch indexPath.row {
            case 0: cell.label.text = "清除缓存"
            case 1: cell.label.text = "退出登录"

            default: break
            }
            
            return cell
        
        
}

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 3
        }
       return 2
}
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 10
    }
    
  
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2{
            return "    Remix 1.0.1, by Tianyi Fang. \n    Visit fongtinyik.tumblr.com for more info."
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:if #available(iOS 9.0, *) {
                let safariView = SFSafariViewController(URL: NSURL(string: "http://jsform.com/f/v5pfam")!)
                safariView.view.tintColor = UIColor(red: 74/255, green: 144/255, blue: 224/255, alpha: 1)
                self.navigationController?.presentViewController(safariView, animated: true, completion: nil)
            } else {
                let webView = RxWebViewController(url: NSURL(string: "http://jsform.com/f/v5pfam")!)
                self.navigationController?.pushViewController(webView, animated: true)
                }
                
            case 1:if #available(iOS 9.0, *) {
                let safariView = SFSafariViewController(URL: NSURL(string: "http://jsform.com/f/j49bk8")!)
                safariView.view.tintColor = UIColor(red: 74/255, green: 144/255, blue: 224/255, alpha: 1)
                self.navigationController?.presentViewController(safariView, animated: true, completion: nil)
            } else {
                let webView = RxWebViewController(url: NSURL(string: "http://jsform.com/f/j49bk8")!)
                self.navigationController?.pushViewController(webView, animated: true)
                }
                
            default: break
            }
        }
        if indexPath.section == 1 {
            switch indexPath.row {
            //FIXME: Remix Official Website
            case 0:  let url = "http://fongtinyik.tumblr.com"
            let handler = UMSocialWechatHandler.setWXAppId("wx6e2c22b24588e0e1", appSecret: "e085edb726c5b92bf443f1e3da3f838e", url: url)
            UMSocialSnsService.presentSnsIconSheetView(self, appKey: "56ba8fa2e0f55a1071000931", shareText: "马上下载Remix来发现魔都最in学生活动与地点(●'◡'●)ﾉ♥", shareImage: UIImage(named: "Icon"), shareToSnsNames: [UMShareToWechatSession,UMShareToWechatTimeline, UMShareToQQ, UMShareToQzone, UMShareToTwitter], delegate: nil)
            case 1: if MFMailComposeViewController.canSendMail() {
                    let composer = MFMailComposeViewController()
                    composer.mailComposeDelegate = self
                    let device = UIDevice.currentDevice()
                    let identifierDictionary = DeviceInformation.appIdentifiers()
                    let subjectString = NSString(format: "Support for Remix %@ %@", identifierDictionary["shortString"]!, identifierDictionary["buildString"]!)
                    let bodyString = NSString(format: "\n\n\n-----\niOS Version: %@\nDevice: %@\n", device.systemVersion, DeviceInformation.hardwareIdentifier())
                    composer.setMessageBody(bodyString as String, isHTML: false)
                    composer.setSubject(subjectString as String)
                    composer.setToRecipients(["fongtinyik@gmail.com", "remixapp@163.com"])
                self.presentViewController(composer, animated: true, completion: nil)
                }
            case 2 : if MFMailComposeViewController.canSendMail() {
                let composer = MFMailComposeViewController()
                composer.mailComposeDelegate = self
                let subjectString = NSString(format: "Remix平台组织入驻申请")
                let bodyString = NSString(format: "简介:\n\n\n\n\n\n-----\n组织成立时间: \n组织名称:\n微信公众号ID:\n负责任联系方式:\n组织性质及分类:\n-----")
                composer.setMessageBody(bodyString as String, isHTML: false)
                composer.setSubject(subjectString as String)
                composer.setToRecipients(["fongtinyik@gmail.com", "remixapp@163.com"])
                self.presentViewController(composer, animated: true, completion: nil)
                }
            default: break
            }
        }
        if indexPath.section == 2 {
            switch indexPath.row {
            case 0: SDImageCache.sharedImageCache().clearDisk()
                    let alertController = UIAlertController(title: nil, message: "缓存清理成功", preferredStyle: .Alert)
                    let actionButton = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alertController.addAction(actionButton)
                    self.presentViewController(alertController, animated: true, completion: nil)
            case 1: BmobUser.logout()
            let storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let regLoginController = storyBoard.instantiateViewControllerWithIdentifier("RegLoginVC")
            self.tr_presentViewController(regLoginController, method: TRPresentTransitionMethod.Fade)
                
            default: break
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}