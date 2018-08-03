//
//  RefCountDisposable.swift
//  RxSwift
//
//  Created by Junior B. on 10/29/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Represents a disposable resource that only disposes its underlying disposable resource when all dependent disposable objects have been disposed.
public final class RefCountDisposable : DisposeBase, Cancelable {
    private var _lock = SpinLock()
    ///: 这个语法不错，可以替换 `private var _disposable: Disposable? = nil` 的写法
    private var _disposable = nil as Disposable?
    ///: 指代该实例是否被调用过 dispose 方法
    private var _primaryDisposed = false
    private var _count = 0

    /// - returns: Was resource disposed.
    public var isDisposed: Bool {
        _lock.lock(); defer { _lock.unlock() }
        return _disposable == nil
    }

    /// Initializes a new instance of the `RefCountDisposable`.
    public init(disposable: Disposable) {
        _disposable = disposable
        super.init()
    }

    /**
     Holds a dependent disposable that when disposed decreases the refcount on the underlying disposable.

     When getter is called, a dependent disposable contributing to the reference count that manages the underlying disposable's lifetime is returned.
     */
    public func retain() -> Disposable {
        return _lock.calculateLocked {
            if let _ = _disposable {

                do {
                    let _ = try incrementChecked(&_count)
                } catch (_) {
                    rxFatalError("RefCountDisposable increment failed")
                }

                return RefCountInnerDisposable(self)
            } else {
                return Disposables.create()
            }
        }
    }

    /// Disposes the underlying disposable only when all dependent disposables have been disposed.
    public func dispose() {
        let oldDisposable: Disposable? = _lock.calculateLocked {
            if let oldDisposable = _disposable, !_primaryDisposed
            {
                _primaryDisposed = true

                if (_count == 0)
                {
                    _disposable = nil
                    return oldDisposable
                }
            }

            return nil
        }

        if let disposable = oldDisposable {
            disposable.dispose()
        }
    }

    fileprivate func release() {
        let oldDisposable: Disposable? = _lock.calculateLocked {
            if let oldDisposable = _disposable {
                do {
                    let _ = try decrementChecked(&_count)
                } catch (_) {
                    rxFatalError("RefCountDisposable decrement on release failed")
                }

                guard _count >= 0 else {
                    rxFatalError("RefCountDisposable counter is lower than 0")
                }

                if _primaryDisposed && _count == 0 {
                    _disposable = nil
                    return oldDisposable
                }
            }

            return nil
        }

        if let disposable = oldDisposable {
            disposable.dispose()
        }
    }
}

internal final class RefCountInnerDisposable: DisposeBase, Disposable
{
    private let _parent: RefCountDisposable
    private var _isDisposed: AtomicInt = 0

    init(_ parent: RefCountDisposable)
    {
        _parent = parent
        super.init()
    }

    internal func dispose()
    {
        if AtomicCompareAndSwap(0, 1, &_isDisposed) {
            _parent.release()
        }
    }
}
///: RefCountInner -> RefCount -> Disposable
///: 如果对 RefCountInner 进行 release，RefCount 的 count 会 -1，如果此时 count == 0 且 RefCount 曾被调用过 dispose，则对 Disposable 进行 dispose
///: 如果对 RefCount 进行 dispose，则会对 _primaryDisposed 进行标识。如果此时 count == 0，则直接对 Disposable 进行 dispose


