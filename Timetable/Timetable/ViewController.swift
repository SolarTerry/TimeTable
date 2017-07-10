//
//  ViewController.swift
//  Timetable
//
//  Created by solar on 17/6/2.
//  Copyright © 2017年 PigVillageStudio. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    // MARK: - 时间collectionview（表头）
    @IBOutlet weak var dateCollectionView: UICollectionView!
    // MARK: - 课程collectionview（课程内容）
    @IBOutlet weak var courseCollectionView: UICollectionView!
    // MARK: - 表头tag
    let DATE_COLLECTION_VIEW_TAG = 0
    // MARK: - 课程内容
    let COURSE_COLLECTION_VIEW_TAG = 1
    // MARK: - 表头
    var weekItems = ["周一", "周二", "周三", "周四", "周五","周六","周日"]
    // MARK: - 图片view
    var imageView: UIImageView!
    // MARK: - 课程单元格大小
    var courseCellSize: CGSize!
    // MARK: - 课程单元格背景色
    var courseColor: UIColor!
    // MARK: - 课程数组
    var courseArray = [Course]()
    // MARK: - 课程label数组
    var courseLabelArray = [UILabel]()
    // MARK: - 背景图
    var bgImageView: UIImageView!
    // MARK: - 清空课表按钮
    var cleanButtonItem: UIBarButtonItem!
    // MARK: - 清空课表按钮tag
    let CLEAN_BUTTON_ITEM = 2
    // MARK: - 加载课程按钮
    var loadButtonItem: UIBarButtonItem!
    // MARK: - 加载课程按钮tag
    let LOAD_BUTTON_ITEM = 3
    // MARK: - 主storyboard
    var storyBoard = UIStoryboard(name: "Main", bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 背景图设置
        bgImageView = UIImageView(frame: self.view.frame)
        bgImageView.image = UIImage.init(named: "bg")
        self.view.insertSubview(bgImageView, belowSubview: dateCollectionView)
        // 设置课程单元格背景色
        courseColor = UIColor(red: 74/255, green: 187/255, blue: 230/255, alpha: 1)
        // 注册cell
        dateCollectionView.register(UINib(nibName: "DateCell", bundle: nil), forCellWithReuseIdentifier: "DateCell")
        courseCollectionView.register(UINib(nibName: "DateCell", bundle: nil), forCellWithReuseIdentifier: "DateCell")
        courseCollectionView.register(UINib(nibName: "CourseCell", bundle: nil), forCellWithReuseIdentifier: "CourseCell")
        // 设置tag
        dateCollectionView.tag = DATE_COLLECTION_VIEW_TAG
        courseCollectionView.tag = COURSE_COLLECTION_VIEW_TAG
        // 设置代理
        dateCollectionView.delegate = self
        dateCollectionView.dataSource = self
        courseCollectionView.delegate = self
        courseCollectionView.dataSource = self
        // 设置课程表透明度
        dateCollectionView.alpha = 0.5
        courseCollectionView.alpha = 0.5
        // 禁止滚动
        self.automaticallyAdjustsScrollViewInsets = false
        // 清空按钮
        cleanButtonItem = UIBarButtonItem(title: "清空课表", style: UIBarButtonItemStyle.plain, target: self, action: #selector(clearTable))
        // 加载按钮
        loadButtonItem = UIBarButtonItem(title: "加载课程", style: UIBarButtonItemStyle.plain, target: self, action: #selector(load))
        // 将按钮添加到导航栏
        self.navigationItem.leftBarButtonItem = loadButtonItem
        self.navigationItem.rightBarButtonItem = cleanButtonItem
        // 刷新数据
        courseCollectionView.reloadData()
        // 加载课程
        loadCourse()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 将课程label添加进view
        for courseItem in self.courseArray {
            drawCourse(courseItem)
        }
    }
    
    override func viewDidLayoutSubviews() {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - 绘画课程单元格
    func drawCourse(_ course: Course) {
        // 计算要画的地方
        let rowNum = course.end - course.start + 1
        let width = courseCellSize.width
        let height = courseCellSize.height * CGFloat(rowNum)
        let x = CGFloat(30) + CGFloat(course.day - 1) * courseCellSize.width
        let y = CGFloat(30 + 64) + CGFloat(course.start - 1) * courseCellSize.height
        let courseView = UIView(frame: CGRect(x: x, y: y, width: width, height: height))
        courseView.alpha = 0.8
        
        // 显示课程信息的label
        let courseInfoLabel = UILabel(frame: CGRect(x: 0, y: 2, width: courseView.frame.size.width - 2, height: courseView.frame.size.height))
        courseInfoLabel.numberOfLines = 5
        courseInfoLabel.font = UIFont.systemFont(ofSize: 12)
        courseInfoLabel.textAlignment = .left
        courseInfoLabel.textColor = UIColor.white
        courseInfoLabel.text = "\(course.courseName!)@\(course.classroom!)"
        courseInfoLabel.tag = self.courseArray.index(of: course)!
        courseInfoLabel.layer.cornerRadius = 5
        courseInfoLabel.layer.masksToBounds = true
        courseInfoLabel.backgroundColor = courseColor
        courseView.addSubview(courseInfoLabel)
        self.courseLabelArray.append(courseInfoLabel)
        
        // 点击显示课程详细信息手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(showCourseDetail(_:)))
        courseInfoLabel.addGestureRecognizer(tap)
        courseInfoLabel.isUserInteractionEnabled = true
        
        // 将要画的地方画上去
        self.view.insertSubview(courseView, aboveSubview: courseCollectionView)
    }
    
    // MARK: - 显示课程详细信息
    func showCourseDetail(_ recognizer: UIGestureRecognizer) {
        // 获取手势所在的label
        let label = recognizer.view as! UILabel
        let vc = storyBoard.instantiateViewController(withIdentifier: "details") as! DetailsViewController
        // 根据label的tag获取label上的Course对象
        vc.course = courseArray[label.tag]
        // 页面跳转
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - 删除课程信息
    func deleteCourse(_ course: Course, tag: Int) {
        // 获取课程所在view
        let courseView = self.courseLabelArray[tag].superview
        // 去除这个view
        courseView?.removeFromSuperview()
        self.courseArray.remove(at: tag)
        self.courseLabelArray.remove(at: tag)
    }
    
    // MARK: - 清空课表
    func clearTable() {
        // 获取数据库路径
        let path = dbOperations.loadDBPath()
        
        // 打开数据库
        let DBOperations = dbOperations(dbPath: path)
        
        // 判断是否存在Timetable表
        if DBOperations.checkTable() {
            // 如果不存在则返回
            print("不存在表")
            return
        }
        // 清空表
        _ = DBOperations.cleanTable()
        // 清除label
        for courseLabel in courseLabelArray {
            let courseView = courseLabel.superview
            courseView?.removeFromSuperview()
        }
        // 清空课程数组
        courseArray = []
        courseLabelArray = []
        // 刷新表格
        view.reloadInputViews()
    }
    
    // MARK: - 加载一节课
    func load() {
        // 模拟一节课
        let course = Course()
        course.courseName = "高等数学"
        course.teacher = "高数学"
        course.classroom = "数学楼A206"
        course.day = 1
        course.start = 7
        course.end = 8
        course.weeks = 17
        self.addCourse(course)
        // 重新加载课程
        loadCourse()
        for courseItem in self.courseArray {
            drawCourse(courseItem)
        }
        // 刷新表格
        view.reloadInputViews()
    }
    
    // MARK: - 添加课程信息
    func addCourse(_ course: Course) {
        
        // 将课程追加到数组
        courseArray.append(course)
        
        // 获取数据库路径
        let path = dbOperations.loadDBPath()
        
        // 打开数据库
        let DBOperations = dbOperations(dbPath: path)
        
        // 判断是否存在Timetable表
        if DBOperations.checkTable() {
            // 如果不存在则新建表
            _ = DBOperations.createTable()
        }
        
        // 插入课程
        _ = DBOperations.addCourse(course: course)
    }
    
    // MARK: - 加载课程信息
    func loadCourse() {
        // 获取数据库路径
        let path = dbOperations.loadDBPath()
        
        // 打开数据库
        let DBOperations = dbOperations(dbPath: path)
        
        // 判断是否存在Timetable表
        if DBOperations.checkTable() {
            // 如果不存在则新建表
            _ = DBOperations.createTable()
        }
        courseArray = DBOperations.getAllCourse()
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch collectionView.tag {
        case DATE_COLLECTION_VIEW_TAG:
            return 1
        case COURSE_COLLECTION_VIEW_TAG:
            return 1
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView.tag {
        case DATE_COLLECTION_VIEW_TAG:
            return weekItems.count + 1
        case COURSE_COLLECTION_VIEW_TAG:
            return (weekItems.count + 1) * 12
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView.tag {
        case DATE_COLLECTION_VIEW_TAG:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCell", for: indexPath) as! DateCell
            if indexPath.row == 0 {
                cell.dateLabel.text = ""
            }else {
                cell.dateLabel.text = weekItems[indexPath.row - 1]
            }
            return cell
        case COURSE_COLLECTION_VIEW_TAG:
            if indexPath.row % 8 == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCell", for: indexPath) as! DateCell
                cell.dateLabel.text = "\(indexPath.row / (weekItems.count + 1) + 1)"
                return cell
            }else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseCell", for: indexPath) as! CourseCell
                cell.courseLabel.text = ""
                return cell
            }
        default:
            return UICollectionViewCell()
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView.tag {
        case DATE_COLLECTION_VIEW_TAG:
            if indexPath.row == 0 {
                return CGSize(width: 30, height: 30)
            }else {
                return CGSize(width: (SCREEN_WIDTH - 30) / 7, height: 30)
            }
        case COURSE_COLLECTION_VIEW_TAG:
            let rowHeight = CGFloat((SCREEN_HEIGHT - 64 - 30) / 12)
            if indexPath.row % 8 == 0 {
                return CGSize(width: 30, height: rowHeight)
            }else {
                courseCellSize = CGSize(width: (SCREEN_WIDTH - 30) / 7, height: rowHeight)
                return courseCellSize
            }
        default:
            return CGSize(width: 0, height: 0)
        }
    }
}

