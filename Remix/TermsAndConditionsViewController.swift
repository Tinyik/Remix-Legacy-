//
//  TermsAndConditionsViewController.swift
//  Remix
//
//  Created by fong tinyik on 2/21/16.
//  Copyright © 2016 fong tinyik. All rights reserved.
//

import UIKit

class TermsAndConditionsViewController: UIViewController {

     weak var modalDelegate: ModalViewControllerDelegate?
    
    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let terms = "1、一切移动客户端用户在下载并浏览Remix软件时均被视为已经仔细阅读本条款并完全同意。凡以任何方式登陆本APP，或直接、间接使用Remix资料者，均被视为自愿接受本网站相关声明和用户服务协议的约束。\n2、Remix转载的内容并不代表Remix之意见及观点，也不意味着本网赞同其观点或证实其内容的真实性。\n3、Remix转载的文字、图片、音视频等资料均由本APP用户提供，其真实性、准确性和合法性由信息发布人负责。Remix不提供任何保证，并不承担任何法律责任。\n4、Remix所转载的文字、图片、音视频等资料，如果侵犯了第三方的知识产权或其他权利，责任由作者或转载者本人承担，本APP对此不承担责任。\n5、Remix不保证为向用户提供便利而设置的外部链接的准确性和完整性，同时，对于该外部链接指向的不由Remix实际控制的任何网页上的内容，Remix不承担任何责任。\n6、用户明确并同意其使用Remix网络服务所存在的风险将完全由其本人承担；因其使用Remix网络服务而产生的一切后果也由其本人承担，Remix对此不承担任何责任。\n7、除Remix注明之服务条款外，其它因不当使用本APP而导致的任何意外、疏忽、合约毁坏、诽谤、版权或其他知识产权侵犯及其所造成的任何损失，Remix概不负责，亦不承担任何法律责任。\n8、对于因不可抗力或因黑客攻击、通讯线路中断等Remix不能控制的原因造成的网络服务中断或其他缺陷，导致用户不能正常使用Remix，Remix不承担任何责任，但将尽力减少因此给用户造成的损失或影响。\n9、本声明未涉及的问题请参见国家有关法律法规，当本声明与国家有关法律法规冲突时，以国家法律法规为准。\n10、本移动应用相关声明版权及其修改权、更新权和最终解释权均属Remix所有。\n\n\nRemix 2016 Tianyi Fang\nAll Rights Reserved"
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 7
        let attribute = [NSParagraphStyleAttributeName: paragraphStyle]
        self.textView.attributedText = NSAttributedString(string: terms, attributes: attribute)
        self.textView.font = UIFont.systemFontOfSize(17)
        self.textView.textColor = .grayColor()
        self.textView.selectable = false
        self.textView.editable = false
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        textView.layoutIfNeeded()
        textView.setContentOffset(CGPointZero, animated: false)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    

  
}
