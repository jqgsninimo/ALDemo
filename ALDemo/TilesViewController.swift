//
//  TilesViewController.swift
//  MLCubeIOS
//
//  Created by 解 磊 on 16/1/27.
//  Copyright © 2016年 Mirror Life Corp. All rights reserved.
//

import UIKit
import AVFoundation

class TilesViewController: UICollectionViewController {
    
    /// 视图状态枚举类
    fileprivate enum State {
        /// 一般状态
        case normal
        /**
         移动状态，长按某设备单元格进入该状态，可调整设备位置
         
         - parameter index: 移动设备数据索引
         */
        case moving(index: Int)
        /**
         选中状态，点击某设备单元格进入该状态，在该单元格下方显示设备的控制画面
         
         - parameter index:       选中设备数据索引
         - parameter controlItem: 设备控制单元格索引
         */
        case selected(index: Int, controlItem: Int)
    }
    
    /// 视图转换ID枚举类
    fileprivate enum SegueId: String { case AlarmLog }
    
    /// 单元高度
    fileprivate let cellHeight = CGFloat(80)
    /// 单元间距
    fileprivate let cellSpace = CGFloat(8)
    /// 命令行高度
    fileprivate let rowHeight = CGFloat(45)
    /// 当前点
    fileprivate var currentPoint = CGPoint.zero
    /// 视图状态
    fileprivate var state = State.normal
    /// 繁忙状态，不处理用户操作
    private var busy = false
    
    /// 数据数组
    fileprivate var dataArray = [(id: Int, isDouble: Bool, rowCount: Int, color: UIColor)]()
    
    /// 选中设备索引
    fileprivate var selectedFaciltyIndex: Int? {
        let result: Int?
        if case let .selected(index, _) = self.state {
            result = index
        } else {
            result = nil
        }
        return result
    }
    
    /// 连接视图，连接选中设备视图与控制设备视图
    private var linkView = UIView()

