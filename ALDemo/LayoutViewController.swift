//
//  LayoutViewController.swift
//  ALDemo
//
//  Created by 解 磊 on 2017/3/13.
//  Copyright © 2017年 AppLeg Corp. All rights reserved.
//

import UIKit

private let cellReuseIdentifier = "Cell"

protocol LayoutDataSource : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, locationForItemAt indexPath: IndexPath) -> CGPoint
}

class Layout: UICollectionViewLayout {
    override var collectionViewContentSize: CGSize {
        return self.collectionView!.bounds.size
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = [UICollectionViewLayoutAttributes]()
        for i in 0..<self.collectionView!.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: i, section: 0)
            if let layoutAttributes = self.layoutAttributesForItem(at: indexPath) {
                if layoutAttributes.frame.intersects(rect) {
                    attributes.append(layoutAttributes)
                }
            }
        }
        return attributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let dataSource = self.collectionView?.dataSource as? LayoutDataSource else { return nil }
        
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.center = dataSource.collectionView(self.collectionView!, locationForItemAt: indexPath)
        attributes.size = CGSize(width: 40, height: 40)
        return attributes
    }
}

class LayoutViewController: UIViewController, LayoutDataSource, UICollectionViewDelegate {
    private var layoutCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: Layout())
    private let itemCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let pageControl = UIPageControl()
    private let itemView = UILabel()
    
    private var topConstraints: (show: NSLayoutConstraint?, hide: NSLayoutConstraint?)
    private var bottomConstraints: (show: NSLayoutConstraint?, hide: NSLayoutConstraint?)
    
    private var itemMap = [Int: (id: Int, title: String, color: UIColor, point: CGPoint?)]()
    private var itemIds = [Int]()
    private var layoutItemIds = [Int]()
    private var movingItemId: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for i in 0..<16 {
            self.itemMap[i] = (i, "\(i)", UIColor(argb: 0xff<<24|UInt32(randomInRange(0..<1<<24))), nil)
            self.itemIds.append(i)
        }
        
        self.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(actionFromPanPressGestureRecognizer(_:))))
        
        self.layoutCollectionView.delegate = self
        self.layoutCollectionView.dataSource = self
        self.layoutCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        self.layoutCollectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.layoutCollectionView)
        self.layoutCollectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.layoutCollectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.layoutCollectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.layoutCollectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        let imageView = UIImageView(image: UIImage(named: "background"))
        imageView.contentMode = .scaleAspectFill
        self.layoutCollectionView.backgroundView = imageView
        
        self.layoutCollectionView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(actionFromLongPressGestureRecognizer(_:))))
        self.layoutCollectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionFromTapGestureRecognizer(_:))))
        
        let color = UIColor(white: 1, alpha: 0.7)
        let topLabel = UILabel()
        topLabel.text = "Change Background"
        topLabel.textAlignment = .center
        topLabel.backgroundColor = color
        topLabel.layer.cornerRadius = 10
        topLabel.clipsToBounds = true
        topLabel.font = UIFont.systemFont(ofSize: 20)
        let pictureButton = UIButton(type: .system)
        pictureButton.setImage(#imageLiteral(resourceName: "picture"), for: .normal)
        pictureButton.backgroundColor = color
        pictureButton.layer.cornerRadius = 10
        let cameraButton = UIButton(type: .system)
        cameraButton.setImage(#imageLiteral(resourceName: "camera"), for: .normal)
        cameraButton.backgroundColor = color
        cameraButton.layer.cornerRadius = 10
        let buttonStackView = UIStackView(arrangedSubviews: [pictureButton, cameraButton])
        buttonStackView.distribution = .fillEqually
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 5
        let topStackView = UIStackView(arrangedSubviews: [topLabel, buttonStackView])
        topStackView.axis = .vertical
        topStackView.spacing = 5
        topStackView.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        topStackView.isLayoutMarginsRelativeArrangement = true
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(topStackView)
        self.topConstraints.show = topStackView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor)
        self.topConstraints.hide = topStackView.bottomAnchor.constraint(equalTo: self.view.topAnchor)
        self.topConstraints.hide?.isActive = true
        topStackView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        topStackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        let bottomView = UIView()
        bottomView.backgroundColor = color
        bottomView.layer.cornerRadius = 10
        bottomView.clipsToBounds = true
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bottomView)
        self.bottomConstraints.show = bottomView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor, constant: -5)
        self.bottomConstraints.hide = bottomView.topAnchor.constraint(equalTo: self.view.bottomAnchor)
        self.bottomConstraints.hide?.isActive = true
        bottomView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1, constant: -10).isActive = true
        bottomView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        let bottomLabel = UILabel()
        bottomLabel.text = "Select Items"
        bottomLabel.textAlignment = .center
        bottomLabel.font = UIFont.systemFont(ofSize: 20)
        
        self.itemCollectionView.delegate = self
        let screenwidth = UIScreen.main.bounds.width
        let itemSize = (screenwidth - 40) / 5
        let height = itemSize * 2 + 15
        self.itemCollectionView.backgroundColor = UIColor.clear
        self.itemCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        self.itemCollectionView.isPagingEnabled = true
        self.itemCollectionView.showsHorizontalScrollIndicator = false
        let layout = self.itemCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        self.itemCollectionView.translatesAutoresizingMaskIntoConstraints = false
        self.itemCollectionView.heightAnchor.constraint(equalToConstant: height).isActive = true
        self.itemCollectionView.dataSource = self
        self.itemCollectionView.delegate = self
        
        self.pageControl.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        let bottomStackView = UIStackView(arrangedSubviews: [bottomLabel, self.itemCollectionView, self.pageControl])
        bottomStackView.axis = .vertical
        bottomStackView.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        bottomStackView.isLayoutMarginsRelativeArrangement = true
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(bottomStackView)
        bottomStackView.topAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
        bottomStackView.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor).isActive = true
        bottomStackView.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor).isActive = true
        bottomStackView.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor).isActive = true
        
        self.itemView.textAlignment = .center
        self.itemView.alpha = 0.7
        self.itemView.frame = CGRect(x: 0, y: 0, width: itemSize, height: itemSize)
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.isEditing
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if self.itemCollectionView.indexPathForItem(at: touch.location(in: self.itemCollectionView)) == nil {
            return false
        } else {
            return true
        }
    }
    
    func actionFromTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        switch sender.state {
        case .ended:
            self.isEditing = false
            self.topConstraints.show?.isActive = false
            self.topConstraints.hide?.isActive = true
            self.bottomConstraints.show?.isActive = false
            self.bottomConstraints.hide?.isActive = true
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                self.setNeedsStatusBarAppearanceUpdate()
            }
        default:
            break
        }
    }
    
    func actionFromLongPressGestureRecognizer(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            self.isEditing = true
            self.topConstraints.hide?.isActive = false
            self.topConstraints.show?.isActive = true
            self.bottomConstraints.hide?.isActive = false
            self.bottomConstraints.show?.isActive = true
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                self.setNeedsStatusBarAppearanceUpdate()
            }
        default: break
        }
    }
    
    func actionFromPanPressGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            if self.isEditing,
                let indexPath = self.layoutCollectionView.indexPathForItem(at: sender.location(in: self.layoutCollectionView)),
                let cell = self.layoutCollectionView.cellForItem(at: indexPath),
                let item = self.itemMap[self.layoutItemIds[indexPath.item]] {
                var anchorPoint = sender.location(in: cell.contentView)
                anchorPoint.x /= cell.contentView.bounds.width
                anchorPoint.y /= cell.contentView.bounds.height
                self.itemView.layer.anchorPoint = anchorPoint
                self.itemView.center = sender.location(in: self.view)
                self.itemView.backgroundColor = item.color
                self.itemView.text = item.title
                self.view.addSubview(self.itemView)
                
                self.movingItemId = item.id
                
                self.layoutCollectionView.reloadData()
            } else if let indexPath = self.itemCollectionView.indexPathForItem(at: sender.location(in: self.itemCollectionView)),
                let cell = self.itemCollectionView.cellForItem(at: indexPath),
                let item = self.itemMap[self.itemIds[indexPath.item]] {
                var anchorPoint = sender.location(in: cell.contentView)
                anchorPoint.x /= cell.contentView.bounds.width
                anchorPoint.y /= cell.contentView.bounds.height
                self.itemView.layer.anchorPoint = anchorPoint
                self.itemView.center = sender.location(in: self.view)
                self.itemView.backgroundColor = item.color
                self.itemView.text = item.title
                self.view.addSubview(self.itemView)
                
                self.movingItemId = item.id
                
                self.itemCollectionView.reloadData()
            }
        case .changed:
            if let movingItemId = self.movingItemId {
                self.itemView.center = sender.location(in: self.view)
                
                let locationInLayout = sender.location(in: self.layoutCollectionView)
                let locationInItem = sender.location(in: self.itemCollectionView)
                if self.itemCollectionView.bounds.contains(locationInItem) {
                    let newIndexPath = self.itemCollectionView.indexPathForItem(at: locationInItem) ?? IndexPath(item: 0, section: 0)
                    
                    if let oldIndex = self.layoutItemIds.index(where: { $0 == movingItemId }) {
                        self.layoutItemIds.remove(at: oldIndex)
                        self.layoutCollectionView.performBatchUpdates({
                            self.layoutCollectionView.deleteItems(at: [IndexPath(item: oldIndex, section: 0)])
                        }, completion: { (_) in
                            self.layoutCollectionView.reloadData()
                        })
                        
                        self.itemIds.insert(movingItemId, at: newIndexPath.item)
                        self.itemCollectionView.performBatchUpdates({
                            self.itemCollectionView.insertItems(at: [newIndexPath])
                        }, completion: { (_) in
                            self.itemCollectionView.reloadData()
                        })
                    } else if let oldIndex = self.itemIds.index(where: { $0 == movingItemId }) {
                        self.itemIds.remove(at: oldIndex)
                        self.itemIds.insert(movingItemId, at: newIndexPath.item)
                        
                        self.itemCollectionView.performBatchUpdates({
                            self.itemCollectionView.moveItem(at: IndexPath(item: oldIndex, section: 0), to: newIndexPath)
                        }, completion: { (_) in
                            self.itemCollectionView.reloadData()
                        })
                    }
                } else {
                    if var item = self.itemMap[movingItemId] {
                        item.point = locationInLayout
                        self.itemMap[item.id] = item
                    }
                    
                    if let oldIndex = self.itemIds.index(where: { $0 == movingItemId }) {
                        self.itemIds.remove(at: oldIndex)
                        
                        self.itemCollectionView.performBatchUpdates({
                            self.itemCollectionView.deleteItems(at: [IndexPath(item: oldIndex, section: 0)])
                        }, completion: { (_) in
                            self.itemCollectionView.reloadData()
                        })
                        
                        self.layoutItemIds.insert(movingItemId, at: 0)
                        self.layoutCollectionView.performBatchUpdates({
                            self.layoutCollectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
                        }, completion: { (_) in
                            self.layoutCollectionView.reloadData()
                        })
                    } else {
                        self.layoutCollectionView.reloadData()
                    }
                }
                
                
//                if self.itemCollectionView.bounds.contains(newPoint) {
//                    if let oldIndex = self.layoutItemIds.index(where: { $0 == movingItemId }) {
//                        let item = self.layoutItemIds.remove(at: oldIndex)
//                        
//                        self.layoutCollectionView.performBatchUpdates({ 
//                            self.layoutCollectionView.deleteItems(at: [IndexPath(item: oldIndex, section: 0)])
//                        }, completion: { (_) in
//                            self.layoutCollectionView.reloadData()
//                        })
//                        
//                        
//                        
//                    }
//                    
//                    if let newIndexPath = self.itemCollectionView.indexPathForItem(at: newPoint) {
//                        if let oldIndex = self.itemIds.index(where: { $0 == movingItemId }) {
//                            let item = self.itemIds.remove(at: oldIndex)
//                            self.itemIds.insert(item, at: newIndexPath.item)
//                            
//                            self.itemCollectionView.performBatchUpdates({
//                                self.itemCollectionView.moveItem(at: IndexPath(item: oldIndex, section: 0), to: newIndexPath)
//                            }, completion: { (_) in
//                                self.itemCollectionView.reloadData()
//                            })
//                        } else {
//                            self.itemIds.insert(movingItemId, at: newIndexPath.item)
//                            
//                            self.itemCollectionView.performBatchUpdates({ 
//                                self.itemCollectionView.insertItems(at: [newIndexPath])
//                            }, completion: { (_) in
//                                self.itemCollectionView.reloadData()
//                            })
//                        }
//                    }
//                } else if let oldIndex = self.itemIds.index(where: { $0 == movingItemId }) {
//                    self.itemIds.remove(at: oldIndex)
//                    
//                    self.itemCollectionView.performBatchUpdates({
//                        self.itemCollectionView.deleteItems(at: [IndexPath(item: oldIndex, section: 0)])
//                    }, completion: { (_) in
//                        self.itemCollectionView.reloadData()
//                    })
//                }
            }
        case .ended:
            if self.movingItemId != nil {
                self.itemView.removeFromSuperview()
                self.movingItemId = nil
                self.layoutCollectionView.reloadData()
                self.itemCollectionView.reloadData()
            }
        default:
            break
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let itemIds: [Int]
        switch collectionView {
        case self.layoutCollectionView:
            itemIds = self.layoutItemIds
        case self.itemCollectionView:
            itemIds = self.itemIds
            self.pageControl.numberOfPages = Int((CGFloat(itemIds.count) / 10).rounded(.up))
        default:
            fatalError()
        }
        
        return itemIds.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        
        let itemIds: [Int]
        switch collectionView {
        case self.layoutCollectionView:
            itemIds = self.layoutItemIds
        case self.itemCollectionView:
            itemIds = self.itemIds
        default:
            fatalError()
        }
        
        if let item = self.itemMap[itemIds[indexPath.item]] {
            cell.isHidden = item.id == self.movingItemId
            
            let label: UILabel
            if cell.contentView.subviews.isEmpty {
                label = UILabel()
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(label)
                label.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
                label.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
                label.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor).isActive = true
                label.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor).isActive = true
            } else {
                label = cell.contentView.subviews.first as! UILabel
            }
            label.backgroundColor = item.color
            label.text = item.title
        }
        
