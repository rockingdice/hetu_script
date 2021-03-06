/// Hetu运算符优先级
/// Description     Operator           Associativity   Precedence
//  Unary postfix   e., e()            None            16
//  Unary prefix    -e, !e             None            15
//  Multiplicative  *, /, %            Left            14
//  Additive        +, -               Left            13
//  Relational      <, >, <=, >=, is   None            8
//  Equality        ==, !=             None            7
//  Logical AND     &&                 Left            6
//  Logical Or      ||                 Left            5
//  Assignment      =                  Right           1

/// Dart运算符优先级（参考用）
/// Description      Operator                             Associativity   Precedence
//  Unary postfix    e., e?., e++, e--, e1[e2], e()       None            16
//  Unary prefix     -e, !e, ˜e, ++e, --e, await e        None            15
//  Multiplicative   *, /, ˜/, %                          Left            14
//  Additive         +, -                                 Left            13
//  Shift            <<, >>, >>>                          Left            12
//  Bitwise          AND &                                Left            11
//  Bitwise          XOR ˆ                                Left            10
//  Bitwise          Or |                                 Left            9
//  Relational       <, >, <=, >=, as, is, is!            None            8
//  Equality         ==, !=                               None            7
//  Logical AND      &&                                   Left            6
//  Logical Or       ||                                   Left            5
//  If-null          ??                                   Left            4
//  Conditional      e1 ? e2 : e3                         Right           3
//  Cascade          ..                                   Left            2
//  Assignment       =, *=, /=, +=, -=, &=, ˆ=, etc.      Right           1

abstract class HT_Lexicon {
  static const defaultProgramMainFunc = 'main';

  static const scriptPattern = r'((/\*[\s\S]*?\*/)|(//.*))|' // 注释 group(1)
      r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(4)
      r'(\.\.\.|\|\||&&|==|!=|<=|>=|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|' // 标点符号和运算符号 group(5)
      r'(0x[0-9a-fA-F]+|\d+(\.\d+)?)|' // 数字字面量 group(4)
      r"(('(\\'|[^'])*')|" // 字符串字面量 group(8)
      r'("(\\"|[^"])*"))';

  static const commandLinePattern = r'(//.*)|' // 注释 group(1)
      r'([_]?[\p{L}]+[\p{L}_0-9]*)|' // 标识符 group(2)
      r'(\|\||&&|==|!=|<=|>=|[><=/%\+\*\-\?!:\[\]\)\(\.])|' // 标点符号和运算符号 group(3)
      r'(0x[0-9a-fA-F]+|\d+(\.\d+)?)|' // 数字字面量 group(4)
      r"(('(\\'|[^'])*')|" // 字符串字面量 group(6)
      r'("(\\"|[^"])*"))';

  static const tokenGroupComment = 1;
  static const tokenGroupIdentifier = 4;
  static const tokenGroupPunctuation = 5;
  static const tokenGroupNumber = 6;
  static const tokenGroupString = 8;

  static const number = 'num';
  static const boolean = 'bool';
  static const string = 'String';

  static Set<String> get literals => {
        number,
        boolean,
        string,
      };

  static const endOfFile = 'end_of_file'; // 文件末尾
  static const newLine = '\n';
  static const multiline = '\\';
  static const variadicArguments = '...';
  static const underscore = '_';
  static const globals = '__globals__';
  static const externs = '__external__';
  static const method = '__method__';
  static const instance = '__instance_of_';
  static const instancePrefix = 'instance of ';
  static const constructor = '__construct__';
  static const getter = '__get__';
  static const setter = '__set__';

  static const object = 'Object';
  static const unknown = '__unknown__';
  static const function = 'function';
  static const list = 'List';
  static const map = 'Map';
  static const length = 'length';
  static const procedure = 'procedure';
  static const identifier = 'identifier';

  static const TRUE = 'true';
  static const FALSE = 'false';
  static const NULL = 'null';

  static const VOID = 'void';
  static const VAR = 'var';
  static const DEF = 'def';
  static const LET = 'let';
  // any并不是一个类型，而是一个向解释器表示放弃类型检查的关键字
  static const ANY = 'any';
  static const TYPEDEF = 'typedef';

  static const STATIC = 'static';
  static const CONST = 'const';
  static const CONSTRUCT = 'construct';
  static const GET = 'get';
  static const SET = 'set';
  static const NAMESPACE = 'namespace';
  static const AS = 'as';
  static const ABSTRACT = 'abstract';
  static const CLASS = 'class';
  static const STRUCT = 'struct';
  static const INTERFACE = 'interface';
  static const FUN = 'fun';
  static const PROC = 'proc';
  static const THIS = 'this';
  static const SUPER = 'super';
  static const EXTENDS = 'extends';
  static const IMPLEMENTS = 'implements';
  static const MIXIN = 'mixin';
  static const EXTERNAL = 'external';
  static const IMPORT = 'import';

  static const ASSERT = 'assert';
  static const BREAK = 'break';
  static const CONTINUE = 'continue';
  static const FOR = 'for';
  static const IN = 'in';
  static const IF = 'if';
  static const ELSE = 'else';
  static const RETURN = 'return';
  static const WHILE = 'while';
  static const DO = 'do';
  static const WHEN = 'when';

  static const IS = 'is';

  /// 保留字，不能用于变量名字
  static Set<String> get keywords => {
        NULL,
        STATIC,
        VAR,
        DEF,
        LET,
        ANY,
        TYPEDEF,
        NAMESPACE,
        AS,
        CLASS,
        STRUCT,
        INTERFACE,
        FUN,
        PROC,
        VOID,
        CONSTRUCT,
        GET,
        SET,
        THIS,
        SUPER,
        EXTENDS,
        IMPLEMENTS,
        MIXIN,
        EXTERNAL,
        IMPORT,
        BREAK,
        CONTINUE,
        FOR,
        IN,
        IF,
        ELSE,
        RETURN,
        WHILE,
        DO,
        WHEN,
        IS,
      };

