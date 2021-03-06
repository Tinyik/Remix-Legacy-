//
//  GalleryViewController.swift
//  Remix
//
//  Created by fong tinyik on 2/7/16.
//  Copyright © 2016 fong tinyik. All rights reserved.
//

import UIKit
import MWPhotoBrowser
import TTGSnackbar
class GalleryViewController: UITableViewController {
    
    var photoURLArray: [[[NSURL]]] = []
    var mwPhotos: [MWPhoto] = []
    var galleryObjects: [[AVObject]] = []
    var monthNameStrings: [String] = []
    var dateLabel: UILabel!
    let photoKeys = ["Pic0", "Pic1", "Pic2", "Pic3", "Pic4", "Pic5", "Pic6", "Pic7", "Pic8"]
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        self.tableView.separatorStyle = .None
        self.navigationController?.navigationBar.tintColor = .whiteColor()
        self.title = "往期活动"
        fetchCloudData()
        setUpParallaxHeaderView()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "添加报道", style: .Plain, target: self, action: "addGallery")
            
          }
    
    func addGallery() {
        let subm = GallerySubmissionViewController()
        let navi = RMNavigationController(rootViewController: subm)
        self.presentViewController(navi, animated: true, completion: nil)
    }

    func setUpParallaxHeaderView() {
        let headerView = ParallaxHeaderView.parallaxHeaderViewWithImage(UIImage(named: "Gallery"), forSize: CGSizeMake(UIScreen.mainScreen().bounds.width, 175)) as! ParallaxHeaderView
        self.tableView.tableHeaderView = headerView
        headerView.headerTitleLabel.text = "往期活动"
        
    }
    // MARK: - Table view data source
    
    func fetchCloudData() {
        let query = AVQuery(className: "Gallery")
        query.whereKey("Cities", containedIn: [REMIX_CITY_NAME])
        query.whereKey("isVisibleToUsers", equalTo: true)
        query.findObjectsInBackgroundWithBlock { (galleryObjects, error) -> Void in
            if error == nil {
                if galleryObjects.count > 0 {
                    for gallery in galleryObjects {
                        var imageURLs:[NSURL] = []
                        for key in self.photoKeys {
                            
                            if let imageFile = gallery.objectForKey(key) as? AVFile {
                                let imageURL = NSURL(string: imageFile.url)!
                                imageURLs.append(imageURL)
                            }
                        }
                        
                        
                        let dateString = gallery.objectForKey("Date") as! String
                        let monthName = dateString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[0] + " " + dateString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[2]
                        if self.isMonthAdded(monthName) == false {
                            self.monthNameStrings.append(monthName)
                            self.galleryObjects.append([gallery as! AVObject])
                            self.photoURLArray.append([imageURLs])
                        } else {
                            
                            if let index = self.galleryObjects.indexOf({
                                
                                ($0[0].objectForKey("Date") as! String).componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[0] + " " + dateString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[2] == monthName})
                            {
                                self.galleryObjects[index].append(gallery as! AVObject)
                                self.photoURLArray[index].append(imageURLs)
                            }
                            
                        }
                        
                        
                        
                        self.tableView.reloadData()
                    }
                }
            }else{
                let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                snackBar.backgroundColor = FlatWatermelonDark()
                snackBar.show()
            }
           
        }

    }
    
    func isMonthAdded(monthName: String) -> Bool {
        
        for _date in monthNameStrings {
            if _date == monthName {
                return true
            }
        }
        return false
    }
    
    func popCurrentVC() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        
        return galleryObjects[section].count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
  
        return monthNameStrings.count
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
 
        let dateHeaderView = UIView(frame: CGRectMake(30,0,UIScreen.mainScreen().bounds.width, 50))
        
        dateHeaderView.backgroundColor = .whiteColor()
        dateHeaderView.layer.shadowColor = UIColor.blackColor().CGColor
        dateHeaderView.layer.shadowOpacity = 0.08
        dateHeaderView.layer.shadowOffset = CGSizeMake(0, 0.7)
        dateLabel = UILabel(frame: CGRectMake(0,0,300,390))
        dateLabel.text = monthNameStrings[section]
        dateLabel.font = UIFont.systemFontOfSize(19)
        dateLabel.sizeToFit()
        dateHeaderView.addSubview(dateLabel)
        dateLabel.center = dateHeaderView.center
        dateLabel.center.x = UIScreen.mainScreen().bounds.width/2
        return dateHeaderView
        
        
    }
    
    
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      
        return  53
    }
    


    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("galleryTVCIdentifier") as! GalleryTableViewCell
        cell.photoURLs = photoURLArray[indexPath.section][indexPath.row]
        cell.titleLabel.text = galleryObjects[indexPath.section][indexPath.row].objectForKey("Title") as? String
        cell.desLabel.text = galleryObjects[indexPath.section][indexPath.row].objectForKey("Description") as? String
        cell.parentViewController = self
        cell.orgLabel.text = galleryObjects[indexPath.section][indexPath.row].objectForKey("Org") as? String
        let query = AVQuery(className: "Organization")
        query.whereKey("Name", equalTo: cell.orgLabel.text)
        query.findObjectsInBackgroundWithBlock({ (organizations, error) -> Void in
            if error == nil {
                if organizations.count == 1 {
                    for org in organizations {
                        let url = NSURL(string: (org.objectForKey("Logo") as! AVFile).url)
                        cell.orgLogo.sd_setImageWithURL(url, placeholderImage: UIImage(named: "SDPlaceholder"))
                    }

                }else{
                    cell.orgLogo.image = UIImage(named: "Placeholder")
                }
            }else{
                let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                snackBar.backgroundColor = FlatWatermelonDark()
                snackBar.show()
            }

        })
        
        cell.timeLabel.text = galleryObjects[indexPath.section][indexPath.row].objectForKey("Date") as? String
        cell.galleryView.reloadData()
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        // FIXME: 非空判断
        let query = AVQuery(className: "Gallery")
        query.whereKey("Cities", containedIn: [REMIX_CITY_NAME])
        let objectId = galleryObjects[indexPath.section][indexPath.row].objectId
        query.getObjectInBackgroundWithId(objectId) { (galleryObject, error) -> Void in
            if error == nil {
                galleryObject.incrementKey("PageView", byAmount: 1)
                galleryObject.saveInBackground()
            }else{
                let snackBar = TTGSnackbar.init(message: "获取数据失败。请检查网络连接后重试。", duration: .Middle)
                snackBar.backgroundColor = FlatWatermelonDark()
                snackBar.show()
            }

        
        }
        
        if let URLString = galleryObjects[indexPath.section][indexPath.row].objectForKey("URL") as? String {
            let webView = RxWebViewController(url: NSURL(string: URLString))
            self.navigationController?.pushViewController(webView, animated: true)
        }else{
            //Erro handling...
        }
        
            
        
    }
    
    override func viewDidAppear(animated: Bool) {
        (self.tableView.tableHeaderView as! ParallaxHeaderView).refreshBlurViewForNewImage()
        super.viewDidAppear(animated)
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
       
        let header: ParallaxHeaderView = tableView.tableHeaderView as! ParallaxHeaderView
        header.layoutHeaderViewForScrollViewOffset(scrollView.contentOffset)
        
    }
    
   
}
