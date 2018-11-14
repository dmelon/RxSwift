//
//  MainScheduler.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Dispatch

/**
Abstracts work that needs to be performed on `DispatchQueue.main`. In case `schedule` methods are called from `DispatchQueue.main`, it will perform action immediately without scheduling.

This scheduler is usually used to perform UI work.

Main scheduler is a specialization of `SerialDispatchQueueScheduler`.

This scheduler is optimized for `observeOn` operator. To ensure observable sequence is subscribed on main thread using `subscribeOn`
operator please use `ConcurrentMainScheduler` because it is more optimized for that purpose.
*/
///: 协议继承链：MainScheduler <- SerialDispatchQueueScheduler <- SchedulerType <- ImmediateSchedulerType
public final class MainScheduler : SerialDispatchQueueScheduler {

    private let _mainQueue: DispatchQueue

    var numberEnqueued: AtomicInt = 0

    /// Initializes new instance of `MainScheduler`.
    public init() {
        _mainQueue = DispatchQueue.main
        super.init(serialQueue: _mainQueue)
    }

    /// Singleton instance of `MainScheduler`
    public static let instance = MainScheduler()

    /// Singleton instance of `MainScheduler` that always schedules work asynchronously
    /// and doesn't perform optimizations for calls scheduled from main queue.
    public static let asyncInstance = SerialDispatchQueueScheduler(serialQueue: DispatchQueue.main)

    /// In case this method is called on a background thread it will throw an exception.
    public class func ensureExecutingOnScheduler(errorMessage: String? = nil) {
        if !DispatchQueue.isMain {
            rxFatalError(errorMessage ?? "Executing on background thread. Please use `MainScheduler.instance.schedule` to schedule work on main thread.")
        }
    }

    ///: 父类是用 DispatchQueueConfiguration 来实现的，而 DispatchQueueConfiguration 的实现都是 async 的，因此这里完全没调用 super 的方法
    ///: asyncInstance 即是用父类实现的
    override func scheduleInternal<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        let currentNumberEnqueued = AtomicIncrement(&numberEnqueued)

        ///: 和 ConcurrentMainScheduler 相比，MainScheduler 当前只能 schedule 一个 action。
        ///: 比如一个 action 中嵌套了一个 schedule，那么第二个 action 就一定会被 async 执行
        if DispatchQueue.isMain && currentNumberEnqueued == 1 {
            let disposable = action(state)
            _ = AtomicDecrement(&numberEnqueued)
            return disposable
        }

        let cancel = SingleAssignmentDisposable()

        _mainQueue.async {
            if !cancel.isDisposed {
                _ = action(state)
            }

            _ = AtomicDecrement(&self.numberEnqueued)
        }

        return cancel
    }
}
