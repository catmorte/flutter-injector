import 'package:flutter_test/flutter_test.dart';
import 'package:injector/injector.dart';


abstract class IX {
  int getValue();
}

abstract class IY {
  int getValue();

  int getXValue();
}

abstract class IZ {}

class X implements IX {
  final int _value;

  X(int value) : _value = value;

  int getValue() => _value;
}

class Y implements IY {
  final int _value;
  final IX _x;

  Y(IX x, int value)
      : _x = x,
        _value = value;

  int getValue() => _value;

  int getXValue() => _x.getValue();
}

void main() {
  /* simple */
  test('root', () {
    final Injector ir = Injector.root();
    int x = 0;
    int y = 0;
    ir.map<IX>((i) => X(++x));
    ir.map<IY>((i) => Y(i.get<IX>(), ++y), isSingleton: false);
    expect(ir.get<IX>().getValue(), 1);
    expect(ir.get<IY>().getXValue(), 1);
    expect(ir.get<IY>().getValue(), 2);
    expect(ir.get<IX>().getValue(), 1);
    expect(() => ir.get<IZ>(), throwsAssertionError);
  });

  test('child', () {
    final Injector ic = Injector.root().child();
    int x = 0;
    int y = 0;
    ic.map<IX>((i) => X(++x));
    ic.map<IY>((i) => Y(i.get<IX>(), ++y), isSingleton: false);
    expect(ic.get<IX>().getValue(), 1);
    expect(ic.get<IY>().getXValue(), 1);
    expect(ic.get<IY>().getValue(), 2);
    expect(ic.get<IX>().getValue(), 1);
    expect(() => ic.get<IZ>(), throwsAssertionError);
  });

  test('root & child', () {
    final Injector ir = Injector.root();
    ir.map<IX>((i) => X(100));
    ir.map<IY>((i) => Y(i.get<IX>(), 100), isSingleton: false);
    final Injector ic = Injector.root().child();
    ic.map<IX>((i) => X(200));
    expect(ic.get<IX>().getValue(), 200);
    expect(ic.get<IY>().getXValue(), 200);
    expect(ic.get<IY>().getValue(), 100);
    expect(ic.get<IX>().getValue(), 200);
    expect(ir.get<IX>().getValue(), 100);
  });

  /* with key */
  test('root with key', () {
    final Injector ir = Injector.root();
    int x = 0;
    int y = 0;
    ir.map<IX>((i) => X(++x), key: "key");
    ir.map<IY>((i) => Y(i.get<IX>(key: "key"), ++y), isSingleton: false, key: "key");
    expect(ir.get<IX>(key: "key").getValue(), 1);
    expect(ir.get<IY>(key: "key").getXValue(), 1);
    expect(ir.get<IY>(key: "key").getValue(), 2);
    expect(ir.get<IX>(key: "key").getValue(), 1);
    expect(() => ir.get<IZ>(key: "key"), throwsAssertionError);
    expect(() => ir.get<IX>(key: "unknown_key"), throwsAssertionError);
    expect(() => ir.get<IY>(key: "unknown_key"), throwsAssertionError);
  });

  test('child with key', () {
    final Injector ic = Injector.root().child();
    int x = 0;
    int y = 0;
    ic.map<IX>((i) => X(++x), key: "key");
    ic.map<IY>((i) => Y(i.get<IX>(key: "key"), ++y), isSingleton: false, key: "key");
    expect(ic.get<IX>(key: "key").getValue(), 1);
    expect(ic.get<IY>(key: "key").getXValue(), 1);
    expect(ic.get<IY>(key: "key").getValue(), 2);
    expect(ic.get<IX>(key: "key").getValue(), 1);
    expect(() => ic.get<IZ>(key: "key"), throwsAssertionError);
    expect(() => ic.get<IX>(key: "unknown_key"), throwsAssertionError);
    expect(() => ic.get<IY>(key: "unknown_key"), throwsAssertionError);
  });

  test('root & child with key', () {
    final Injector ir = Injector.root();
    ir.map<IX>((i) => X(100), key: "key");
    ir.map<IY>((i) => Y(i.get<IX>(key: "key"), 100), isSingleton: false, key: "key");
    final Injector ic = Injector.root().child();
    ic.map<IX>((i) => X(200), key: "key");
    expect(ic.get<IX>(key: "key").getValue(), 200);
    expect(ic.get<IY>(key: "key").getXValue(), 200);
    expect(ic.get<IY>(key: "key").getValue(), 100);
    expect(ic.get<IX>(key: "key").getValue(), 200);
    expect(ir.get<IX>(key: "key").getValue(), 100);
    expect(() => ic.get<IX>(key: "unknown_key"), throwsAssertionError);
    expect(() => ic.get<IY>(key: "unknown_key"), throwsAssertionError);
  });

  /* params */
  test('root with params', () {
    final Injector ir = Injector.root();
    ir.mapWithParams<IX>((i, params) => X(params["intValue"] as int), key: "key_with_params");
    expect(ir.get<IX>(key: "key_with_params", params: {"intValue": 200}).getValue(), 200);
  });
}
