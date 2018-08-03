//
//  BooleanDisposable.swift
//  RxSwift
//
//  Created by Junior B. on 10/29/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Represents a disposable resource that can be checked for disposal status.
public final class BooleanDisposable : Cancelable {

    internal static let BooleanDisposableTrue = BooleanDisposable(isDisposed: true)
    private var _isDisposed = false
    
    /// Initializes a new instance of the `BooleanDisposable` class
    public init() {
    }
    
    /// Initializes a new instance of the `BooleanDisposable` class with given value
    public init(isDisposed: Bool) {
        self._isDisposed = isDisposed
    }
    
    /// - returns: Was resource disposed.
    public var isDisposed: Bool {
        return _isDisposed
    }
    
    /// Sets the status to disposed, which can be observer through the `isDisposed` property.
    public func dispose() {
        _isDisposed = true
    }
}
///: 包含一个状态变量，可以查看是否已经调用过 dispose 方法。搜索全局，只用在了单元测试里了，不知道还有别的用处否？
