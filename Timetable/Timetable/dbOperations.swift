//
//  dbOperations.swift
//  Timetable
//
//  Created by solar on 17/7/2.
//  Copyright © 2017年 PigVillageStudio. All rights reserved.
//

import Foundation
// 数据库操作
class dbOperations: NSObject {
    // 不透明指针，对应C语言里面的void *，这里指sqlite3指针
    private var db: OpaquePointer? = nil
    
    // 初始化方法打开数据库
    required init(dbPath: String) {
        print("dbPath:\(dbPath)")
        // String类的路径，转换成cString
        let cpath = dbPath.cString(using: String.Encoding.utf8)
        
        // 打开数据库
        let error = sqlite3_open(cpath!, &db)
        
        // 数据库打开失败处理
        if error != SQLITE_OK {
            print("失败打开数据库")
            sqlite3_close(db)
        }else {
            print("成功打开数据库")
        }
    }
    
    deinit {
        self.colseDB()
    }
    
    // MARK: - 将Bundle.main路径下的数据库文件复制到Documents下
    class func loadDBPath() -> String {
        // 声明一个Documents下的路径
        let dbPath = NSHomeDirectory() + "/Documents/Timetable.sqlite"
        // 判断数据库文件是否存在
        if !FileManager.default.fileExists(atPath: dbPath) {
            // 获取安装包内数据库路径
            let bundleDBPath = Bundle.main.path(forResource: "Timetable", ofType: "sqlite")!
            // 将安装包内数据库拷贝到Documents目录下
            do {
                try FileManager.default.copyItem(atPath: bundleDBPath, toPath: dbPath)
            } catch let error as NSError{
                print(error)
            }
        }
        return dbPath
    }
    
    // 关闭数据库
    func colseDB() {
        sqlite3_close(db)
    }
    
    // MARK: - 判断表是否存在
    func checkTable() -> Bool {
        // sql语句
        let sql = "SELECT COUNT(*) FROM sqlite_master where type='table' and name='CourseTable';"
        // 执行sql语句
        let executeResult = sqlite3_exec(db, sql.cString(using: String.Encoding.utf8), nil, nil, nil)
        // 判断是否执行成功
        if executeResult != SQLITE_OK {
            print("判断失败")
        }
        if executeResult == 1 {
            return true
        }else {
            return false
        }
    }
    
    // 代码创建表
    func createTable() -> Bool {
        print("建表ing")
        // sql语句
        let sql = "CREATE TABLE CourseTable(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, courseName TEXT NOT NULL, teacher TEXT NOT NULL, classroom TEXT NOT NULL, start INTEGER NOT NULL, end INTEGER NOT NULL, day INTEGER NOT NULL)"
        // 执行sql语句
        let executeResult = sqlite3_exec(db, sql.cString(using: String.Encoding.utf8), nil, nil, nil)
        // 判断是否执行成功
        if executeResult != SQLITE_OK {
            print("建表失败\(executeResult)")
            return false
        }
        print("建表成功")
        return true
    }
    
    // 插入一条信息
    func addCourse(course: Course) -> Bool {
        print("插入信息ing")
        // sql语句
        let sql = "INSERT INTO CourseTable (courseName, teacher, classroom, start, end, day) VALUES (?,?,?,?,?,?);"
        // sql语句转换成cString类型
        let csql = sql.cString(using: String.Encoding.utf8)
        // sqlite3_stmt 指针
        var stmt: OpaquePointer? = nil
        // 编译sql
        let prepareResult = sqlite3_prepare_v2(db, csql, -1, &stmt, nil)
        // 判断如果失败，获取失败信息
        if prepareResult != SQLITE_OK {
            sqlite3_finalize(stmt)
            if let error = sqlite3_errmsg(db) {
                let msg = "SQLiteDB - failed to prepare SQL: \(sql), Error: \(error)"
                print(msg)
            }
            return false
        }
        // 准备参数
        let cCourseName = course.courseName!.cString(using: String.Encoding.utf8)
        let cTeacher = course.teacher!.cString(using: String.Encoding.utf8)
        let cClassroom = course.classroom!.cString(using: String.Encoding.utf8)
        let cStart = Int32(Int(course.start!))
        let cEnd = Int32(Int(course.end!))
        let cDay = Int32(Int(course.day!))
        
        // 绑定參数
        sqlite3_bind_text(stmt, 1, cCourseName, -1, nil)
        sqlite3_bind_text(stmt, 2, cTeacher, -1, nil)
        sqlite3_bind_text(stmt, 3, cClassroom, -1, nil)
        sqlite3_bind_int(stmt, 4, cStart)
        sqlite3_bind_int(stmt, 5, cEnd)
        sqlite3_bind_int(stmt, 6, cDay)
        
        // 执行插入
        if sqlite3_step(stmt) != SQLITE_DONE {
            sqlite3_finalize(stmt)
            print("插入数据失败。")
            return false
        }
        // 释放语句对象
        sqlite3_finalize(stmt)
        // 关闭数据库
        sqlite3_close(db)
        print("插入数据成功")
        return true
    }
    
