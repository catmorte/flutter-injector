typedef InstanceFactory<T extends dynamic> = T Function(Getter getter);
typedef InstanceFactoryWithParams<T extends dynamic> = T Function(Getter getter, Map<String, dynamic> params);

abstract class InstanceWrapper<T extends dynamic> {
  InstanceFactoryWithParams<T> _factory;

  InstanceWrapper(InstanceFactoryWithParams<T> value) : _factory = value;

  T getValue(Getter getter, String key, {Map<String, dynamic> params = const {}}) => _factory(getter, params);
}

class Singleton<T extends dynamic> extends InstanceWrapper<T> {
  T? _value;
  bool _initialized = false;

  Singleton(InstanceFactoryWithParams<T> value) : super(value);

  @override
  T getValue(Getter getter, String key, {Map<String, dynamic> params = const {}}) {
    if (_initialized) {
      return _value!;
    }
    _value = super.getValue(getter, key, params: params);
    _initialized = true;
    return _value!;
  }
}

class Prototype<T extends dynamic> extends InstanceWrapper<T> {
  Prototype(InstanceFactoryWithParams<T> value) : super(value);
}

abstract class Getter {
  T get<T extends dynamic>({String key = "", Map<String, dynamic> params = const {}, Injector? childInjector});
}

class Injector implements Getter {
  static final Injector _root = Injector._();
  static final Map<String, Injector> _injectorsRegistry = {};

  Injector? _parentInjector;
  Map<String, InstanceWrapper> instanceWrappers = {};

  Injector._([Injector? parentInjector]) : _parentInjector = parentInjector;

  factory Injector.root() => _root;

  Injector child() => Injector._(this);

  Injector namedChild(String key, {clear: false}) {
    if (clear) {
      Injector newInstance = Injector._(this);
      _injectorsRegistry[key] = newInstance;
      return newInstance;
    }
    return _injectorsRegistry.putIfAbsent(key, () => Injector._(this));
  }

  _generateKey<T>(String key) {
    String typeKey = T.toString();
    return '$typeKey:$key';
  }

  T get<T extends dynamic>({String key = "", Map<String, dynamic> params = const {}, Injector? childInjector}) {
    String genKey = _generateKey<T>(key);
    InstanceWrapper? instanceWrapper = instanceWrappers[genKey];
    if (instanceWrapper == null) {
      if (_parentInjector != null) {
        return _parentInjector!.get<T>(key: key, params: params, childInjector: childInjector ?? this);
      }
    }
    assert(instanceWrapper != null, '$genKey is not initialized yet');
    return instanceWrapper!.getValue(childInjector ?? this, genKey, params: params) as T;
  }

  void map<T extends dynamic>(InstanceFactory instanceFactory, {isSingleton = true, String key = ""}) {
    String genKey = _generateKey<T>(key);
    InstanceFactoryWithParams<T> factory = (i, _) => instanceFactory(i);
    instanceWrappers[genKey] = isSingleton ? Singleton(factory) : Prototype(factory);
  }

  void mapWithParams<T extends dynamic>(InstanceFactoryWithParams instanceFactory, {String key = ""}) {
    String genKey = _generateKey<T>(key);
    instanceWrappers[genKey] = Prototype(instanceFactory);
  }
}
