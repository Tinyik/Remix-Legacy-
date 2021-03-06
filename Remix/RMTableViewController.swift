//
//  RMTableViewController.swift
//  Remix
//
//  Created by fong tinyik on 2/5/16.
//  Copyright © 2016 fong tinyik. All rights reserved.
//

import UIKit
import PassKit
import SDWebImage
import TTGSnackbar
 
// Global Constants
let DEVICE_SCREEN_WIDTH = UIScreen.mainScreen().bounds.width
let DEVICE_SCREEN_HEIGHT = UIScreen.mainScreen().bounds.height
let COMMENTS_TABLE_VIEW_VISIBLE_HEIGHT: CGFloat = 450
var APPLICATION_UI_REMOTE_CONFIG: AVObject!
var APP_VERSION_AVAILABILITY = "Available"
var CURRENT_USER: AVUser!
var REMIX_CITY_NAME: String!

var naviController: RMSwipeBetweenViewControllers!
var isHomepageFirstLaunching: Bool!
var hasPromptedToEnableNotif: Bool!
var sharedOneSignalInstance: OneSignal!
var launchedTimes: Int!
var shouldAskToEnableNotif = true

enum Helper {
    case NewOrder, StatusChange
}
class RMTableViewController: TTUITableViewZoomController, MGSwipeTableCellDelegate, UISearchBarDelegate, PKPaymentAuthorizationViewControllerDelegate, BmobPayDelegate, RMActivityViewControllerDelegate, RMSwipeBetweenViewControllersDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var headerScrollView: UIScrollView!
    @IBOutlet weak var adTableView: UITableView!
    @IBOutlet weak var floatingScrollView: UIScrollView!
    
    @IBOutlet weak var filterButton_1: UIButton!
    @IBOutlet weak var filterButton_2: UIButton!
    @IBOutlet weak var filterButton_3: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var filterLabel_3: UILabel!
    @IBOutlet weak var filterLabel_2: UILabel!
    @IBOutlet weak var filterLabel_1: UILabel!
    var promoSnackbar: TTGSnackbar!
    var isRefreshing: Bool = false
    var coverImgURLs: [[NSURL]] = []
    var activities: [[AVObject]] = []
    var headerAds: [AVObject] = []
    var floatingActivities: [AVObject] = []
    var registeredActivitiesIds: [String] = []
    var monthNameStrings: [String] = []
    var dateLabel: UILabel!
    var likedActivitiesIds: [String] = []
    var adTargetURLs: [NSURL] = []
    var bannerAds: [AVObject]!
    var randomAdIndex = Int()
    var pageControl = UIPageControl(frame: CGRectMake(80, 240, 200, 50))
    var trackingAreas: [UIButton]! = []
    var indexPathForSelectedActivity: NSIndexPath!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Just to get around the not-in-hierarchy issue by adding a bit of delay here.
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if launchedTimes % 3 == 0 || launchedTimes == 2 {
                self.askToEnableNotifications()
            }
        }
        if CURRENT_USER.objectForKey("City") as! String == "全国" && launchedTimes == 1 {
            naviController.switchRemixCity()
        }
        
        cellZoomAnimationDuration = 0.4
        cellZoomXScaleFactor = 1.1
        cellZoomYScaleFactor = 1.1
        cellZoomInitialAlpha = 0.5
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.adTableView.scrollEnabled = false
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        self.tableView.tableFooterView = UIView()
        searchBar.delegate = self
        headerScrollView.delegate = self
        self.tableView.tableHeaderView?.hidden = true
        let refreshCtrl = UIRefreshControl()
        refreshCtrl.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
        self.refreshControl = refreshCtrl
        setUpViews()
        loadRemoteUIConfigurations()
        fetchCloudData()
        fetchCloudAdvertisement()
        fetchOrdersInformation()
        self.tableView.contentInset.top = 90
        
        //Registering nib
        self.tableView.registerNib(UINib(nibName: "MiddleCoverCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "MiddleCoverCell")
        self.tableView.registerNib(UINib(nibName: "RMTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "RMTableViewCell")
        
       
    
    }
    
    func callHelperMethods(type: Helper, phoneNumbers: [String], isSuccessful: Bool!, remark: String!) {
        if type == .StatusChange {
            RemixHelper.activityStatusChangeNotification(phoneNumbers, isSuccessful: isSuccessful, remark: remark)

        }else if type == .NewOrder {
            RemixHelper.newOrderNotification(phoneNumbers)
        }
    
    }
    
    func setUpViews() {
        
        adTableView.separatorStyle = .None
        searchBar.searchBarStyle = .Minimal
        self.tableView.separatorColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.4)
        self.navigationItem.hidesBackButton = true
    }
    
    
    
    func setUpTapTrackingArea() {
        trackingAreas = []
        for var i = 0; i < 3; ++i {
            let button = UIButton(frame: CGRectMake(CGFloat(i)*DEVICE_SCREEN_WIDTH/3, 64, DEVICE_SCREEN_WIDTH/3, 30))
            button.backgroundColor = .clearColor()
            button.tag = i
            trackingAreas.append(button)
            button.addTarget(self, action: "handlePageIndicatorSelection:", forControlEvents: .TouchUpInside)
            UIApplication.sharedApplication().keyWindow?.addSubview(button)
        }
    }
    
    func handlePageIndicatorSelection(button: UIButton) {
        (self.navigationController as! RMSwipeBetweenViewControllers).tapSegmentButtonAction(button)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        for button in trackingAreas {
            button.hidden = false
        }
    }
    
    
    func loadRemoteUIConfigurations() {
        let query = AVQuery(className: "UIRemoteConfig")
        query.getObjectInBackgroundWithId("56ea40b6f3609a00544ed773") { (config, error) -> Void in
            self.setUpTapTrackingArea() //FIXME: I don't know why but in viewDidLoad() keywindow? always return nil.
            if error == nil {
                APPLICATION_UI_REMOTE_CONFIG = config
                // Check Version availability
                
                self.filterLabel_1.text = config.objectForKey("FilterLabel_1_Text") as? String
                self.filterLabel_2.text = config.objectForKey("FilterLabel_2_Text") as? String
                self.filterLabel_3.text = config.objectForKey("FilterLabel_3_Text") as? String
                self.locationLabel.text = config.objectForKey("LocationLabel_Text") as? String
                let url1 = NSURL(string: (config.objectForKey("FilterButton_1_Image") as? AVFile)!.url)
                let url2 = NSURL(string: (config.objectForKey("FilterButton_2_Image") as? AVFile)!.url)
                let url3 = NSURL(string: (config.objectForKey("LocationButton_Image") as? AVFile)!.url)
                let url4 = NSURL(string: (config.objectForKey("FilterButton_3_Image") as? AVFile)!.url)
                if config.objectForKey("shouldShowSnackbar") as! Bool == true {
                    if launchedTimes % 3 != 0 && launchedTimes != 2 && launchedTimes != 1 {
                        let url = config.objectForKey("SnackbarURL") as! String
                        let message = config.objectForKey("SnackbarMessage") as! String
                        self.promoSnackbar = TTGSnackbar.init(message: message, duration: .Long, actionText: "查看", actionBlock: { (snackbar) -> Void in
                            UIApplication.sharedApplication().openURL(NSURL(string: url)!)
                            self.promoSnackbar.dismiss()
                        })
                        self.promoSnackbar.backgroundColor = FlatBlueDark()
                        self.promoSnackbar.alpha = 0.9
                        self.promoSnackbar.show()
                    }
                    
                }
                let manager = SDWebImageManager()
                manager.downloadImageWithURL(url1, options: .RetryFailed, progress: nil, completed: { (image, error, type, isSuccessful, url) -> Void in
                    self.filterButton_1.setImage(image, forState: .Normal)
                })
                manager.downloadImageWithURL(url2, options: .RetryFailed, progress: nil, completed: { (image, error, type, isSuccessful, url) -> Void in
                    self.filterButton_2.setImage(image, forState: .Normal)
                })
                manager.downloadImageWithURL(url3, options: .RetryFailed, progress: nil, completed: { (image, error, type, isSuccessful, url) -> Void in
                    self.locationButton.setImage(image, forState: .Normal)
                })
                manager.downloadImageWithURL(url4, options: .RetryFailed, progress: nil, completed: { (image, error, type, isSuccessful, url) -> Void in
                    self.filterButton_3.setImage(image, forState: .Normal)
                })
            }else{
                let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                snackBar.backgroundColor = FlatWatermelonDark()
                snackBar.show()
            }
        }
        let identifierDictionary = DeviceInformation.appIdentifiers()
        let query2 = AVQuery(className: "AppVersions")
        query2.whereKey("Version", equalTo: identifierDictionary["shortString"]!)
        query2.whereKey("Build", equalTo: identifierDictionary["buildString"]!)
        query2.findObjectsInBackgroundWithBlock { (versions, error) -> Void in
            if error == nil {
                if versions.count > 0 {
                    APP_VERSION_AVAILABILITY = versions[0].objectForKey("Status") as! String
                    self.checkVersionAvailability()
                }
            }else{
                let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                snackBar.backgroundColor = FlatWatermelonDark()
                snackBar.show()
            }
        }
    }
    
    func checkVersionAvailability() {
        switch APP_VERSION_AVAILABILITY {
        case "Expired": let alert = UIAlertController(title: "Remix过期提示", message: "该测试版本Remix已过期, 请从Apple官方渠道更新Remix或致电181-4977-0476获取技术支持。", preferredStyle: .Alert)
        let action = UIAlertAction(title: "退出Remix", style: .Destructive, handler: { (action) -> Void in
            exit(0)
        })
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
        case "Update": if launchedTimes % 3 == 1 {
            let alert = UIAlertController(title: "Remix提示", message: "新版本的Remix已经发布啦，想要现在立即更新吗？", preferredStyle: .Alert)
            let action = UIAlertAction(title: "立即更新", style: .Default, handler: { (action) -> Void in
                UIApplication.sharedApplication().openURL(NSURL(string: APPLICATION_UI_REMOTE_CONFIG.objectForKey("Appstore") as! String)!)
            })
            let cancel = UIAlertAction(title: "稍后在说", style: .Cancel, handler: nil)
            alert.addAction(action)
            alert.addAction(cancel)
            self.presentViewController(alert, animated: true, completion: nil)

                      }
        default: break
        }
        
    }

    
    func configurePageControl() {
       
        pageControl.addTarget(self, action: Selector("changePage:"), forControlEvents: UIControlEvents.ValueChanged)
        pageControl.numberOfPages = adTargetURLs.count
        pageControl.currentPage = 0
        pageControl.tintColor = UIColor.blackColor()
        pageControl.pageIndicatorTintColor = UIColor(white: 0.4, alpha: 0.8)
        pageControl.currentPageIndicatorTintColor = UIColor.whiteColor()
        self.view.addSubview(pageControl)
        
    }
    
    func changePage(sender: AnyObject) -> () {
        let x = CGFloat(pageControl.currentPage) * headerScrollView.frame.size.width
        headerScrollView.setContentOffset(CGPointMake(x, 0), animated: true)
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        if scrollView == headerScrollView {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
            
        }
    }
    
    func presentSettingsVC() {
        let storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let settingsVC = storyBoard.instantiateViewControllerWithIdentifier("SettingsVC")
        let navigationController = RMNavigationController(rootViewController: settingsVC)
        self.navigationController?.presentViewController(navigationController, animated: true, completion: nil)

    }
    
    func fetchOrdersInformation() {
        registeredActivitiesIds = []
        let query = AVQuery(className: "Orders")
        query.whereKey("CustomerObjectId", equalTo: AVUser(outDataWithObjectId: CURRENT_USER.objectId))
        query.findObjectsInBackgroundWithBlock { (orders, error) -> Void in
            if error == nil {
                for order in orders {
                   
                    if let o = order.objectForKey("ParentActivityObjectId") as? AVObject {
                        self.registeredActivitiesIds.append(o.objectId)
                    }

                }
                self.setUpFloatingScrollView()
            }else{
                let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                snackBar.backgroundColor = FlatWatermelonDark()
                snackBar.show()
            }
        }
    }

    
    func setUpFloatingScrollView() {
        for subView in floatingScrollView.subviews {
            subView.removeFromSuperview()
        }
        var imageURLs: [NSURL] = []
        for activity in floatingActivities {
            let imageURL = NSURL(string: (activity.objectForKey("CoverImg") as! AVFile).url)
            imageURLs.append(imageURL!)

        }

        // children
        let elementMargin: CGFloat = 10
        let elementWidth: CGFloat = (DEVICE_SCREEN_WIDTH - 3 * elementMargin) / 2.2 // 2 & a bit of the 3rd
        
        self.floatingScrollView.contentSize = CGSizeMake(elementMargin + (elementWidth + elementMargin) * CGFloat(floatingActivities.count), self.floatingScrollView.frame.height)
        self.floatingScrollView.userInteractionEnabled = true
        
        for var i = 0; i < floatingActivities.count; ++i {
            let fView = FloatingActivityView.loadFromNibNamed("FloatingActivityView") as! FloatingActivityView
            fView.tag = i
            fView.activity = self.floatingActivities[i]
            fView.registeredActivitiesIds = self.registeredActivitiesIds
            fView.parentViewController = self
            fView.frame = CGRectMake(elementMargin + (elementWidth + elementMargin) * CGFloat(i), 0, elementWidth, 185)
            
            fView.imageView.sd_setImageWithURL(imageURLs[i], placeholderImage: UIImage(named: "SDPlaceholder"))
            let tap = UITapGestureRecognizer(target: self, action: "handleFloatingViewSelection:")
            fView.addGestureRecognizer(tap)
            fView.titleLabel.text = self.floatingActivities[i].objectForKey("Title") as! String
            
            if let price = self.floatingActivities[i].objectForKey("Price") as? Double {
                if price != 0 {
                    let priceNumberFont = UIFont.systemFontOfSize(17)
                    let attrDic1 = [NSFontAttributeName:priceNumberFont]
                    let priceString = NSMutableAttributedString(string: String(price), attributes: attrDic1)
                    let currencyFont = UIFont.systemFontOfSize(13)
                    let attrDic2 = [NSFontAttributeName:currencyFont]
                    let currencyString = NSMutableAttributedString(string: "元", attributes: attrDic2)
                    priceString.appendAttributedString(currencyString)
                    fView.priceTag.attributedText = priceString
             
                }else{
                    fView.priceTag.text = "免费"
                    fView.payButton.setImage(UIImage(named: "RegisterButton"), forState: .Normal)
                }

            }
            
            
            // heights
            var contentRect = CGRectZero
            for view in fView.subviews {
                view.layoutIfNeeded()
                contentRect = CGRectUnion(contentRect, view.frame)
            }
            
            let h = contentRect.size.height
            if h > self.floatingScrollView.frame.size.height {
                self.floatingScrollView.frame.size.height = h
            }
            self.floatingScrollView.contentSize.height = h
            fView.frame.size.height = h
            fView.frame.origin.y += (self.floatingScrollView.frame.size.height - h) / 2
            
            self.floatingScrollView.addSubview(fView)
        }
            
        
    }
    
    func fetchCloudAdvertisement() {
        adTargetURLs = []
        headerAds = []
        let query = AVQuery(className: "HeaderPromotion")
        query.whereKey("isVisibleToUsers", equalTo: true)
        query.whereKey("Cities", containedIn: [REMIX_CITY_NAME])
        query.findObjectsInBackgroundWithBlock { (ads, error) -> Void in
            if error == nil {
                if self.isRefreshing == true {
                    self.isRefreshing = false
                    self.refreshControl?.endRefreshing()
                }
                var adImageURLs: [NSURL] = []
                for ad in ads{
                    let adImageURL = NSURL(string: (ad.objectForKey("AdImage") as! AVFile).url)
                    if let urlString = ad.objectForKey("URL") as? String {
                        self.adTargetURLs.append(NSURL(string: urlString)!)
                    }
                    adImageURLs.append(adImageURL!)
                    self.headerAds.append(ad as! AVObject)
                }
                
                
                let screenWidth = UIScreen.mainScreen().bounds.width
                self.headerScrollView.contentSize = CGSizeMake(screenWidth*CGFloat((ads.count)), self.headerScrollView.frame.height)
                self.headerScrollView.userInteractionEnabled = true
                
                for var i = 0; i < ads.count; ++i {
                    let headerImageView = UIImageView(frame: CGRectMake(screenWidth*CGFloat(i),0,screenWidth,self.headerScrollView.frame.height ))
                    
                    // easy fix;
                    // to avoid the extra top & bottom margins requires a more complicated solution,
                    // which includes calculating the total height of several top elements in this view
                    headerImageView.contentMode = .ScaleAspectFit
                    
                    headerImageView.clipsToBounds = true
                    headerImageView.tag = i
                    headerImageView.userInteractionEnabled = true
                    let tap = UITapGestureRecognizer(target: self, action: "handlePromoSelection:")
                    headerImageView.addGestureRecognizer(tap)
                    headerImageView.sd_setImageWithURL(adImageURLs[i], placeholderImage: UIImage(named: "SDPlaceholder"))
                    self.headerScrollView.addSubview(headerImageView)
                    
                }
                
                self.configurePageControl()
                self.pageControl.frame.origin.x = UIScreen.mainScreen().bounds.size.width/2 - self.pageControl.frame.size.width/2
            }else{
                let alert = UIAlertController(title: "Remix提示", message: "出错了！ |ﾟДﾟ)))请检查你的网络连接后重试。", preferredStyle: .Alert)
                let action = UIAlertAction(title: "好的", style: .Default, handler: { (action) -> Void in
                    if self.isRefreshing == true {
                        self.isRefreshing = false
                        self.refreshControl?.endRefreshing()
                    }
                })
                
                alert.addAction(action)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
        }
    
    }
    
    func fetchCloudData() {
        coverImgURLs = []
      
        monthNameStrings = []
        activities = []
        floatingActivities = []
        
        let query = AVQuery(className: "Activity")
        query.whereKey("isVisibleToUsers", equalTo: true)
        query.whereKey("isVisibleOnMainList", equalTo: true)
        query.whereKey("Cities", containedIn: [REMIX_CITY_NAME])
        query.orderByDescending("InternalDate")
        query.findObjectsInBackgroundWithBlock { (activities, error) -> Void in
            if error == nil {
                if activities.count > 0 {
                    self.tableView.tableHeaderView?.hidden = false
                    for activity in activities {
                        if activity.objectForKey("isFloatingActivity") as! Bool == false {
                            
                            let coverImg = activity.objectForKey("CoverImg") as! AVFile
                            let imageURL = NSURL(string:coverImg.url)!
                            
                            let dateString = activity.objectForKey("Date") as! String
                            let monthName = dateString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[0] + " " + dateString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[2]
                            
                            if self.isMonthAdded(monthName) == false {
                                self.monthNameStrings.append(monthName)
                                self.activities.append([activity as! AVObject])
                                self.coverImgURLs.append([imageURL])
                               
                            } else {
                                
                                if let index = self.activities.indexOf({
                                    
                                    ($0[0].objectForKey("Date") as! String).componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[0] + " " + dateString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[2] == monthName})
                                {
                                    self.activities[index].append(activity as! AVObject)
                                    self.coverImgURLs[index].append(imageURL)
                                }
                                
                            }
                            
                        }else{
                            
                            self.floatingActivities.append(activity as! AVObject)
                        }
                    }
                    self.fetchOrdersInformation()
                    self.tableView.reloadData()
                    
                }else{
                    self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top)
                    self.tableView.tableHeaderView?.hidden = true
                    self.tableView.reloadData()
                }

            }else{
                let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                snackBar.backgroundColor = FlatWatermelonDark()
                snackBar.show()
            }

        }
        
                fetchLikedActivitiesList()
    }
    
    func fetchLikedActivitiesList() {
        if let _likedlist = CURRENT_USER.objectForKey("LikedActivities") as? [String] {
            likedActivitiesIds = _likedlist
        }
    }
    
    func refresh() {
        isRefreshing = true
        self.adTableView.reloadData()
        loadRemoteUIConfigurations()
        fetchCloudData()
        fetchCloudAdvertisement()

    }
        
    func isMonthAdded(monthName: String) -> Bool {
        
        for _date in monthNameStrings {
            if _date == monthName {
                return true
            }
        }
        return false
    }
    
    func handleFloatingViewSelection(sender: UIGestureRecognizer) {
        if launchedTimes! == 1 && shouldAskToEnableNotif {
            askToEnableNotifications()
            shouldAskToEnableNotif = false
        }
        let targetURL = NSURL(string: floatingActivities[(sender.view?.tag)!].objectForKey("URL") as! String)
       
            let activityView = RMActivityViewController(url: targetURL)
            activityView.activity = floatingActivities[(sender.view?.tag)!]
            activityView.delegate = self
            activityView.isFloating = true
        if likedActivitiesIds.contains(floatingActivities[(sender.view?.tag)!].objectId) {
            activityView.isLiked = true
        }else{
            activityView.isLiked = false
        }
        
            self.navigationController?.pushViewController(activityView, animated: true)
    }
    
    func handlePromoSelection(sender: UIGestureRecognizer) {
        if launchedTimes! == 1 && shouldAskToEnableNotif {
            askToEnableNotifications()
            shouldAskToEnableNotif = false
        }
        
        if let parentActivity = headerAds[(sender.view?.tag)!].objectForKey("ParentActivityObjectId") as? AVObject {
            let query = AVQuery(className: "Activity")
            query.getObjectInBackgroundWithId(parentActivity.objectId, block: { (activity, error) -> Void in
                if error == nil {
                    let activityView = RMActivityViewController(url: NSURL(string: activity.objectForKey("URL") as! String))
                    activityView.activity = activity
                    self.navigationController?.pushViewController(activityView, animated: true)

                }else{
                    let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                    snackBar.backgroundColor = FlatWatermelonDark()
                    snackBar.show()
                }

            })
            
        }else{
          
            
                let webVC = RxWebViewController(url: adTargetURLs[(sender.view?.tag)!])
                self.navigationController?.pushViewController(webVC, animated: true)
            
            
        }
        
    }
    
    func refreshViewContentForCityChange() {
     
        self.refresh()
        
    }
    
    func reloadRowForActivity(activity: AVObject, isFloating: Bool) {
        fetchLikedActivitiesList()
            let query = AVQuery(className: "Activity")
            query.whereKey("Cities", containedIn: [REMIX_CITY_NAME])
            query.getObjectInBackgroundWithId(activity.objectId) { (activity, error) -> Void in
                if error == nil {
                    if isFloating == false{
                        self.activities[self.indexPathForSelectedActivity.section][self.indexPathForSelectedActivity.row] = activity
                        self.tableView.reloadRowsAtIndexPaths([self.indexPathForSelectedActivity], withRowAnimation: .Automatic)
                    }else{
                        let index = self.floatingActivities.indexOf({$0.objectId == activity.objectId})
                        self.floatingActivities[self.floatingActivities.startIndex.advancedBy(index!)] = activity
                    }
                }else{
                    let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                    snackBar.backgroundColor = FlatWatermelonDark()
                    snackBar.show()
                }
                
            }


    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if tableView == adTableView {
            return DEVICE_SCREEN_WIDTH*0.4
        }
        
        if activities.count > 0 {
            if let isFeatured = activities[indexPath.section][indexPath.row].objectForKey("isFeatured") as? Bool  {
                if isFeatured == true {
                    return UITableViewAutomaticDimension
                }
            }
        }
        return 166
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // don't know about the adTableView, so the first value might need to change in the future
        return (tableView == adTableView) ? 0 : 350
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if tableView == adTableView {
            return 1
        }
  
        return activities[section].count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if tableView == adTableView {
            return 1
        }
        
        return monthNameStrings.count
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if tableView == adTableView {
            return nil
        }
        
        let dateHeaderView = UIView(frame: CGRectMake(30,0,UIScreen.mainScreen().bounds.width, 50))
        
        dateHeaderView.backgroundColor = .whiteColor()
        dateHeaderView.layer.shadowColor = UIColor.blackColor().CGColor
        dateHeaderView.layer.shadowOpacity = 0.08
        dateHeaderView.layer.shadowOffset = CGSizeMake(0, 0.7)
        dateLabel = UILabel(frame: CGRectMake(0,0,300,390))
        
        if monthNameStrings.count > section {
            dateLabel.text = monthNameStrings[section]
        }else{
            let alert = UIAlertController(title: "Remix提示", message: "出错了！ |ﾟДﾟ)))请检查你的网络连接后重试。", preferredStyle: .Alert)
            let action = UIAlertAction(title: "立即重试", style: .Default, handler: { (action) -> Void in
                if self.isRefreshing == false {
                    self.isRefreshing = true
                    self.refreshControl?.beginRefreshing()
                }
            })
            
            let cancel = UIAlertAction(title: "好的", style: .Cancel, handler: nil)
            alert.addAction(cancel)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        dateLabel.font = UIFont.systemFontOfSize(19)
        dateLabel.sizeToFit()
        dateHeaderView.addSubview(dateLabel)
        dateLabel.center = dateHeaderView.center
        dateLabel.center.x = UIScreen.mainScreen().bounds.width/2
        return dateHeaderView
        
        
    }
    
    
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == adTableView {
            return 0
        }
        return  53
    }
    
  

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        if tableView == adTableView {
            let action = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "换一换", handler: { (action, indexpath) -> Void in
                self.adTableView.reloadData()
            })
           return [action]
        }
        
        return nil
    }
    
   override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if tableView == self.tableView {
            return false
        }
        
        return true
    }
    
   
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if tableView == adTableView {
            self.bannerAds = []
            let cell = tableView.dequeueReusableCellWithIdentifier("adCellReuseIdentifier", forIndexPath: indexPath) as! AdvertiseCell
            let query = AVQuery(className: "BannerPromotion")
            query.whereKey("isVisibleToUsers", equalTo: true)
            query.whereKey("Cities", containedIn: [REMIX_CITY_NAME])
            query.findObjectsInBackgroundWithBlock({ (promotions, error) -> Void in
                if error == nil {
                    if promotions.count > 0{
                       
                        for promotion in promotions {
                            self.bannerAds.append(promotion as! AVObject)
                        }
                        self.randomAdIndex = Int(arc4random_uniform(UInt32(self.bannerAds.count)))
                        let adImageURL = NSURL(string:(self.bannerAds[self.randomAdIndex].objectForKey("AdImage") as! AVFile).url)
                        
                        cell.adImageView.sd_setImageWithURL(adImageURL, placeholderImage: UIImage(named: "SDPlaceholder"))
                        tableView.userInteractionEnabled = true
                    }else{
                        tableView.userInteractionEnabled = false
                    }
                }else{
                    let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                    snackBar.backgroundColor = FlatWatermelonDark()
                    snackBar.show()
                }

                
            })
            return cell
        }else {
            let selectedActivity = activities[indexPath.section][indexPath.row]
            if (selectedActivity.objectForKey("isFeatured") as! Bool) == true {
                
                let cell = tableView.dequeueReusableCellWithIdentifier("MiddleCoverCell", forIndexPath: indexPath) as! RMFullCoverCell
                cell.delegate = self
                cell.parentViewController = self
                if let price = selectedActivity.objectForKey("Price") as? Double {
                    if price != 0 {
                        let priceNumberFont = UIFont.systemFontOfSize(19)
                        let attrDic1 = [NSFontAttributeName:priceNumberFont]
                        let priceString = NSMutableAttributedString(string: String(price), attributes: attrDic1)
                        let currencyFont = UIFont.systemFontOfSize(13)
                        let attrDic2 = [NSFontAttributeName:currencyFont]
                        let currencyString = NSMutableAttributedString(string: "元/人", attributes: attrDic2)
                        priceString.appendAttributedString(currencyString)
                        cell.priceTag.attributedText = priceString
                        
                    }else{
                        cell.priceTag.text = "免费"
                       
                    }
                }
                cell.titleLabel.text = selectedActivity.objectForKey("Title") as? String
                cell.orgLabel.text = selectedActivity.objectForKey("Org") as? String
                if let summary = selectedActivity.objectForKey("Summary") as? String{
                    cell.orgLabel.text = cell.orgLabel.text! + summary
                }

                cell.timeLabel.text = selectedActivity.objectForKey("Date") as? String
                cell.likesNumberLabel.text = String(selectedActivity.objectForKey("LikesNumber") as! Int)
                  cell.fullImageView.sd_setImageWithURL(coverImgURLs[indexPath.section][indexPath.row], placeholderImage: UIImage(named: "SDPlaceholder"))
                let _objId = selectedActivity.objectId
                cell.objectId = _objId
                let query = AVQuery(className: "Organization")
                query.whereKey("Name", equalTo: selectedActivity.objectForKey("Org") as? String)
                query.findObjectsInBackgroundWithBlock({ (organizations, error) -> Void in
                    if error == nil {
                        if organizations.count == 1 {
                            let url = NSURL(string: (organizations[0].objectForKey("Logo") as! AVFile).url)
                            cell.orgLogo.sd_setImageWithURL(url, placeholderImage: UIImage(named: "SDPlaceholder"))
                        }else{
                            cell.orgLogo.image = UIImage(named:"Placeholder")
                        }
                    }else{
                        let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                        snackBar.backgroundColor = FlatWatermelonDark()
                        snackBar.show()
                    }
                })
               
                if likedActivitiesIds.contains(_objId) {
                    
                    cell.isLiked = true
                }else{
                    
                    cell.isLiked = false
                }
                
                return cell
            }
            
        let cell = tableView.dequeueReusableCellWithIdentifier("RMTableViewCell", forIndexPath: indexPath) as! RMTableViewCell
        if let summary = selectedActivity.objectForKey("Summary") as? String {
            cell.summaryLabel.text = summary
        }else{
            cell.summaryLabel.text = ""
        }
        cell.delegate = self
        cell.parentViewController = self
            if let price = selectedActivity.objectForKey("Price") as? Double {
                if price != 0 {
                    let priceNumberFont = UIFont.systemFontOfSize(19)
                    let attrDic1 = [NSFontAttributeName:priceNumberFont]
                    let priceString = NSMutableAttributedString(string: String(price), attributes: attrDic1)
                    let currencyFont = UIFont.systemFontOfSize(13)
                    let attrDic2 = [NSFontAttributeName:currencyFont]
                    let currencyString = NSMutableAttributedString(string: "元/人", attributes: attrDic2)
                    priceString.appendAttributedString(currencyString)
                    cell.priceTag.attributedText = priceString
                }else{
                    cell.priceTag.text = "免费"
                    
                }
            }
        cell.titleLabel.text = selectedActivity.objectForKey("Title") as? String
        cell.desLabel.text = selectedActivity.objectForKey("Description") as? String
        cell.orgLabel.text = selectedActivity.objectForKey("Org") as? String
        cell.timeLabel.text = selectedActivity.objectForKey("Date") as? String
        cell.likesNumberLabel.text = String(selectedActivity.objectForKey("LikesNumber") as! Int)
        cell.themeImg.sd_setImageWithURL(coverImgURLs[indexPath.section][indexPath.row], placeholderImage: UIImage(named: "SDPlaceholder"))
        let _objId = selectedActivity.objectId
        cell.objectId = _objId
            let query = AVQuery(className: "Organization")
            query.whereKey("Name", equalTo: selectedActivity.objectForKey("Org") as? String)
            query.findObjectsInBackgroundWithBlock({ (organizations, error) -> Void in
                if error == nil {
                    if organizations.count == 1 {
                        let url = NSURL(string: (organizations[0].objectForKey("Logo") as! AVFile).url)
                        cell.orgLogo.sd_setImageWithURL(url, placeholderImage: UIImage(named: "SDPlaceholder"))
                    }else{
                        cell.orgLogo.image = UIImage(named:"Placeholder")
                    }
                    
                }else{
                    let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                    snackBar.backgroundColor = FlatWatermelonDark()
                    snackBar.show()
                }
            })
            if likedActivitiesIds.contains(_objId) {
                cell.isLiked = true
            }else{
                cell.isLiked = false
            }

        
            return cell
        }
        
    }
    
    
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
      
        if launchedTimes == 1 && shouldAskToEnableNotif {
            askToEnableNotifications()
            shouldAskToEnableNotif = false
        }
        if tableView == adTableView {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            let query = AVQuery(className: "BannerPromotion")
            query.whereKey("Cities", containedIn: [REMIX_CITY_NAME])
            let objectId = bannerAds[randomAdIndex].objectId
            query.getObjectInBackgroundWithId(objectId) { (ad, error) -> Void in
                if error == nil {
                    ad.incrementKey("PageView", byAmount: 1)
                    ad.saveInBackground()

                }else{
                    let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                    snackBar.backgroundColor = FlatWatermelonDark()
                    snackBar.show()
                }
            }
            let adTargetURL = NSURL(string:(self.bannerAds[Int(self.randomAdIndex)].objectForKey("URL") as! String))
            
                let webView = RxWebViewController(url: adTargetURL!)
                self.navigationController?.pushViewController(webView, animated: true)
            

            
        }
        
        if tableView == self.tableView {
            
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
            let query = AVQuery(className: "Activity")
            query.whereKey("Cities", containedIn: [REMIX_CITY_NAME])
            let objectId = activities[indexPath.section][indexPath.row].objectId
            query.getObjectInBackgroundWithId(objectId) { (activity, error) -> Void in
                if error == nil {
                activity.incrementKey("PageView", byAmount: 1)
                activity.saveInBackground()
                }else{
                    let alert = UIAlertController(title: "Remix提示", message: "出错了！ |ﾟДﾟ)))请检查你的网络连接后重试。", preferredStyle: .Alert)
                    let action = UIAlertAction(title: "好的", style: .Default, handler: nil)
                    alert.addAction(action)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }

           let activityView = RMActivityViewController(url: NSURL(string: activities[indexPath.section][indexPath.row].objectForKey("URL") as! String)!)
            activityView.activity = activities[indexPath.section][indexPath.row]
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? RMFullCoverCell {
                activityView.isLiked = cell.isLiked
            }
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? RMTableViewCell {
                activityView.isLiked = cell.isLiked
            }
            indexPathForSelectedActivity = indexPath
            activityView.delegate = self
            self.navigationController?.pushViewController(activityView, animated: true)
   
            
      
       
        }
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        for button in trackingAreas {
            button.hidden = true
        }
        let storyBoard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let searchResultVC = storyBoard.instantiateViewControllerWithIdentifier("SearchVC")
        self.navigationController?.pushViewController(searchResultVC, animated: true)
        return false
    }
    
    func askToEnableNotifications() {
    
        let userDefault = NSUserDefaults.standardUserDefaults()
        sharedOneSignalInstance.IdsAvailable { (userId, pushToken) -> Void in
            if pushToken != nil {
                userDefault.setBool(true, forKey: "isRegisteredForNotif")
               
            }else{
                userDefault.setBool(false, forKey: "isRegisteredForNotif")
              
            }
            
        }
        if let key = userDefault.objectForKey("isRegisteredForNotif") as? Bool {
            
            if key == false {
                let alert = UIAlertController(title: "推送设置", message: "Remix需要你允许推送消息才能及时传递当前城市学生圈的最新消息。想要现在允许推送消息吗？(●'◡'●)ﾉ♥", preferredStyle: .Alert)
                let buttonOK = UIAlertAction(title: "好的", style: .Default) { (action) -> Void in
                    self.promptToEnableNotifications()
                }
                let buttonCancel = UIAlertAction(title: "不了谢谢", style: .Default, handler: { (action) -> Void in
                    self.checkVersionAvailability()
                })
                alert.addAction(buttonCancel)
                alert.addAction(buttonOK)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }else{
            let alert = UIAlertController(title: "推送设置", message: "Remix需要你允许推送消息才能及时传递当前城市学生圈的最新消息。想要现在允许推送消息吗？(●'◡'●)ﾉ♥", preferredStyle: .Alert)
            let buttonOK = UIAlertAction(title: "好的", style: .Default) { (action) -> Void in
                self.promptToEnableNotifications()
            }
            let buttonCancel = UIAlertAction(title: "不了谢谢", style: .Default, handler: { (action) -> Void in
                self.checkVersionAvailability()
            })

            alert.addAction(buttonCancel)
            alert.addAction(buttonOK)
            self.presentViewController(alert, animated: true, completion: nil)
            
        }

        
           }
    
    func promptToEnableNotifications() {
        self.checkVersionAvailability()
        if hasPromptedToEnableNotif == false {
            sharedOneSignalInstance.registerForPushNotifications()
            let userDefaults = NSUserDefaults.standardUserDefaults()
            userDefaults.setObject(true, forKey: "hasPromptedToEnableNotif")
            hasPromptedToEnableNotif = true
        
        }else{
             
                let instruction = UIAlertController(title: "如何开启消息通知", message: "请进入 设置->通知->Remix->允许通知 来开启Remix推送消息。", preferredStyle: .Alert)
                let ok = UIAlertAction(title: "好的", style: .Default, handler: nil)
                instruction.addAction(ok)
                self.presentViewController(instruction, animated: true, completion: nil)
           
        }
    }
   
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        completion(PKPaymentAuthorizationStatus.Success)
    }
    
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //DZNEmptyDataSet
    
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attrDic = [NSFontAttributeName: UIFont.systemFontOfSize(19)]
        return NSAttributedString(string: "(:3[____] 哎呀...! 你发现了一座空荡荡的城池！\n", attributes: attrDic)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrDic = [NSFontAttributeName: UIFont.systemFontOfSize(15)]
        return NSAttributedString(string: "快点击左上角向Remix提交活动，成为邦主吧！如果你想离开这里, 你也可以：", attributes: attrDic)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let attrDic = [NSFontAttributeName: UIFont.systemFontOfSize(17), NSForegroundColorAttributeName: FlatRed()]
        return NSAttributedString(string: "切换城市", attributes: attrDic)
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return UIColor(red: 0.97255, green: 0.97255, blue: 0.97255, alpha: 1)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "NoData")
    }
    
    func emptyDataSetShouldAllowScroll(scrollView: UIScrollView!) -> Bool {
        return false
    }
    
    func emptyDataSet(scrollView: UIScrollView!, didTapButton button: UIButton!) {
        (self.navigationController as! RMSwipeBetweenViewControllers).switchRemixCity()
    }

}
   