//        // Configure the cell
//        switch collectionView {
//        case self.layoutCollectionView:
//            
//        case self.itemCollectionView:
//            if let item = self.itemMap[itemIds[indexPath.item]] {
//                cell.isHidden = item.id == self.movingItemId
//                
//                let label: UILabel
//                if cell.contentView.subviews.isEmpty {
//                    label = UILabel()
//                    label.textAlignment = .center
//                    label.translatesAutoresizingMaskIntoConstraints = false
//                    cell.contentView.addSubview(label)
//                    label.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
//                    label.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
//                    label.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor).isActive = true
//                    label.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor).isActive = true
//                } else {
//                    label = cell.contentView.subviews.first as! UILabel
//                }
//                label.backgroundColor = item.color
//                label.text = item.title
//            }
//        default:
//            break
//        }
    
        return cell
    }
    
    // MARK: LayoutDataSource
    
    func collectionView(_ collectionView: UICollectionView, locationForItemAt indexPath: IndexPath) -> CGPoint {
        return self.itemMap[self.layoutItemIds[indexPath.item]]!.point!
    }

    // MARK: UICollectionViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === self.itemCollectionView {
            self.pageControl.currentPage = Int(scrollView.contentOffset.x / scrollView.bounds.width + 0.5)
        }
    }
}