  /// 函数调用表达式
  static const nullExpr = 'null_expression';
  static const literalExpr = 'literal_expression';
  static const groupExpr = 'group_expression';
  static const vectorExpr = 'vector_expression';
  static const blockExpr = 'block_expression';
  static const varExpr = 'variable_expression';
  static const typeExpr = 'type_expression';
  static const unaryExpr = 'unary_expression';
  static const binaryExpr = 'binary_expression';
  static const callExpr = 'call_expression';
  static const thisExpr = 'this_expression';
  static const assignExpr = 'assign_expression';
  static const subGetExpr = 'subscript_get_expression';
  static const subSetExpr = 'subscript_set_expression';
  static const memberGetExpr = 'member_get_expression';
  static const memberSetExpr = 'member_set_expression';
  static const namedVarExpr = 'named_var_expression';

  static const importStmt = 'import_statement';
  static const varStmt = 'variable_statement';
  static const exprStmt = 'expression_statement';
  static const blockStmt = 'block_statement';
  static const returnStmt = 'return_statement';
  static const breakStmt = 'break_statement';
  static const continueStmt = 'continue_statement';
  static const ifStmt = 'if_statement';
  static const whileStmt = 'while_statement';
  static const forInStmt = 'for_in_statement';
  static const classStmt = 'class_statement';
  static const funcStmt = 'function_statement';
  static const externFuncStmt = 'external_function_statement';
  static const constructorStmt = 'constructor_function_statement';

  static const memberGet = '.';
  static const subGet = '[';
  static const call = '(';

  /// 后缀操作符，包含多个符号
  static Set<String> get unaryPostfixs => {
        memberGet,
        subGet,
        call,
      };

  static const not = '!';
  static const negative = '-';

  /// 前缀操作符，包含多个符号
  static Set<String> get unaryPrefixs => {
        not,
        negative,
      };

  static const multiply = '*';
  static const devide = '/';
  static const modulo = '%';

  /// 乘除操作符，包含多个符号
  static Set<String> get multiplicatives => {
        multiply,
        devide,
        modulo,
      };

  static const add = '+';
  static const subtract = '-';

  /// 加减操作符，包含多个符号
  static Set<String> get additives => {
        add,
        subtract,
      };

  static const greater = '>';
  static const greaterOrEqual = '>=';
  static const lesser = '<';
  static const lesserOrEqual = '<=';

  /// 大小判断操作符，包含多个符号
  static Set<String> get relationals => {
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
        IS,
      };

  static const equal = '==';
  static const notEqual = '!=';

  /// 相等判断操作符，包含多个符号
  static Set<String> get equalitys => {
        equal,
        notEqual,
      };

  static const and = '&&';
  static const or = '||';

  static const assign = '=';

  /// 赋值类型操作符，包含多个符号
  static Set<String> get assignments => {
        assign,
      };

  static const comma = ',';
  static const colon = ':';
  static const semicolon = ';';
  static const roundLeft = '(';
  static const roundRight = ')';
  static const curlyLeft = '{';
  static const curlyRight = '}';
  static const squareLeft = '[';
  static const squareRight = ']';
  static const angleLeft = '<';
  static const angleRight = '>';

  static Set<String> get Punctuations => {
        not,
        multiply,
        devide,
        modulo,
        add,
        subtract,
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
        equal,
        notEqual,
        and,
        or,
        assign,
        comma,
        colon,
        semicolon,
        memberGet,
        roundLeft,
        roundRight,
        curlyLeft,
        curlyRight,
        squareLeft,
        squareRight,
        angleLeft,
        angleRight,
      };

  static const errorUnsupport = 'Unsupport value type';
  static const errorExpected = 'expected, ';
  static const errorUnexpected = 'Unexpected identifier';
  static const errorPrivateMember = 'Could not acess private member';
  static const errorPrivateDecl = 'Could not acess private declaration';
  static const errorInitialized = 'has not initialized';
  static const errorUndefined = 'Undefined identifier';
  static const errorUndefinedOperator = 'Undefined operator';
  static const errorDeclared = 'is already declared';
  static const errorDefined = 'is already defined';
  static const errorRange = 'Index out of range, should be less than';
  static const errorInvalidLeftValue = 'Invalid left-value';
  static const errorCallable = 'is not callable';
  static const errorUndefinedMember = 'isn\'t defined for the class';
  static const errorCondition = 'Condition expression must evaluate to type "bool"';
  static const errorMissingFuncDef = 'Missing function definition body of';
  static const errorGet = 'is not a collection or object';
  static const errorSubGet = 'is not a List or Map';
  static const errorExtends = 'is not a class';
  static const errorSetter = 'Setter function\'s arity must be 1';
  static const errorNullObject = 'is null';
  static const errorMutable = 'is immutable';
  static const errorNotType = 'is not a type.';

  static const errorOfType = 'of type';

  static const errorType1 = 'Variable';
  static const errorType2 = 'can\'t be assigned with type';

  static const errorArgType1 = 'Argument';
  static const errorArgType2 = 'doesn\'t match parameter type';

  static const errorReturnType1 = 'Value of type';
  static const errorReturnType2 = 'can\'t be returned from function';
  static const errorReturnType3 = 'because it has a return type of';

  static const errorArity1 = 'Number of arguments';
  static const errorArity2 = 'doesn\'t match parameter requirement of function';
}
