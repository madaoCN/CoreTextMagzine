//
//  MarkupParser.swift
//  CoreTextMagazine
//
//  Created by 梁宪松 on 2017/11/23.
//  Copyright © 2017年 madao. All rights reserved.
//

import UIKit

class MarkupParser: NSObject {

    // MARK: - 属性
    var color: UIColor = .black
    var fontName: String = "Arial"
    var attrString: NSMutableAttributedString!
    var images: [[String: Any]] = []
    
    // MARK: - 初始化方法
    override init() {
        super.init()
    }
    
    // MARK: - 内部方法
    func parseMarkup(_ markup: String) {
        // 初始化attrString
        attrString = NSMutableAttributedString(string: "")
        // 解析
        do {
            // 正则匹配所有标签块 例如：<img src="zombie1.jpg" width="320" height="882">
            let regex = try NSRegularExpression.init(pattern: "(.*?)(<[^>]+>|\\Z)", options: NSRegularExpression.Options.dotMatchesLineSeparators)
            let chunks = regex.matches(in: markup, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSRange.init(location: 0, length: markup.count))
            
            // 设定默认字体
            let defaultFont: UIFont = .systemFont(ofSize: UIScreen.main.bounds.size.height / 40)
            // 遍历匹配结果
            for chunk in chunks {
                // 获取当前匹配结果 NSTextCheckingResult 在原文本中的范围
                guard let markupRange = markup.range(from: chunk.range) else { continue }
                // 以符号 "<" 分割句子
                let parts = markup[markupRange].components(separatedBy: "<")
                // 从 fontName 属性（Arial）创建字体, 若无该字体，则使用默认字体 defaultFont
                let font = UIFont(name: fontName, size: UIScreen.main.bounds.size.height / 40) ?? defaultFont
                // 为 NSAttributedString 创建 字体颜色和字体 属性
                let attrs = [NSAttributedStringKey.foregroundColor: color, NSAttributedStringKey.font: font] as [NSAttributedStringKey : Any]
                // 将属性 应用于 parts[0]
                let text = NSMutableAttributedString(string: parts[0], attributes: attrs)
                attrString.append(text)
                
                // 如果分割后的模式数组长度小于等于1，则略过 说明不带有形如 <> 的匹配
                if parts.count <= 1 {
                    continue
                }
                let tag = parts[1]
                // 如果 parts[1] ( < 之后的文本，也就是标签名) 是 font
                if tag.hasPrefix("font") {
                    // 匹配颜色属性
                    let colorRegex = try NSRegularExpression(pattern: "(?<=color=\")\\w+",
                                                             options: NSRegularExpression.Options(rawValue: 0))
                    colorRegex.enumerateMatches(in: tag,
                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                range: NSMakeRange(0, tag.characters.count)) {
                            (match, _, _) in
                            // 利用 NSObject perform 方法对 color 属性 赋值获取到的颜色
                            if let match = match,
                                let range = tag.range(from: match.range) {
                                let colorSel = NSSelectorFromString(tag[range]+"Color")
                                color = UIColor.perform(colorSel).takeRetainedValue() as? UIColor ?? .black
                            }
                    }
                    // 正则匹配 face 字体属性
                    let faceRegex = try NSRegularExpression(pattern: "(?<=face=\")[^\"]+",
                                                            options: NSRegularExpression.Options(rawValue: 0))
                    faceRegex.enumerateMatches(in: tag,
                                               options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                               range: NSMakeRange(0, tag.characters.count)) { (match, _, _) in
                                                
                            if let match = match,
                                let range = tag.range(from: match.range) {
                                fontName = String(tag[range])
                            }
                    }
                } //end of font parsing
                
                // 解析 img 标签
                else if tag.hasPrefix("img") {
                    // 正则匹配 src 内容
                    var filename:String = ""
                    let imageRegex = try NSRegularExpression(pattern: "(?<=src=\")[^\"]+",
                                                             options: NSRegularExpression.Options(rawValue: 0))
                    imageRegex.enumerateMatches(in: tag,
                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                range: NSMakeRange(0, tag.characters.count)) {
                            (match, _, _) in
                            
                            if let match = match,
                                let range = tag.range(from: match.range) {
                                filename = String(tag[range])
                            }
                    }
                    // 将图片的宽度设置为 列的宽度
                    let settings = CTSettings()
                    var width: CGFloat = settings.columnRect.width
                    var height: CGFloat = 0
                    
                    if let image = UIImage(named: filename) {
                        height = width * (image.size.height / image.size.width)
                        // 图片高度若超出列，对图片进行等比例缩放
                        if height > settings.columnRect.height - font.lineHeight {
                            height = settings.columnRect.height - font.lineHeight
                            width = height * (image.size.width / image.size.height)
                        }
                    }
                    
                    // image 数组 添加 图片属性字典
                    images += [["width": NSNumber(value: Float(width)),
                                "height": NSNumber(value: Float(height)),
                                "filename": filename,
                                "location": NSNumber(value: attrString.length)]]
                    // 定义CTRun属性结构体
                    struct RunStruct {
                        let ascent: CGFloat
                        let descent: CGFloat
                        let width: CGFloat
                    }
                    // Memory指针 相当于RunStruct 结构体指针
                    let extentBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
                    extentBuffer.initialize(to: RunStruct(ascent: height, descent: 0, width: width))
                    //  创建CTRunDelegateCallbacks 控制占位
                    var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (pointer) in
                    }, getAscent: { (pointer) -> CGFloat in
                        let d = pointer.assumingMemoryBound(to: RunStruct.self)
                        return d.pointee.ascent
                    }, getDescent: { (pointer) -> CGFloat in
                        let d = pointer.assumingMemoryBound(to: RunStruct.self)
                        return d.pointee.descent
                    }, getWidth: { (pointer) -> CGFloat in
                        let d = pointer.assumingMemoryBound(to: RunStruct.self)
                        return d.pointee.width
                    })
                    // 创建绑定了回调的代理
                    let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
                    // 将代理封装至属性字典
                    let attrDictionaryDelegate = [(kCTRunDelegateAttributeName as NSAttributedStringKey): (delegate as Any)]
                    attrString.append(NSAttributedString(string: " ", attributes: attrDictionaryDelegate))
                }
            }
            
            
        } catch _ {
        }
    }
}

// MARK: - String （NSRange 转换成 Range）
extension String {
    func range(from range: NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex,
                                       offsetBy: range.location,
                                       limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: range.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) else {
                return nil
        }
        return from ..< to
    }
}
