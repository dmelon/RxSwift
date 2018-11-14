//
//  ConcurrentMainScheduler.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 10/17/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import struct Foundation.Date
import struct Foundation.TimeInterval
import Dispatch

/**
Abstracts work that needs to be performed on `MainThread`. In case `schedule` methods are called from main thread, it will perform action immediately without scheduling.

This scheduler is optimized for `subscribeOn` operator. If you want to observe observable sequence elements on main thread using `observeOn` operator,
`MainScheduler` is more suitable for that purpose.
*/
public final class ConcurrentMainScheduler : SchedulerType {
    public typealias TimeInterval = Foundation.TimeInterval
    public typealias Time = Date

    private let _mainScheduler: MainScheduler
    private let _mainQueue: DispatchQueue

    /// - returns: Current time.
    public var now : Date {
        return _mainScheduler.now as Date
    }

    private init(mainScheduler: MainScheduler) {
        _mainQueue = DispatchQueue.main
        _mainScheduler = mainScheduler
    }

    /// Singleton instance of `ConcurrentMainScheduler`
    public static let instance = ConcurrentMainScheduler(mainScheduler: MainScheduler.instance)

    /**
    Schedules an action to be executed immediately.

    - parameter state: State passed to the action to be executed.
    - parameter action: Action to be executed.
    - returns: The disposable object used to cancel the scheduled action (best effort).
    */
    ///: 和 MainScheduler 相比，ConcurrentMainScheduler 可以进行嵌套 schedule。
    ///: 比如一个 action 中嵌套了一个 schedule，那么第二个 action 也会被 sync 执行
    public func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        if DispatchQueue.isMain {
            return action(state)
        }

        let cancel = SingleAssignmentDisposable()

        _mainQueue.async {
            if cancel.isDisposed {
                return
            }

            cancel.setDisposable(action(state))
        }

        return cancel
    }

    /**
    Schedules an action to be executed.

    - parameter state: State passed to the action to be executed.
    - parameter dueTime: Relative time after which to execute the action.
    - parameter action: Action to be executed.
    - returns: The disposable object used to cancel the scheduled action (best effort).
    */
    public final func scheduleRelative<StateType>(_ state: StateType, dueTime: Foundation.TimeInterval, action: @escaping (StateType) -> Disposable) -> Disposable {
        return _mainScheduler.scheduleRelative(state, dueTime: dueTime, action: action)
    }

    /**
    Schedules a periodic piece of work.

    - parameter state: State passed to the action to be executed.
    - parameter startAfter: Period after which initial work should be run.
    - parameter period: Period for running the work periodically.
    - parameter action: Action to be executed.
    - returns: The disposable object used to cancel the scheduled action (best effort).
    */
    public func schedulePeriodic<StateType>(_ state: StateType, startAfter: TimeInterval, period: TimeInterval, action: @escaping (StateType) -> StateType) -> Disposable {
        return _mainScheduler.schedulePeriodic(state, startAfter: startAfter, period: period, action: action)
    }
}