    // 查询所有课程
    func getAllCourse() -> [Course] {
        // 声明一个Course对象数组（查询的信息会添加到该数组）
        var courseArray = [Course]()
        
        // sql
        let sql = "SELECT * FROM CourseTable;"
        
        // sqlite3_stmt 指针
        var stmt: OpaquePointer? = nil
        
        // sql语句转换成cString类型
        let csql = sql.cString(using: String.Encoding.utf8)
        
        // 编译sql
        let prepareResult = sqlite3_prepare_v2(db, csql!, -1, &stmt, nil)
        if prepareResult != SQLITE_OK {
            sqlite3_finalize(stmt)
            if let error = sqlite3_errmsg(db) {
                let msg = "SQLiteDB - failed to prepare SQL: \(sql), Error: \(error)"
                print(msg)
            }
            return courseArray
        }
        
        // 查询
        while sqlite3_step(stmt) == SQLITE_ROW {
            let course = Course()
            // 循环从数据库获取数据并添加到数组中
            let cCourseName = UnsafePointer(sqlite3_column_text(stmt, 1))
            let cTeacher = UnsafePointer(sqlite3_column_text(stmt, 2))
            let cClassroom = UnsafePointer(sqlite3_column_text(stmt, 3))
            let cStart = sqlite3_column_int(stmt, 4)
            let cEnd = sqlite3_column_int(stmt, 5)
            let cDay = sqlite3_column_int(stmt, 6)
            course.courseName = String.init(cString: cCourseName!)
            course.teacher = String.init(cString: cTeacher!)
            course.classroom = String.init(cString: cClassroom!)
            course.start = Int(cStart)
            course.end = Int(cEnd)
            course.day = Int(cDay)
            
            courseArray.append(course)
        }
        
        sqlite3_finalize(stmt)
        
        return courseArray
    }
    
    // MARK: - 清空课表
    func cleanTable() -> Bool {
        print("清空课表ing")
        // sql
        let sql = "DELETE FROM CourseTable;"
        
        // sqlite3_stmt 指针
        var stmt: OpaquePointer? = nil
        
        // sql语句转换成cString类型
        let csql = sql.cString(using: String.Encoding.utf8)
        // 编译sql
        let prepareResult = sqlite3_prepare_v2(db, csql!, -1, &stmt, nil)
        if prepareResult != SQLITE_OK {
            sqlite3_finalize(stmt)
            if let error = sqlite3_errmsg(db) {
                let msg = "SQLiteDB - failed to prepare SQL: \(sql), Error: \(error)"
                print(msg)
            }
            print("清空失败")
            return false
        }
        // step执行
        let stepResult = sqlite3_step(stmt)
        // 判断执行结果，如果失败，获取失败信息
        if stepResult != SQLITE_OK && stepResult != SQLITE_DONE {
            sqlite3_finalize(stmt)
            if sqlite3_errmsg(stmt) != nil {
                let msg = "SQLiteDB - failed to execute SQL:\(sql)"
                print(msg)
            }
            return false
        }
        //
        sqlite3_finalize(stmt)
        print("清空成功")
        return true
    }
}
