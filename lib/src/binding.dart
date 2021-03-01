import 'dart:io';
import 'dart:math';

import 'class.dart';
import 'interpreter.dart';
import 'value.dart';
import 'lexicon.dart';
import 'class.dart' show HT_Instance;

/// Type of external functions in Dart.
typedef HT_External = dynamic Function(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs});

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HT_BaseBinding {
  /// A ref of interpreter, initted by [Hetu.init()] function.
  /// For eval script in script it self.
  static Interpreter itp;

  /// Some low level external dart functions for Hetu to use.
  static Map<String, HT_External> dartFunctions = {
    'typeof': _typeof,
    'help': _help,
    'print': _print,
    'string': _string,
    'System.invoke': _system_invoke,
    'System.now': _system_now,
    'Console.write': _console_write,
    'Console.writeln': _console_writeln,
    'Console.getln': _console_getln,
    'Console.eraseLine': _console_erase_line,
    'Console.setTitle': _console_set_title,
    'Console.cls': _console_cls,
    'Value.toString': HTVal_Value._to_string,
    'num.parse': HTVal_Number._parse,
    'num.toStringAsFixed': HTVal_Number._to_string_as_fixed,
    'num.truncate': HTVal_Number._truncate,
    'String.isEmpty': HTVal_String._is_empty,
    'String.parse': HTVal_String._parse,
    'String.substring': HTVal_String._substring,
    'List.length': HTVal_List._get_length,
    'List.add': HTVal_List._add,
    'List.clear': HTVal_List._clear,
    'List.removeAt': HTVal_List._remove_at,
    'List.indexOf': HTVal_List._index_of,
    'List.elementAt': HTVal_List._element_at,
    'Map.length': HTVal_Map._get_length,
    'Map.keys': HTVal_Map._get_keys,
    'Map.values': HTVal_Map._get_values,
    'Map.containsKey': HTVal_Map._contains_key,
    'Map.containsValue': HTVal_Map._contains_value,
    'Map.setVal': HTVal_Map._set_val,
    'Map.addAll': HTVal_Map._add_all,
    'Map.clear': HTVal_Map._clear,
    'Map.remove': HTVal_Map._remove,
    'Map.getVal': HTVal_Map._get_val,
    'Map.putIfAbsent': HTVal_Map._put_if_absent,
    'random': _math_random,
    'randomInt': _math_random_int,
    'sqrt': _math_sqrt,
    'log': _math_log,
    'sin': _math_sin,
    'cos': _math_cos,
  };

  static dynamic _typeof(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      return HT_TypeOf(args.first).toString();
    }
  }

  static dynamic _help(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      var value = args.first;
      if (value is HT_Instance) {
        return value.typeid.toString();
      } else {
        return HT_TypeOf(value).toString();
      }
    }
  }

  static dynamic _print(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var sb = StringBuffer();
    for (final arg in args) {
      sb.write('$arg ');
    }
    print(sb.toString());
  }

  static dynamic _string(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var result = StringBuffer();
    for (final arg in args) {
      result.write(arg);
    }
    return result.toString();
  }

  static dynamic _system_invoke(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.length >= 2) {
      var func_name = args[0];
      var className = args[1];
      var arguments = args[2];
      return itp?.invoke(func_name, classname: className, args: arguments);
    }
  }

  static dynamic _console_write(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) stdout.write(args.first);
  }

  static dynamic _console_writeln(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) stdout.writeln(args.first);
  }

  static dynamic _console_getln(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      stdout.write('${args.first.toString()}');
    } else {
      stdout.write('>');
    }
    var input = stdin.readLineSync();
    return input;
  }

  static dynamic _console_erase_line(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    stdout.write('\x1B[1F\x1B[1G\x1B[1K');
  }

  static dynamic _console_set_title(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      var title = args.first.toString();
      stdout.write('\x1b]0;${title}\x07');
    }
  }

  static dynamic _console_cls(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    stdout.write('\x1B[2J\x1B[0;0H');
  }

  static dynamic _math_random(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    return Random().nextDouble();
  }

  static dynamic _math_random_int(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      final value = (args.first as num).truncate();
      return Random().nextInt(value);
    }
  }

  static dynamic _math_sqrt(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      num value = args.first;
      return sqrt(value);
    }
  }

  static dynamic _math_log(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      num value = args.first;
      return log(value);
    }
  }

  static dynamic _math_sin(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      num value = args.first;
      return sin(value);
    }
  }

  static dynamic _math_cos(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      num value = args.first;
      return cos(value);
    }
  }

  static dynamic _system_now(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    return DateTime.now().millisecondsSinceEpoch;
  }
}

/// Abstract base class of all class wrapper for literal values.
abstract class HTVal_Value extends HT_Instance {
  final dynamic value;

  HTVal_Value(this.value, String className, int line, int column, Interpreter interpreter)
      : super(
          interpreter,
          interpreter.fetchGlobal(className),
        );

  //dynamic get value => fetch('_val', null, null, globalInterpreter.curFileName, error: false, from: type);

  static dynamic _to_string(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (instance != null) {
      //var value = instance.fetch('_val', null, null, globalInterpreter.curFileName, from: instance.type);
      return (instance as HTVal_Value).value.toString();
    }
  }
}

