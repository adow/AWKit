//
//  TestViewController.swift
//  AWHttpRequest
//
//  Created by 秦 道平 on 16/5/13.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView : UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //        let url = NSURL(string: "http://www.codingnext.com")!
//        let url = NSURL(string: "http://www.google.com")!
//        let url = NSURL(string: "https://images.unsplash.com/photo-1439736637365-748f240b24fb?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&s=f18043849f8c96c566ba85b07cf0e521")!
        let url = NSURL(string: "http://img.wifiwx.com/material/video_split/img/710x236/2016/05/05b33aa5eb85ec31674a7e756abcd246.png")!
//        let configuration = AWHttpConfiguration(name: "test")
//        configuration.sessionConfiguration.timeoutIntervalForRequest = 3.0
//        AWHttpRequest.get(url)
//            .responseString({ [weak self](str) in
//                self?.textView.text = str
//                }) { (error) in
//                    NSLog("error:%@", error)
//        }
        
        self.imageView.aw_downloadImageURL_loading(url, showLoading: true) { (_, _) in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    deinit {
        NSLog("dealloc")
    }
    
    @IBAction func onButtonCancel(sender:UIButton!) {
        self.dismissViewControllerAnimated(true) { 
            
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
