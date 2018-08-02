//
//  ObservableType.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 8/8/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Represents a push style sequence.
public protocol ObservableType : ObservableConvertibleType {
    /**
    Subscribes `observer` to receive events for this sequence.
    
    ### Grammar
    
    **Next\* (Error | Completed)?**
    
    * sequences can produce zero or more elements so zero or more `Next` events can be sent to `observer`
    * once an `Error` or `Completed` event is sent, the sequence terminates and can't produce any other elements
    
    It is possible that events are sent from different threads, but no two events can be sent concurrently to
    `observer`.
    
    ### Resource Management
    
    When sequence sends `Complete` or `Error` event all internal resources that compute sequence elements
    will be freed.
    
    To cancel production of sequence elements and free resources immediately, call `dispose` on returned
    subscription.
    
    - returns: Subscription for `observer` that can be used to cancel production of sequence elements and free resources.
    */
    func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E
}
///: ObservableType 只规定了一个方法，即接收 Observer，并返回 Disposable。

extension ObservableType {
    
    /// Default implementation of converting `ObservableType` to `Observable`.
    public func asObservable() -> Observable<E> {
        // temporary workaround
        //return Observable.create(subscribe: self.subscribe)
        return Observable.create { o in
            return self.subscribe(o)
        }
    }
}
///: ObservableType 默认实现了 ObservableConvertibleType 协议规定的方法，即一个的 AnonymousObservable。
///: AnonymousObservable 是 fileprivate 修饰的，即只在 Observable 的扩展方法 create(:) 中使用了。
///: 注意，不像 AnyObserver，并没有 AnyObservable。
