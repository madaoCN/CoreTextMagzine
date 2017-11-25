//
//  ViewController.swift
//  CoreTextMagazine
//
//  Created by 梁宪松 on 2017/11/21.
//  Copyright © 2017年 madao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.white
        let ctView = CTView()
        ctView.frame = view.frame
        view.addSubview(ctView)
        
        guard let file = Bundle.main.path(forResource: "zombies", ofType: "txt") else { return }
        
        do {
            let text = try String(contentsOfFile: file, encoding: .utf8)
            // 2
            let parser = MarkupParser()
            parser.parseMarkup(text)
//            ctView.importAttrString(parser.attrString)
            ctView.buildFrames(withAttrString: parser.attrString, andImages: parser.images)

        } catch _ {
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

