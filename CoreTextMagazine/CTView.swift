//
//  CTView.swift
//  CoreTextMagazine
//
//  Created by 梁宪松 on 2017/11/21.
//  Copyright © 2017年 madao. All rights reserved.
//

import UIKit
import CoreText

class CTView: UIScrollView {

    var attrString: NSAttributedString!
    // MARK: - 图片下标
    var imageIndex: Int!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
//    func importAttrString(_ attrString: NSAttributedString) {
//        self.attrString = attrString
//    }
    
    func buildFrames(withAttrString attrString: NSAttributedString,
                     andImages images: [[String: Any]]) {
        // 初始化图片下标
        imageIndex = 0

        
        // 运行UIScrollview 整页进行翻动
        isPagingEnabled = true
        // CTFrameSetter 将创建每列对应的 CTFrame
        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        // 属性
        var pageView = UIView()
        var textPos = 0 //当前字符所在位置
        var columnIndex: CGFloat = 0 //当前列下标
        var pageIndex: CGFloat = 0 //当前页面下标
        let settings = CTSettings() //配置
        // 逐列遍历
        while textPos < attrString.length {
            // columnIndex %s ettings.columnsPerPage为零（truncatingRemainder：对浮点数取余），说明为页面第一列，需要新建一个页，并设置frame
            if columnIndex.truncatingRemainder(dividingBy: settings.columnsPerPage) == 0 {
                columnIndex = 0
                pageView = UIView(frame: settings.pageRect.offsetBy(dx: pageIndex * bounds.width, dy: 0))
                addSubview(pageView)
                // 页面索引自增
                pageIndex += 1
            }
            // 列宽度
            let columnXOrigin = pageView.frame.size.width / settings.columnsPerPage
            // 列偏移量
            let columnOffset = columnIndex * columnXOrigin
            // 计算列的frame
            let columnFrame = settings.columnRect.offsetBy(dx: columnOffset, dy: 0)
            
            // 创建位置路径，确定text分绘制范围
            let path = CGMutablePath()
            path.addRect(CGRect(origin: .zero, size: columnFrame.size))
            // 创建 CTFramesetter 用来创建 CTFrame
            let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, nil)
            // 创建列视图
            let column = CTColumnView(frame: columnFrame, ctframe: ctframe)
            if images.count > imageIndex {
                attachImagesWithFrame(images, ctframe: ctframe, margin: settings.margin, columnView: column)
            }
            pageView.addSubview(column)
            // 获取CTFrame 能容纳多少文本，从而更新textPos
            let frameRange = CTFrameGetVisibleStringRange(ctframe)
            textPos += frameRange.length
            // 列数指针自增
            columnIndex += 1
        }
        // 更新UIScrollview的contentSize
        contentSize = CGSize(width: CGFloat(pageIndex) * bounds.size.width,
                             height: bounds.size.height)
    }
    
    
    func attachImagesWithFrame(_ images: [[String: Any]],
                               ctframe: CTFrame,
                               margin: CGFloat,
                               columnView: CTColumnView) {
        // 获取ctframe 的`CTLine`数组
        let lines = CTFrameGetLines(ctframe) as NSArray
        // 使用CTFrameGetLineOrigins 将ctframe中的行origin 复制到数组 origins
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        // CFRangeMake(0, 0)代表转换整个CTFrame
        CTFrameGetLineOrigins(ctframe, CFRangeMake(0, 0), &origins)
        // 获取图片对象的location属性，如果没有值直接返回
        var nextImage = images[imageIndex]
        guard var imgLocation = nextImage["location"] as? Int else {
            return
        }
        // 遍历CTLine
        for lineIndex in 0..<lines.count {
            let line = lines[lineIndex] as! CTLine
            // 如果CTRun, 文件名，图片都存在
            if let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun],
                let imageFilename = nextImage["filename"] as? String,
                let img = UIImage(named: imageFilename)  {
                for run in glyphRuns {
                    // 如果当前CTRun的范围range没有包含nextImage，直接进入一下循环
                    let runRange = CTRunGetStringRange(run)
                    if runRange.location > imgLocation || runRange.location + runRange.length <= imgLocation {
                        continue
                    }
                    // 通过 CTRunGetTypographicBounds 计算图片的大小
                    var imgBounds: CGRect = .zero
                    var ascent: CGFloat = 0
                    imgBounds.size.width = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, nil, nil))
                    imgBounds.size.height = ascent
                    // 通过 CTLineGetOffsetForStringIndex 计算 CTLine x轴的偏移量，
                    let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
                    // 偏移量需要加上 imgBounds 的 origin
                    imgBounds.origin.x = origins[lineIndex].x + xOffset
                    imgBounds.origin.y = origins[lineIndex].y
                    // 将image 和 image绘制的位置 加入 columnView
                    columnView.images += [(image: img, frame: imgBounds)]
                    // 图片下标自增，更新imgLocation
                    imageIndex! += 1
                    if imageIndex < images.count {
                        nextImage = images[imageIndex]
                        imgLocation = (nextImage["location"] as AnyObject).intValue
                    }
                }
            }
        }
    }
    
//    override func draw(_ rect: CGRect) {
//
//        // 获取当前上下文
//        guard let context = UIGraphicsGetCurrentContext() else {
//            return;
//        }
//        //转换成uikit坐标系
//        context.textMatrix = .identity
//        context.translateBy(x: 0, y: rect.height)
//        context.scaleBy(x: 1, y: -1)
//        // 绘制区域路径
//        let path = CGMutablePath.init()
//        path.addRect(rect)
//        // 创建 CTFramesetter
//        let frameSetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
//        // 创建 CTFrame
//        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attrString.length), path, nil)
//        // 在指定上下文绘制CTFrame
//        CTFrameDraw(frame, context)
//    }
}
