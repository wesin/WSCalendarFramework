//
//  CalendarView.swift
//  CALayerDemo
//
//  Created by 何文新 on 15/4/13.
//  Copyright (c) 2015年 hupun. All rights reserved.
//

import UIKit

public protocol WSCalendarViewDelegate:class {
    func WSCalendarDidSelectDate(calendar:WSCalendarView, date:NSDate)
}

public enum CalendarType {
    case Day
    case Month
    case Year
}

var beginDate:NSDate = NSDate(timeIntervalSince1970: 0)
var endDate:NSDate = beginDate.dateByAddingYears(100)
var curSelectDate:NSDate? = NSDate()
var curSelectMonth:NSDate? = NSDate()
var curSelectYear:NSDate? = NSDate()

public class WSCalendarView: UIView,UICollectionViewDataSource,UICollectionViewDelegate,WSCalendarItemDelegate {
    
    public weak var delegate:WSCalendarViewDelegate?
    
    private let dayCount = 42
    var monthHorCount:Int = 4
    var monthVerCount:Int = 3
    private var showMode:CalendarType = .Day
    
    private var collectView:UICollectionView?
    
    public var yearPerCount:Int = 4
    public var getCalendarMode:CalendarType = .Day {
        didSet{
            curSelectDate = NSDate()
            curSelectMonth = NSDate()
            curSelectYear = NSDate()
            switch getCalendarMode {
            case .Month:
                changeMode(.Month)
            case .Year:
                changeMode(.Year)
            default:
                changeMode(.Day)
            }
            
        }
    }
    

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    private var currentSection:Int {
        get {
            if let itemArray = collectView?.indexPathsForVisibleItems() as? [NSIndexPath] {
                if itemArray.count > 0 {
                return itemArray[0].section
                }
                return 0
            }
            return 0
        }
    }
    
    override public func drawRect(rect: CGRect) {
        //设置默认的时区
//        NSDate.setDefaultCalendarIdentifier(NSCalendarIdentifierChinese)
        var collectLayout = UICollectionViewFlowLayout()
        collectLayout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        collectLayout.minimumInteritemSpacing = 0
        collectLayout.minimumLineSpacing = 0
        collectLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectLayout.itemSize = rect.size
        
        collectView = UICollectionView(frame: rect, collectionViewLayout: collectLayout)
        self.addSubview(collectView!)
        collectView!.delegate = self
        collectView!.dataSource = self
        collectView!.pagingEnabled = true
        collectView!.showsHorizontalScrollIndicator = false
        collectView!.showsVerticalScrollIndicator = false
        collectView?.backgroundColor = UIColor.grayColor()
        
        collectView!.registerClass(WSCalendarItem.self, forCellWithReuseIdentifier: "calendarcell")
        var todayIndex = NSDate().monthsFrom(beginDate)
        collectView?.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: todayIndex), atScrollPosition: .CenteredHorizontally, animated: false)
        
        let date = NSDate(year: 1988, month: 11, day: 3)
        let extraInterval = NSTimeZone.systemTimeZone().secondsFromGMTForDate(date)
        let utcDate = date.dateByAddingSeconds(extraInterval)
//        scrollToDate(utcDate)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        println(beginDate.weekday())
        println(endDate.weekday())
    }
    
    
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        switch showMode {
        case .Day:
            return endDate.monthsFrom(beginDate)
        case .Month:
            return endDate.yearsFrom(beginDate)
        case .Year:
            return endDate.yearsFrom(beginDate) / (yearPerCount * yearPerCount)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("calendarcell", forIndexPath: indexPath) as? WSCalendarItem
        cell?.yearPerCount = yearPerCount
        cell?.dayType = showMode
//        println(beginDate)
        var currentDate = NSDate()
        switch showMode {
        case .Day:
            currentDate = beginDate.dateByAddingMonths(indexPath.section)
        case .Month:
            currentDate = beginDate.dateByAddingYears(indexPath.section)
        case .Year:
            currentDate = beginDate.dateByAddingYears(indexPath.section * yearPerCount * yearPerCount)
        }
        cell?.currentDate = currentDate
        cell?.delegate = self
        cell?.clearSelectDate()
        return cell!
    }
    
    
    //MARK:WSCalendarItemDelegate
    func scrollTo(isNext: Bool) {
        var newIndex:NSIndexPath?
        if isNext {
            if currentSection == collectView!.numberOfSections() - 1 {
                return
            }
            newIndex = NSIndexPath(forRow: 0, inSection: currentSection + 1)
        } else {
            if currentSection == 0 {
                return
            }
            newIndex = NSIndexPath(forRow: 0, inSection: currentSection - 1)
        }
        collectView?.scrollToItemAtIndexPath(newIndex!, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
    }
    
    /**
    按照目标mode，原mode，改变ui
    
    :param: destModeStr 目标mode
    :param: fromMode    <#fromMode description#>
    */
    func changeShowType(destModeStr:CalendarType, fromMode:CalendarType? = nil) {
        switch destModeStr {
        case .Month:
            if getCalendarMode == .Year {
                return
            }
            showMode = destModeStr
            var index = 0
            if fromMode == nil {
                index = curSelectYear!.yearsFrom(beginDate)
            } else {
                index = beginDate.dateByAddingMonths(currentSection).yearsFrom(beginDate)
            }
            collectView?.reloadData()

            collectView?.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: index), atScrollPosition: .CenteredHorizontally, animated: false)
            return
        case .Day:
            if getCalendarMode == .Month {
                return
            }
            showMode = destModeStr
            collectView?.reloadData()
            let index = curSelectMonth!.monthsFrom(beginDate)
            collectView?.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: index), atScrollPosition: .CenteredHorizontally, animated: false)
            return
        case .Year:
            showMode = destModeStr
            let index = Int(currentSection / (yearPerCount * yearPerCount))
            collectView?.reloadData()
            collectView?.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: index), atScrollPosition: .CenteredHorizontally, animated: false)
        default:
            return
        }

    }
    
    func changeMode(type: CalendarType?) {
        if type == nil {
            switch showMode {
            case .Year:
                changeShowType(CalendarType.Day, fromMode: .Year)
            case .Month:
                changeShowType(.Year, fromMode: .Month)
            case .Day:
                changeShowType(.Month, fromMode: .Day)
            }
        } else {
            changeShowType(type!, fromMode: nil)
        }
    }
    
    func didSelectItem(cellType:CalendarType) {
        if cellType == getCalendarMode {
            switch getCalendarMode {
            case .Day:
                delegate?.WSCalendarDidSelectDate(self, date: curSelectDate!)
            case .Month:
                delegate?.WSCalendarDidSelectDate(self, date: curSelectMonth!)
            case .Year:
                delegate?.WSCalendarDidSelectDate(self, date: curSelectYear!)
            }
        }
    }
    
    //MARK:PublicMethod
    
    /**
    定位到某天
    
    :param: date
    */
   public func scrollToDate(date:NSDate) {
        showMode = .Day
        let index = date.monthsFrom(beginDate)
        curSelectDate = date
        collectView?.reloadData()
        collectView?.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: index), atScrollPosition: .CenteredHorizontally, animated: false)
    }
    
    public var selectDate:NSDate? {
        get {
            return curSelectDate
        }
    }
    
    func reloadCalendar() {
        
        collectView?.reloadData()
    }
    
}
