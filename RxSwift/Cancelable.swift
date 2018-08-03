//
//  Cancelable.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 3/12/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Represents disposable resource with state tracking.
public protocol Cancelable : Disposable {
    /// Was resource disposed.
    var isDisposed: Bool { get }
}
///: 继承自 Disposable，但有一个状态位表示该 Disposable 是否已经被 disposed
