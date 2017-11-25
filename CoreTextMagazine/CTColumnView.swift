//
//  CTColumnView.swift
//  CoreTextMagazine
//
//  Created by 梁宪松 on 2017/11/25.
//  Copyright © 2017年 madao. All rights reserved.
//

import UIKit

class CTColumnView: UIView {

    var ctFrame: CTFrame!
    var images: [(image: UIImage, frame: CGRect)] = []

    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    required init(frame: CGRect, ctframe: CTFrame) {
        super.init(frame: frame)
        self.ctFrame = ctframe
        backgroundColor = .white
    }
    
    // MARK: -
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // 转换成UIKit坐标系
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        // 在上下文中绘制 CTFrame
        CTFrameDraw(ctFrame, context)
        
        // 绘制图片
        for imageData in images {
            if let image = imageData.image.cgImage {
                let imgBounds = imageData.frame
                context.draw(image, in: imgBounds)
            }
        }
    }
}