    // MARK: - 继承自UICollectionViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置视图背景
        self.collectionView?.backgroundColor = UIColor.groupTableViewBackground
        // 不使用默认的长按调整位置功能，重新实现
        self.installsStandardGestureForInteractiveMovement = false
        self.collectionView?.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(actionFromLongPressGestureRecognizer(_:))))
        
        // 设置连接视图
        self.linkView.alpha = 0
        self.collectionView?.addSubview(self.linkView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        for id in 0..<100 {
            self.dataArray.append((id, randomInRange(0..<2) % 2 == 0, randomInRange(1..<6), UIColor(red: CGFloat(randomInRange(0..<256)) / CGFloat(255), green: CGFloat(randomInRange(0..<256)) / CGFloat(255), blue: CGFloat(randomInRange(0..<256)) / CGFloat(255), alpha: 1)))
        }
        
        self.collectionView?.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let number: Int
        switch self.state {
        case .normal, .moving:
            number = self.dataArray.count
        case .selected:
            number = self.dataArray.count + 1
        }
        return number
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        switch self.state {
        case .normal, .moving:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCell", for: indexPath)
            
            let data = self.dataArray[indexPath.item]
            let label = cell.contentView.subviews.first as! UILabel
            label.text = "\(data.id)(\(data.isDouble),\(data.rowCount))"
            label.backgroundColor = data.color
        case let .selected(index, controlItem):
            if controlItem == indexPath.item {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ControlCell", for: indexPath)
                
                let data = self.dataArray[index]
                let tableView = cell.contentView.subviews.first as! UITableView
                tableView.backgroundColor = data.color
                tableView.delegate = self
                tableView.dataSource = self
                tableView.reloadData()
            } else {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCell", for: indexPath)
                
                let index = indexPath.item > controlItem ? indexPath.item - 1 : indexPath.item
                let label = cell.contentView.subviews.first as! UILabel
                let data = self.dataArray[index]
                label.text = "\(data.id)(\(data.isDouble),\(data.rowCount))"
                label.backgroundColor = data.color
            }
        }
        
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let data = self.dataArray.remove(at: sourceIndexPath.item)
        self.dataArray.insert(data, at: destinationIndexPath.item)
        self.state = .moving(index: destinationIndexPath.item)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 闭包：将指定项目构建为IndexPath
        let path = { (item: Int) -> IndexPath in
            IndexPath(item: item, section: 0)
        }
        
        // 闭包：计算指定设备项目的控制项目
        let controlItemOfFacilityItem = { (facilityItem: Int) -> Int in
            // 获取设备项目布局属性
            let facilityLayoutAttributes = collectionView.layoutAttributesForItem(at: path(facilityItem))!
            // 计算控制项目索引
            // 控制项目将显示在设备项目的下一行，循环设备项目之后项目，找到首个下行项目的索引，即为控制项目的索引
            var controlItem = facilityItem + 1
            while controlItem < collectionView.numberOfItems(inSection: 0) {
                // 获得下个项目的布局属性
                guard let nextLayoutAttributes = collectionView.cellForItem(at: path(controlItem)) else { break }
                
                // 检查该项目是否位于下一行，如果是，即达成目标，退出循环
                if facilityLayoutAttributes.center.y + self.cellHeight / 2 < nextLayoutAttributes.center.y {
                    break
                }
                // 如果不是，设置控制项目索引为下一个项目的索引
                controlItem += 1
            }
            return controlItem
        }
        
        // 闭包：调整控制项
        let adjustControlItem = {
            guard case let .selected(_, controlItem) = self.state else { return }
            
            // 将控制项移动到可见区域
            if let controlLayoutAttributes = collectionView.layoutAttributesForItem(at: path(controlItem)) {
                collectionView.scrollRectToVisible(controlLayoutAttributes.frame, animated: true)
            }
        }
        
        // 闭包：调整连接视图
        let adjustLinkView = {
            UIView.animate(withDuration: 0.3, animations: {
                switch self.state {
                case let .selected(index, _):
                    if let facilityLayoutAttributes = collectionView.layoutAttributesForItem(at: path(index)) {
                        var linkFrame = CGRect.zero
                        linkFrame.origin.x = facilityLayoutAttributes.frame.origin.x
                        linkFrame.origin.y = facilityLayoutAttributes.frame.maxY
                        linkFrame.size.width = facilityLayoutAttributes.frame.width
                        linkFrame.size.height = self.cellSpace
                        self.linkView.frame = linkFrame
                        self.linkView.backgroundColor = self.dataArray[index].color
                        self.linkView.alpha = 1
                    }
                default:
                    self.linkView.alpha = 0
                }
            }) 
        }
        
        // 防止连续触发
        guard !self.busy else { return }
        // 设置为繁忙状态
        self.busy = true
        
        // 根据当前状态进行选择处理
        switch self.state {
        case .normal:
            // 一般状态，显示点击项的控制项
            collectionView.performBatchUpdates({
                // 显示控制项
                let controlItem = controlItemOfFacilityItem(indexPath.item)
                self.state = .selected(index: indexPath.item, controlItem: controlItem)
                collectionView.insertItems(at: [path(controlItem)])
                adjustLinkView()
            }) { (finished) in
                self.busy = false
                adjustControlItem()
            }
        case let .selected(index, controlItem) where indexPath.item != index && indexPath.item != controlItem:
            // 选中状态，点击项不为选中项，进行切换控制项处理
            // 计算新的控制项目
            let newControlItem = controlItemOfFacilityItem(indexPath.item)
            if newControlItem == controlItem {
                // 如果新的控制项在相同位置，只需更新控制项即可
                self.state = .selected(index: indexPath.item, controlItem: newControlItem)
                collectionView.performBatchUpdates({
                    // 更新控制项
                    collectionView.reloadItems(at: [path(newControlItem)])
                    adjustLinkView()
                }) { (finished) in
                    self.busy = false
                    adjustControlItem()
                }
            } else {
                // 如果新的控制项在其他位置，首先删除旧的控制项，再在新的位置添加控制项
                self.state = .normal
                collectionView.performBatchUpdates({
                    // 关闭当前控制项
                    collectionView.deleteItems(at: [path(controlItem)])
                }) { (finished) in
                    collectionView.performBatchUpdates({
                        // 当点击项在控制项之后，由于控制项刚被删除，需要对索引进行修正
                        let offset = indexPath.item > controlItem ? 1 : 0
                        // 显示控制项
                        self.state = .selected(index: indexPath.item - offset, controlItem: newControlItem - offset)
                        collectionView.insertItems(at: [path(newControlItem - offset)])
                        adjustLinkView()
                    }) { (finished) in
                        self.busy = false
                        adjustControlItem()
                    }
                }
            }
        case let .selected(index, controlItem) where indexPath.item == index:
            // 选中状态，点击项为选中项，取消选择
            self.state = .normal
            collectionView.performBatchUpdates({
                // 关闭控制项
                collectionView.deleteItems(at: [path(controlItem)])
                adjustLinkView()
            }) { (finished) in
                self.busy = false
            }
        default: break
        }
    }
    
    func actionFromLongPressGestureRecognizer(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let collectionView = self.collectionView else { return }
        
        switch gestureRecognizer.state {
        case .began:
            guard self.state == .normal else { return }
            guard var indexPath = collectionView.indexPathForItem(at: gestureRecognizer.location(in: collectionView)) else { return }
            
            self.state = .moving(index: indexPath.item)
            collectionView.beginInteractiveMovementForItem(at: indexPath)
            collectionView.setCollectionViewLayout(self.collectionViewLayout, animated: true)
            _ = delay(0.1) {
                if indexPath.item > 0 {
                    indexPath = IndexPath(item: indexPath.item - 1, section: 0)
                } else if indexPath.item < collectionView.numberOfItems(inSection: 0) - 1 {
                    indexPath = IndexPath(item: indexPath.item + 1, section: 0)
                }
                collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            }
            collectionView.updateInteractiveMovementTargetPosition(gestureRecognizer.location(in: collectionView))
        case .changed:
            guard self.state == State.moving else { return }
            collectionView.updateInteractiveMovementTargetPosition(gestureRecognizer.location(in: collectionView))
        case .ended:
            fallthrough
        default:
            guard self.state == State.moving else { return }
            
            collectionView.endInteractiveMovement()
            collectionView.setCollectionViewLayout(self.collectionViewLayout, animated: true)
            _ = delay(0.1) {
                switch self.state {
                case let .moving(item):
                    collectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: .centeredVertically, animated: false)
                default: break
                }
            }
            
            collectionView.performBatchUpdates({ () -> Void in
                collectionView.reloadData()
                }, completion: nil)
            self.state = .normal
        }
    }
}

