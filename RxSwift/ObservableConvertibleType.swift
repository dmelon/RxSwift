//
//  ObservableConvertibleType.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 9/17/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Type that can be converted to observable sequence (`Observable<E>`).
public protocol ObservableConvertibleType {
    /// Type of elements in sequence.
    associatedtype E

    /// Converts `self` to `Observable` sequence.
    ///
    /// - returns: Observable sequence that represents `self`.
    func asObservable() -> Observable<E>
}

///: Observable <- ObservableType <- ObservableConvertibleType 线的基础协议。
///: ObservableConvertibleType 协议规定了实例必须可以转换为 Observable 类型。而 Observable 实际又服从 ObservableConvertibleType 协议，这是循环依赖的关系。
