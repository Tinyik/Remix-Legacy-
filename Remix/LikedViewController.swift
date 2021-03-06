//
//  TestViewController.swift
//  Remix
//
//  Created by fong tinyik on 2/9/16.
//  Copyright © 2016 fong tinyik. All rights reserved.
//

import UIKit
import TTGSnackbar
class LikedViewController: CTFilteredViewController {

    var likedHeaderImage = UIImage(named: "LikedActivities")
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "我喜欢的活动"
    }
    
    override func configureRightBarButtonItem() {
        //Do nothing
    }
    
    override func setUpParallaxHeaderView() {
        let headerView = ParallaxHeaderView.parallaxHeaderViewWithImage(likedHeaderImage, forSize: CGSizeMake(UIScreen.mainScreen().bounds.width, 175)) as! ParallaxHeaderView
        self.tableView.tableHeaderView = headerView
        headerView.headerTitleLabel.text = "Liked Activities"
    }

    override func fetchCloudData() {
        coverImgURLs = []
        
        //    dates = []
        monthNameStrings = []
        activities = []
        
    
        
        var query = AVQuery(className: "Activity")
    
        fetchLikedActivitiesList()
        
      
        for likedActivityId in likedActivitiesIds {
            query.getObjectInBackgroundWithId(likedActivityId, block: { (activity, error) -> Void in
                if error == nil {
                    if activity != nil {
                        let coverImg = activity.objectForKey("CoverImg") as! AVFile
                        let imageURL = NSURL(string:coverImg.url)!
                        
                        let dateString = activity.objectForKey("Date") as! String
                        let monthName = dateString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[0] + " " + dateString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[2]
                        
                        if self.isMonthAdded(monthName) == false {
                            self.monthNameStrings.append(monthName)
                            self.activities.append([activity as AVObject])
                            self.coverImgURLs.append([imageURL])
                        } else {
                            
                            if let index = self.activities.indexOf({
                                
                                ($0[0].objectForKey("Date") as! String).componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[0] + " " + dateString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())[2] == monthName})
                            {
                                self.activities[index].append(activity as AVObject)
                                self.coverImgURLs[index].append(imageURL)
                            }
                            
                        }
                        self.tableView.reloadData()
                    }
                }
               
                
            })
        }
        
        
    }
    
    
    //DZNEmptyDataSet
    
    override func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attrDic = [NSFontAttributeName: UIFont.systemFontOfSize(17)]
        return NSAttributedString(string: "\n\n\n\n\n\n\n\n\n\n\n\n你还没有❤过Remix的活动\n", attributes: attrDic)
    }
    
    override func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrDic = [NSFontAttributeName: UIFont.systemFontOfSize(15)]
        return NSAttributedString(string: "在活动详情页面中，为活动点赞后它将会出现在这里。", attributes: attrDic)
    }
    
    override func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let attrDic = [NSFontAttributeName: UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: FlatRed()]
        return NSAttributedString(string: "去逛逛", attributes: attrDic)
    }
    
    override func emptyDataSet(scrollView: UIScrollView!, didTapButton button: UIButton!) {
        self.navigationController?.popViewControllerAnimated(true)
        
    }

}
