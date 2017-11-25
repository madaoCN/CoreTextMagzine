//
//  CTSettings.swift
//  CoreTextMagazine
//
//  Created by 梁宪松 on 2017/11/25.
//  Copyright © 2017年 madao. All rights reserved.
//

import Foundation
import UIKit

class CTSettings {

    // MARK: - 属性
    let margin: CGFloat = 20 // 边距
    var columnsPerPage: CGFloat! // 每页列数
    var pageRect: CGRect! // 页面大小
    var columnRect: CGRect! // 列大小
    
    // MARK: - 初始化
    init() {
        // 如果是iphone 每页显示1列，否则每页两列
        columnsPerPage = UIDevice.current.userInterfaceIdiom == .phone ? 1 : 2
        // 页面frame 边距设置为 margin大小
        pageRect = UIScreen.main.bounds.insetBy(dx: margin, dy: margin)
        // 设置列的frame
        columnRect = CGRect(x: 0,
                            y: 0,
                            width: pageRect.width / columnsPerPage,
                            height: pageRect.height).insetBy(dx: margin, dy: margin)
    }
}