/// Class wrapper for literal number.
class HTVal_Number extends HTVal_Value {
  HTVal_Number(num value, int line, int column, Interpreter interpreter)
      : super(value, HT_Lexicon.number, line, column, interpreter);

  static dynamic _parse(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      return num.tryParse(args.first);
    }
  }

  static dynamic _to_string_as_fixed(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var fractionDigits = 0;
    if (args.isNotEmpty) {
      fractionDigits = args.first;
    }
    var numObj = (instance as HTVal_Number);
    num number = numObj?.value;
    return number.toStringAsFixed(fractionDigits);
  }

  static dynamic _truncate(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var numObj = (instance as HTVal_Number);
    num number = numObj?.value;
    return number.truncate();
  }
}

/// Class wrapper for literal boolean.
class HTVal_Boolean extends HTVal_Value {
  HTVal_Boolean(bool value, int line, int column, Interpreter interpreter)
      : super(value, HT_Lexicon.number, line, column, interpreter);
}

/// Class wrapper for literal string.
class HTVal_String extends HTVal_Value {
  HTVal_String(String value, int line, int column, Interpreter interpreter)
      : super(value, HT_Lexicon.string, line, column, interpreter);

  static dynamic _is_empty(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var strObj = (instance as HTVal_String);
    String str = strObj?.value;
    return str?.isEmpty;
  }

  static dynamic _substring(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var strObj = (instance as HTVal_String);
    String str = strObj?.value;
    if (args.isNotEmpty) {
      int startIndex = args[0];
      int endIndex;
      if (args.length >= 2) {
        endIndex = args[1];
      }
      return str?.substring(startIndex, endIndex);
    }
  }

  static dynamic _parse(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      return args.first.toString();
    }
  }
}

/// Class wrapper for literal list.
class HTVal_List extends HTVal_Value {
  String valueType;

  HTVal_List(List value, int line, int column, Interpreter interpreter, {this.valueType})
      : super(value, HT_Lexicon.list, line, column, interpreter) {
    valueType ??= HT_Lexicon.ANY;
  }

  static dynamic _get_length(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var listObj = (instance as HTVal_List);
    return listObj?.value?.length ?? -1;
  }

  static dynamic _add(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var listObj = (instance as HTVal_List);
    listObj?.value?.addAll(args);
  }

  static dynamic _clear(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var listObj = (instance as HTVal_List);
    List list = listObj?.value;
    list?.clear();
  }

  static dynamic _remove_at(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var listObj = (instance as HTVal_List);
    List list = listObj?.value;
    if (args.isNotEmpty) {
      list?.removeAt(args.first);
    }
  }

  static dynamic _index_of(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var listObj = (instance as HTVal_List);
    List list = listObj?.value;
    if (args.isNotEmpty) {
      return list?.indexOf(args.first);
    }
    return -1;
  }

  static dynamic _element_at(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var listObj = (instance as HTVal_List);
    List list = listObj?.value;
    try {
      if ((args.isNotEmpty) && (args.first is int)) {
        return list?.elementAt(args.first);
      }
    } catch (e) {
      if (e is RangeError) {
        // TODO: 打印错误信息到Errors
        return null;
      }
    }
    return null;
  }
}

/// Class wrapper for literal map.
class HTVal_Map extends HTVal_Value {
  String keyType;
  String valueType;

  HTVal_Map(Map value, int line, int column, Interpreter interpreter, {this.keyType, this.valueType})
      : super(value, HT_Lexicon.map, line, column, interpreter) {
    keyType ??= HT_Lexicon.ANY;
    valueType ??= HT_Lexicon.ANY;
  }

  static dynamic _get_length(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    return (instance as HTVal_Map)?.value?.length ?? -1;
  }

  static dynamic _get_keys(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    return (instance as HTVal_Map)?.value?.keys?.toList() ?? [];
  }

  static dynamic _get_values(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    return (instance as HTVal_Map)?.value?.values?.toList() ?? [];
  }

  static dynamic _contains_key(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsKey(args.first);
    }
    return false;
  }

  static dynamic _contains_value(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      if (map != null) return map.containsValue(args.first);
    }
    return false;
  }

  static dynamic _set_val(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if ((args.isNotEmpty) && args.length >= 2) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      var key = args[0];
      var value = args[1];
      if (map != null) {
        map[key] = value;
      }
    }
  }

  static dynamic _add_all(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if ((args.isNotEmpty) && (args.first is Map)) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      map?.addAll(args.first);
    }
  }

  static dynamic _clear(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    var mapObj = (instance as HTVal_Map);
    Map map = mapObj?.value;
    map?.clear();
  }

  static dynamic _remove(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      map.remove(args.first);
    }
  }

  static dynamic _get_val(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      var key = args[0];
      return map[key];
    }
  }

  static dynamic _put_if_absent(HT_Instance instance, List<dynamic> args, {Map<String, dynamic> namedArgs}) {
    if (args.isNotEmpty) {
      var mapObj = (instance as HTVal_Map);
      Map map = mapObj?.value;
      var key = args[0];
      var value = args[1];
      map.putIfAbsent(key, () => value);
    }
  }
}
