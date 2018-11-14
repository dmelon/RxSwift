//
//  DispatchQueueConfiguration.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 7/23/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import Dispatch
import struct Foundation.TimeInterval

struct DispatchQueueConfiguration {
    let queue: DispatchQueue
    let leeway: DispatchTimeInterval
}

private func dispatchInterval(_ interval: Foundation.TimeInterval) -> DispatchTimeInterval {
    precondition(interval >= 0.0)
    // TODO: Replace 1000 with something that actually works 
    // NSEC_PER_MSEC returns 1000000
    return DispatchTimeInterval.milliseconds(Int(interval * 1000.0))
}

extension DispatchQueueConfiguration {
    ///: 一律异步 schedule 出 action
    func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        let cancel = SingleAssignmentDisposable()

        queue.async {
            if cancel.isDisposed {
                return
            }


            cancel.setDisposable(action(state))
        }

        return cancel
    }

    ///: 指定某个时间点 schedule 出 action
    func scheduleRelative<StateType>(_ state: StateType, dueTime: Foundation.TimeInterval, action: @escaping (StateType) -> Disposable) -> Disposable {
        let deadline = DispatchTime.now() + dispatchInterval(dueTime)

        let compositeDisposable = CompositeDisposable()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        #if swift(>=4.0)
            timer.schedule(deadline: deadline, leeway: leeway)
        #else
            timer.scheduleOneshot(deadline: deadline, leeway: leeway)
        #endif

        // TODO:
        // This looks horrible, and yes, it is.
        // It looks like Apple has made a conceputal change here, and I'm unsure why.
        // Need more info on this.
        // It looks like just setting timer to fire and not holding a reference to it
        // until deadline causes timer cancellation.
        var timerReference: DispatchSourceTimer? = timer
        let cancelTimer = Disposables.create {
            timerReference?.cancel()
            timerReference = nil
        }

        timer.setEventHandler(handler: {
            if compositeDisposable.isDisposed {
                return
            }
            _ = compositeDisposable.insert(action(state))
            cancelTimer.dispose()
        })
        timer.resume()

        _ = compositeDisposable.insert(cancelTimer)

        return compositeDisposable
    }

    ///: 每隔一段时间重复 schedule action
    func schedulePeriodic<StateType>(_ state: StateType, startAfter: TimeInterval, period: TimeInterval, action: @escaping (StateType) -> StateType) -> Disposable {
        let initial = DispatchTime.now() + dispatchInterval(startAfter)

        var timerState = state

        let timer = DispatchSource.makeTimerSource(queue: queue)
        #if swift(>=4.0)
            timer.schedule(deadline: initial, repeating: dispatchInterval(period), leeway: leeway)
        #else
            timer.scheduleRepeating(deadline: initial, interval: dispatchInterval(period), leeway: leeway)
        #endif
        
        // TODO:
        // This looks horrible, and yes, it is.
        // It looks like Apple has made a conceputal change here, and I'm unsure why.
        // Need more info on this.
        // It looks like just setting timer to fire and not holding a reference to it
        // until deadline causes timer cancellation.
        var timerReference: DispatchSourceTimer? = timer
        let cancelTimer = Disposables.create {
            timerReference?.cancel()
            timerReference = nil
        }

        timer.setEventHandler(handler: {
            if cancelTimer.isDisposed {
                return
            }
            timerState = action(timerState)
        })
        timer.resume()
        
        return cancelTimer
    }
}
