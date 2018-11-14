//
//  ObserverBase.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 2/15/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//
class ObserverBase<ElementType> : Disposable, ObserverType {
    typealias E = ElementType

    private var _isStopped: AtomicInt = 0

    func on(_ event: Event<E>) {
        switch event {
        case .next:
            if _isStopped == 0 {
                onCore(event)
            }
        case .error, .completed:
            ///: 如果 _isStopped == 0，则返回 true，同时将 _isStopped 置为 1。该操作是原子性的，会 block 读操作，相当于加锁。
            if AtomicCompareAndSwap(0, 1, &_isStopped) {
                onCore(event)
            }
        }
    }

    func onCore(_ event: Event<E>) {
        rxAbstractMethod()
    }

    func dispose() {
        _ = AtomicCompareAndSwap(0, 1, &_isStopped)
    }
}
