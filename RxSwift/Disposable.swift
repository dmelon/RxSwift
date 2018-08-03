//
//  Disposable.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Represents a disposable resource.
public protocol Disposable {
    /// Dispose resource.
    func dispose()
}
///: 可以被 dispose，即做一些资源销毁的操作。比如说，网路请求中 cancel request、Notification 中 remove observer
