import 'package:hetu_script/hetu_script.dart';

class DartPerson {
  static String race = 'Caucasian';
  static String meaning(int n) => 'The meaning of life is $n';

  String get child => 'Tom';
  DartPerson();
  DartPerson.withName([this.name = 'some guy']);

  String? name = 'default name';
  void greeting() {
    print('Hi! I\'m $name');
  }
}

class DartPersonClassBinding extends HT_ExternNamespace {
  @override
  dynamic fetch(String id) {
    switch (id) {
      case 'DartPerson':
        return () => DartPerson();
      case 'DartPerson.withName':
        return ([name = 'some guy']) => DartPerson.withName(name);
      case 'meaning':
        return (int n) => DartPerson.meaning(n);
      case 'race':
        return DartPerson.race;
      default:
        throw HTErr_Undefined(id);
    }
  }

  @override
  void assign(String id, dynamic value) {
    switch (id) {
      case 'race':
        return DartPerson.race = value;
      default:
        throw HTErr_Undefined(id);
    }
  }
  @override
  void instanceFetch(dynamic instance, String id) {
    var i = instance as DartPerson;
    return i.fetch(id);
  }

  @override
  void instanceAssign(dynamic instance, String id, dynamic value) {
    var i = instance as DartPerson;
    i.assign(id, value);
  }
}

extension DartPersonBinding on DartPerson {
  dynamic fetch(String varName, {String? from}) {
    switch (varName) {
      case 'name':
        return name;
      case 'greeting':
        return greeting;
      default:
        throw HTErr_Undefined(varName);
    }
  }
  void assign(String varName, dynamic value, {String? from}) {
    switch (varName) {
      case 'name':
        name = value;
        break;
      default:
        throw HTErr_Undefined(varName);
    }
  }
}


void main() {
  var d = DartPerson();
  var n = d.fetch('name');
  print('name: $n');
  var hetu = HT_Interpreter();
  hetu.bindExternalNamespace('DartPerson', DartPersonClassBinding());

  hetu.eval('''
      external class DartPerson {
        static var race
        static fun meaning (n: num)
        construct
        get child
        construct withName
        var name
        fun greeting
      }
      fun main {
        var p1 = DartPerson()
        print(p1.name)
        p1.name = 'Alice'
        print(p1.name)
        var p2 = DartPerson.withName('Jimmy')
        print(p2.name)
        p2.name = 'John'
        p2.greeting();

        print('My race is', DartPerson.race)
        DartPerson.race = 'Reptile'
        print('Oh no! My race turned into', DartPerson.race)

        print(DartPerson.meaning(42))
      }
      ''', invokeFunc: 'main');
}
