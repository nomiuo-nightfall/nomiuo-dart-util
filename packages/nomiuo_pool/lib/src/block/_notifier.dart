part of 'block.dart';

abstract class Notifier {
  factory Notifier() => _Notifier();

  /// Notify all observers.
  Future<void> notifyAll({Object? obj});

  /// Notify one observer.
  ///
  /// If there is no observer, then throw [NoSuchObserver].
  Future<void> notifyOne({Object? obj});

  /// Notify specified observer.
  ///
  /// If the observer is not blocked on the current notifier, then
  /// throw [NoSuchObserver].
  Future<void> notify(Observer observer, {Object? obj});

  bool get hasObservers;

  Future<void> _addObserver(Observer observer);

  Future<void> _removeObserver(Observer observer);
}

class _Notifier implements Notifier {
  final List<Observer> _observers = <Observer>[];

  @override
  Future<void> notify(Observer observer, {Object? obj}) async {
    if (!_observers.contains(observer)) {
      throw NoSuchObserver('No such observer: $observer');
    }

    await _wakeUpTargetObserver(observer, obj: obj);
  }

  @override
  Future<void> notifyAll({Object? obj}) => Future.wait(_observers
      .map((Observer observer) => _wakeUpTargetObserver(observer, obj: obj)));

  @override
  Future<void> notifyOne({Object? obj}) async {
    if (_observers.isEmpty) {
      throw NoSuchObserver('No such observer: $this');
    }
    final Random random = Random();
    await _wakeUpTargetObserver(_observers[random.nextInt(_observers.length)],
        obj: obj);
  }

  Future<void> _wakeUpTargetObserver(Observer observer, {Object? obj}) async {
    await observer._wakeUp(obj: obj);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> _addObserver(Observer observer) async {
    _observers.add(observer);
  }

  @override
  Future<void> _removeObserver(Observer observer) async {
    _observers.remove(observer);
  }

  @override
  bool get hasObservers => _observers.isNotEmpty;
}