// MARK: - 继承自UICollectionViewDelegateFlowLayout
extension TilesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentSize = collectionView.bounds.insetBy(dx: self.cellSpace, dy: self.cellSpace).size
        
        let sizeForItemAtIndex = { (index: Int) -> CGSize in
            var currentSize: CGSize
            if index == self.dataArray.count - 1 {
                let width = contentSize.width - self.currentPoint.x
                currentSize = CGSize(width: width, height: self.cellHeight)
                self.currentPoint.x = 0
                self.currentPoint.y += currentSize.height + self.cellSpace
            } else {
                let singleWidth = (contentSize.width - self.cellSpace * 3) / 4
                let doubleWidth = self.state == State.moving ? singleWidth : singleWidth * 2 + self.cellSpace
                let currentData = self.dataArray[index]
                
                currentSize = CGSize(width: singleWidth, height: self.cellHeight)
                if currentData.isDouble {
                    currentSize.width = doubleWidth
                }
                
                self.currentPoint.x += currentSize.width + self.cellSpace
                let nextData = self.dataArray[index + 1]
                let nextWidth = nextData.isDouble ? doubleWidth : singleWidth
                if self.currentPoint.x + nextWidth > contentSize.width {
                    currentSize.width += contentSize.width - self.currentPoint.x + self.cellSpace
                    self.currentPoint.x = 0
                    self.currentPoint.y += self.cellHeight + self.cellSpace
                }
            }
            return currentSize
        }
        
        let currentSize: CGSize
        switch self.state {
        case .normal, .moving:
            currentSize = sizeForItemAtIndex(indexPath.item)
        case let .selected(index, controlItem):
            if controlItem == indexPath.item {
                let maxHeight = contentSize.height - self.cellHeight
                let selectedData = self.dataArray[index]
                let height = min(self.rowHeight * CGFloat(selectedData.rowCount), maxHeight)
                currentSize = CGSize(width: contentSize.width, height: height)
                self.currentPoint.x = 0
                self.currentPoint.y += currentSize.height + self.cellSpace
            } else if controlItem == indexPath.item + 1 {
                let width = contentSize.width - currentPoint.x
                currentSize = CGSize(width: width, height: self.cellHeight)
                self.currentPoint.x = 0
                self.currentPoint.y += currentSize.height + self.cellSpace
            } else {
                currentSize = sizeForItemAtIndex(indexPath.item > controlItem ? indexPath.item - 1 : indexPath.item)
            }
        }
        
        return currentSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: self.cellSpace, left: self.cellSpace, bottom: self.cellSpace, right: self.cellSpace)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.cellSpace
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.cellSpace
    }
}

// MARK: - 继承自UITableViewDelegate
extension TilesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.rowHeight
    }
}

// MARK: - 继承自UITableViewDataSource
extension TilesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.state {
        case let .selected(index, _):
            let data = self.dataArray[index]
            return data.rowCount
        default:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommandCell")!
        switch self.state {
        case .selected:
            cell.backgroundColor = UIColor.clear
            cell.textLabel?.text = "Command\(indexPath.row)"
        default: break
        }
        return cell
    }
}

// MARK: - 视图状态枚举运算符==重载
private func ==(left: TilesViewController.State, right: TilesViewController.State) -> Bool {
    switch (left, right) {
    case (.normal, .normal): return true
    case let (.moving(leftItem), .moving(rightItem)) where leftItem == rightItem: return true
    case let (.selected(leftItem, leftControlItem), .selected(rightItem, rightControlItem)) where leftItem == rightItem && leftControlItem == rightControlItem: return true
    default: return false
    }
}

private func ==(left: TilesViewController.State, rightFunction: (_ index: Int) -> TilesViewController.State) -> Bool {
    let right = rightFunction(0)
    switch (left, right) {
    case (.moving, .moving): return true
    default: return false
    }
}

private func ==(left: TilesViewController.State, rightFunction: (_ index: Int, _ controlItem: Int) -> TilesViewController.State) -> Bool {
    let right = rightFunction(0, 0)
    switch (left, right) {
    case (.selected, .selected): return true
    default: return false
    }
}
