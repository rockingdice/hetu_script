import 'errors.dart';
import 'expression.dart';
import 'interpreter.dart';
import 'lexicon.dart';
import 'statement.dart';
import 'token.dart';
import 'value.dart';

enum ParseStyle {
  /// 程序脚本使用完整的标点符号规则，包括各种括号、逗号和分号
  ///
  /// 库脚本中只能出现变量、类和函数的声明
  library,

  /// 函数语句块中只能出现变量声明、控制语句和函数调用
  function,

  /// 类定义中只能出现变量和函数的声明
  classDefinition,
}

/// 负责对Token列表进行语法分析并生成语句列表
///
/// 语法定义如下
///
/// <程序>    ::=   <导入语句> | <变量声明>
///
/// <变量声明>      ::=   <变量声明> | <函数定义> | <类定义>
///
/// <语句块>    ::=   "{" <语句> { <语句> } "}"
///
/// <语句>      ::=   <声明> | <表达式> ";"
///
/// <表达式>    ::=   <标识符> | <单目> | <双目> | <三目>
///
/// <运算符>    ::=   <运算符>
class Parser {
  final Interpreter interpreter;

  final List<Token> _tokens = [];
  var _tokPos = 0;
  String _curClassName;
  String _curFileName;

  static int internalVarIndex = 0;

  Parser(this.interpreter);

  /// 检查包括当前Token在内的接下来数个Token是否符合类型要求
  ///
  /// 如果consume为true，则在符合要求时向前移动Token指针
  ///
  /// 在不符合预期时，如果error为true，则抛出异常
  bool expect(List<String> tokTypes, {bool consume = false, bool error}) {
    error ??= consume;
    for (var i = 0; i < tokTypes.length; ++i) {
      if (consume) {
        if (curTok.type != tokTypes[i]) {
          if (error) {
            throw HTErr_Expected(
                tokTypes[i], curTok.lexeme, curTok.line, curTok.column,
                _curFileName);
          }
          return false;
        }
        ++_tokPos;
      } else {
        if (peek(i).type != tokTypes[i]) {
          return false;
        }
      }
    }
    return true;
  }

  /// 如果当前token符合要求则前进一步，然后返回之前的token，否则抛出异常
  Token match(String tokenType, {bool error = true}) {
    if (curTok.type == tokenType) {
      return advance(1);
    }

    if (error) throw HTErr_Expected(
        tokenType, curTok.lexeme, curTok.line, curTok.column, _curFileName);
    return Token.EOF;
  }

  /// 前进指定距离，返回原先位置的Token
  Token advance(int distance) {
    _tokPos += distance;
    return peek(-distance);
  }

  /// 获得相对于目前位置一定距离的Token，不改变目前位置
  Token peek(int pos) {
    if ((_tokPos + pos) < _tokens.length) {
      return _tokens[_tokPos + pos];
    } else {
      return Token.EOF;
    }
  }

  /// 获得当前Token
  Token get curTok => peek(0);

  // {
  // var cur = peek(0);
  // if (cur == env.lexicon.Multiline) {
  //   advance(1);
  //   cur = peek(0);
  // }
  // return cur;
  // }

  List<Stmt> parse(List<Token> tokens, {
    String fileName,
    ParseStyle style = ParseStyle.library,
  }) {
    _tokens.clear();
    _tokens.addAll(tokens);
    _tokPos = 0;
    _curFileName = fileName;

    final statements = <Stmt>[];
    try {
      while (curTok.type != HT_Lexicon.endOfFile) {
        var stmt = _parseStmt(style: style);
        if (stmt != null) statements.add(stmt);
      }
    } catch (e) {
      print(e);
    } finally {
      return statements;
    }
  }

  /// 使用递归向下的方法生成表达式，不断调用更底层的，优先级更高的子Parser
  Expr _parseExpr() => _parseAssignmentExpr();

  HT_Type _parseTypeId() {
    final type_name = advance(1).lexeme;
    var type_args = <HT_Type>[];
    if (expect([HT_Lexicon.angleLeft], consume: true, error: false)) {
      while ((curTok.type != HT_Lexicon.angleRight) &&
          (curTok.type != HT_Lexicon.endOfFile)) {
        type_args.add(_parseTypeId());
        expect([HT_Lexicon.comma], consume: true, error: false);
      }
      expect([HT_Lexicon.angleRight], consume: true);
    }

    return HT_Type(type_name, arguments: type_args);
  }

  /// 赋值 = ，优先级 1，右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  Expr _parseAssignmentExpr() {
    final expr = _parseLogicalOrExpr();

    if (HT_Lexicon.assignments.contains(curTok.type)) {
      final op = advance(1);
      final value = _parseAssignmentExpr();

      if (expr is SymbolExpr) {
        return AssignExpr(expr.name, op, value, _curFileName);
      } else if (expr is MemberGetExpr) {
        return MemberSetExpr(expr.collection, expr.key, value, _curFileName);
      } else if (expr is SubGetExpr) {
        return SubSetExpr(expr.collection, expr.key, value, _curFileName);
      }

      throw HTErr_InvalidLeftValue(op.lexeme, op.line, op.column, _curFileName);
    }

    return expr;
  }

  /// 逻辑或 or ，优先级 5，左合并
  Expr _parseLogicalOrExpr() {
    var expr = _parseLogicalAndExpr();
    while (curTok.type == HT_Lexicon.or) {
      final op = advance(1);
      final right = _parseLogicalAndExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 逻辑和 and ，优先级 6，左合并
  Expr _parseLogicalAndExpr() {
    var expr = _parseEqualityExpr();
    while (curTok.type == HT_Lexicon.and) {
      final op = advance(1);
      final right = _parseEqualityExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 逻辑相等 ==, !=，优先级 7，无合并
  Expr _parseEqualityExpr() {
    var expr = _parseRelationalExpr();
    while (HT_Lexicon.equalitys.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseRelationalExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，无合并
  Expr _parseRelationalExpr() {
    var expr = _parseAdditiveExpr();
    while (HT_Lexicon.relationals.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseAdditiveExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 加法 +, -，优先级 13，左合并
  Expr _parseAdditiveExpr() {
    var expr = _parseMultiplicativeExpr();
    while (HT_Lexicon.additives.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseMultiplicativeExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 乘法 *, /, %，优先级 14，左合并
  Expr _parseMultiplicativeExpr() {
    var expr = _parseUnaryPrefixExpr();
    while (HT_Lexicon.multiplicatives.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseUnaryPrefixExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 前缀 -e, !e，优先级 15，不能合并
  Expr _parseUnaryPrefixExpr() {
    // 因为是前缀所以不能像别的表达式那样先进行下一级的分析
    Expr expr;
    if (HT_Lexicon.unaryPrefixs.contains(curTok.type)) {
      var op = advance(1);

      expr = UnaryExpr(op, _parseUnaryPostfixExpr(), _curFileName);
    } else {
      expr = _parseUnaryPostfixExpr();
    }
    return expr;
  }

  /// 后缀 e., e[], e()，优先级 16，取属性不能合并，下标和函数调用可以右合并
  Expr _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    //多层函数调用可以合并
    while (true) {
      if (expect([HT_Lexicon.call], consume: true, error: false)) {
        var params = <Expr>[];
        while ((curTok.type != HT_Lexicon.roundRight) &&
            (curTok.type != HT_Lexicon.endOfFile)) {
          //需要判断是否为命名参数
          if (expect([HT_Lexicon.identifier, HT_Lexicon.colon], error: false, consume: false)) {
            var varName = match(HT_Lexicon.identifier, error: false);
            advance(1);
            var varValue = _parseExpr();
            var varExpr = NamedVarExpr(varName, varValue, _curFileName);
            params.add(varExpr);
          } else {
            params.add(_parseExpr());
          }

          if (curTok.type != HT_Lexicon.roundRight) {
            expect([HT_Lexicon.comma], consume: true);
          }
        }
        expect([HT_Lexicon.roundRight], consume: true);
        expr = CallExpr(expr, params, _curFileName);
      } else if (expect([HT_Lexicon.memberGet], consume: true, error: false)) {
        final name = match(HT_Lexicon.identifier);
        expr = MemberGetExpr(expr, name, _curFileName);
      } else if (expect([HT_Lexicon.subGet], consume: true, error: false)) {
        var index_expr = _parseExpr();
        expect([HT_Lexicon.squareRight], consume: true);
        expr = SubGetExpr(expr, index_expr, _curFileName);
      } else {
        break;
      }
    }
    return expr;
  }

  /// 只有一个Token的简单表达式
  Expr _parsePrimaryExpr() {
    if (curTok.type == HT_Lexicon.NULL) {
      advance(1);
      return NullExpr(peek(-1).line, peek(-1).column, _curFileName);
    } else if (HT_Lexicon.literals.contains(curTok.type)) {
      var index = interpreter.addLiteral(curTok.literal);
      advance(1);
      return ConstExpr(index, peek(-1).line, peek(-1).column, _curFileName);
    } else if (curTok.type == HT_Lexicon.THIS) {
      advance(1);
      return ThisExpr(peek(-1), _curFileName);
    } else if (curTok.type == HT_Lexicon.identifier) {
      advance(1);
      return SymbolExpr(peek(-1), _curFileName);
    } else if (curTok.type == HT_Lexicon.roundLeft) {
      advance(1);
      var innerExpr = _parseExpr();
      expect([HT_Lexicon.roundRight], consume: true);
      return GroupExpr(innerExpr, _curFileName);
    } else if (curTok.type == HT_Lexicon.squareLeft) {
      final line = curTok.line;
      final col = advance(1).column;
      var list_expr = <Expr>[];
      while (curTok.type != HT_Lexicon.squareRight) {
        list_expr.add(_parseExpr());
        if (curTok.type != HT_Lexicon.squareRight) {
          expect([HT_Lexicon.comma], consume: true);
        }
      }
      expect([HT_Lexicon.squareRight], consume: true);
      return LiteralVectorExpr(list_expr, line, col, _curFileName);
    } else if (curTok.type == HT_Lexicon.curlyLeft) {
      final line = curTok.line;
      final col = advance(1).column;
      var map_expr = <Expr, Expr>{};
      while (curTok.type != HT_Lexicon.curlyRight) {
        var key_expr = _parseExpr();
        expect([HT_Lexicon.colon], consume: true);
        var value_expr = _parseExpr();
        expect([HT_Lexicon.comma], consume: true, error: false);
        map_expr[key_expr] = value_expr;
      }
      expect([HT_Lexicon.curlyRight], consume: true);
      return LiteralDictExpr(map_expr, line, col, _curFileName);
    } else {
      throw HTErr_Unexpected(
          curTok.lexeme, curTok.line, curTok.column, _curFileName);
    }
  }

  Stmt _parseStmt({ParseStyle style = ParseStyle.library}) {
    if (curTok.type == HT_Lexicon.newLine) advance(1);
    switch (style) {
      case ParseStyle.library:
        {
          final is_extern = expect(
              [HT_Lexicon.EXTERNAL], consume: true, error: false);
          if (expect([HT_Lexicon.IMPORT])) {
            return _parseImportStmt();
          } // var变量声明
          else if (expect([HT_Lexicon.VAR])) {
            return _parseVarStmt();
          } // let变量声明
          else if (expect([HT_Lexicon.LET])) {
            return _parseVarStmt(type_inferrence: true);
          } // 类声明
          else if (expect([HT_Lexicon.CLASS])) {
            return _parseClassDeclStmt();
          } // 函数声明
          else if (expect([HT_Lexicon.FUN])) {
            return _parseFuncDeclStmt(
                FuncStmtType.normal, is_extern: is_extern);
          } // 过程声明
          else if (expect([HT_Lexicon.PROC])) {
            return _parseFuncDeclStmt(
                FuncStmtType.procedure, is_extern: is_extern);
          } else {
            throw HTErr_Unexpected(
                curTok.lexeme, curTok.line, curTok.column, _curFileName);
          }
        }
        break;
      case ParseStyle.function:
        {
          // 函数块中不能出现extern或者static关键字的声明
          // var变量声明
          if (expect([HT_Lexicon.VAR])) {
            return _parseVarStmt();
          } // var变量声明
          else if (expect([HT_Lexicon.VAR])) {
            return _parseVarStmt();
          } // def
          else if (expect([HT_Lexicon.DEF])) {
            return _parseVarStmt(type_inferrence: true);
          } // let变量声明
          else if (expect([HT_Lexicon.LET])) {
            return _parseVarStmt(type_inferrence: true, is_mutable: false);
          } // 函数声明
          else if (expect([HT_Lexicon.FUN])) {
            return _parseFuncDeclStmt(FuncStmtType.normal);
          } // 过程声明
          else if (expect([HT_Lexicon.PROC])) {
            return _parseFuncDeclStmt(FuncStmtType.procedure);
          } // 赋值语句
          else if (expect([HT_Lexicon.identifier, HT_Lexicon.assign])) {
            return _parseAssignStmt();
          } //If语句
          else if (expect([HT_Lexicon.IF])) {
            return _parseIfStmt();
          } // While语句
          else if (expect([HT_Lexicon.WHILE])) {
            return _parseWhileStmt();
          } // For语句
          else if (expect([HT_Lexicon.FOR])) {
            return _parseForStmt();
          } // 跳出语句
          else if (expect([HT_Lexicon.BREAK])) {
            advance(1);
            return BreakStmt();
          } // 继续语句
          else if (expect([HT_Lexicon.CONTINUE])) {
            advance(1);
            return ContinueStmt();
          } // 返回语句
          else if (curTok.type == HT_Lexicon.RETURN) {
            return _parseReturnStmt();
          }
          // 表达式
          else {
            return _parseExprStmt();
          }
        }
        break;
      case ParseStyle.classDefinition:
        {
          final is_extern = expect(
              [HT_Lexicon.EXTERNAL], consume: true, error: false);
          final is_static = expect(
              [HT_Lexicon.STATIC], consume: true, error: false);
          // var变量声明
          if (expect([HT_Lexicon.VAR]) || expect([HT_Lexicon.LET])) {
            return _parseVarStmt(is_static: is_static);
          } // def
          else if (expect([HT_Lexicon.DEF])) {
            return _parseVarStmt(type_inferrence: true);
          } // let变量声明
          else if (expect([HT_Lexicon.LET])) {
            return _parseVarStmt(type_inferrence: true, is_mutable: false);
          } // 构造函数
          // TODO：命名的构造函数
          else if (expect([HT_Lexicon.CONSTRUCT])) {
            return _parseFuncDeclStmt(
                FuncStmtType.constructor, is_extern: is_extern,
                is_static: is_static);
          } // setter函数声明
          else if (expect([HT_Lexicon.GET])) {
            return _parseFuncDeclStmt(FuncStmtType.getter, is_extern: is_extern,
                is_static: is_static);
          } // getter函数声明
          else if (expect([HT_Lexicon.SET])) {
            return _parseFuncDeclStmt(FuncStmtType.setter, is_extern: is_extern,
                is_static: is_static);
          } // 成员函数声明
          else if (expect([HT_Lexicon.FUN])) {
            return _parseFuncDeclStmt(FuncStmtType.method, is_extern: is_extern,
                is_static: is_static);
          } // 过程声明
          else if (expect([HT_Lexicon.PROC])) {
            return _parseFuncDeclStmt(
                FuncStmtType.procedure, is_extern: is_extern,
                is_static: is_static);
          } else {
            throw HTErr_Unexpected(
                curTok.lexeme, curTok.line, curTok.column, _curFileName);
          }
        }
        break;
    }
    return null;
  }

  List<Stmt> _parseBlock({ParseStyle style = ParseStyle.library}) {
    var stmts = <Stmt>[];
    while ((curTok.type != HT_Lexicon.curlyRight) &&
        (curTok.type != HT_Lexicon.endOfFile)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HT_Lexicon.curlyRight], consume: true);
    return stmts;
  }

  BlockStmt _parseBlockStmt({ParseStyle style = ParseStyle.library}) {
    var stmts = <Stmt>[];
    while ((curTok.type != HT_Lexicon.curlyRight) &&
        (curTok.type != HT_Lexicon.endOfFile)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HT_Lexicon.curlyRight], consume: true);
    return BlockStmt(stmts);
  }

  ImportStmt _parseImportStmt() {
    // 之前校验过了所以这里直接跳过
    advance(1);
    String filename = match(HT_Lexicon.string).literal;
    String spacename;
    if (expect([HT_Lexicon.AS], consume: true, error: false)) {
      spacename = match(HT_Lexicon.identifier).lexeme;
    }
    var stmt = ImportStmt(filename, nameSpace: spacename);
    expect([HT_Lexicon.semicolon], consume: true, error: false);
    return stmt;
  }

  /// 变量声明语句
  VarDeclStmt _parseVarStmt(
      {bool is_static = false, bool type_inferrence = false, bool is_mutable = true}) {
    advance(1);
    final name = match(HT_Lexicon.identifier);
    HT_Type decl_type;
    if (expect([HT_Lexicon.colon], consume: true, error: false)) {
      decl_type = _parseTypeId();
    }

    Expr initializer;
    if (expect([HT_Lexicon.assign], consume: true, error: false)) {
      initializer = _parseExpr();
    }
    // 语句结尾
    expect([HT_Lexicon.semicolon], consume: true, error: false);
    return VarDeclStmt(
      name,
      declType: decl_type,
      initializer: initializer,
      //isExtern: is_extern,
      isStatic: is_static,
      typeInferrence: type_inferrence,
      isMutable: is_mutable,
    );
  }

  /// 为了避免涉及复杂的左值右值问题，赋值语句在河图中不作为表达式处理
  /// 而是分成直接赋值，取值后复制和取属性后复制
  ExprStmt _parseAssignStmt() {
    // 之前已经校验过等于号了所以这里直接跳过
    var name = advance(1);
    var assignTok = advance(1);
    var value = _parseExpr();
    // 语句结尾
    expect([HT_Lexicon.semicolon], consume: true, error: false);
    var expr = AssignExpr(name, assignTok, value, _curFileName);
    return ExprStmt(expr);
  }

  ExprStmt _parseExprStmt() {
    var stmt = ExprStmt(_parseExpr());
    // 语句结尾
    expect([HT_Lexicon.semicolon], consume: true, error: false);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    Expr expr;
    if (!expect([HT_Lexicon.semicolon], consume: true, error: false)) {
      expr = _parseExpr();
    }
    expect([HT_Lexicon.semicolon], consume: true, error: false);
    return ReturnStmt(keyword, expr);
  }

  IfStmt _parseIfStmt() {
    advance(1);
    expect([HT_Lexicon.roundLeft], consume: true);
    var condition = _parseExpr();
    expect([HT_Lexicon.roundRight], consume: true);
    Stmt thenBranch;
    if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
      thenBranch = _parseBlockStmt(style: ParseStyle.function);
    } else {
      thenBranch = _parseStmt(style: ParseStyle.function);
    }
    Stmt elseBranch;
    if (expect([HT_Lexicon.ELSE], consume: true, error: false)) {
      if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
        elseBranch = _parseBlockStmt(style: ParseStyle.function);
      } else {
        elseBranch = _parseStmt(style: ParseStyle.function);
      }
    }
    return IfStmt(condition, thenBranch, elseBranch);
  }

  WhileStmt _parseWhileStmt() {
    // 之前已经校验过括号了所以这里直接跳过
    advance(1);
    expect([HT_Lexicon.roundLeft], consume: true);
    var condition = _parseExpr();
    expect([HT_Lexicon.roundRight], consume: true);
    Stmt loop;
    if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
      loop = _parseBlockStmt(style: ParseStyle.function);
    } else {
      loop = _parseStmt(style: ParseStyle.function);
    }
    return WhileStmt(condition, loop);
  }

  /// For语句其实会在解析时转换为While语句
  BlockStmt _parseForStmt() {
    var list_stmt = <Stmt>[];
    expect([HT_Lexicon.FOR, HT_Lexicon.roundLeft], consume: true);
    // 递增变量
    final i = '__i${internalVarIndex++}';
    list_stmt.add(VarDeclStmt(TokenIdentifier(i, curTok.line, curTok.column),
        declType: HT_Type.number,
        initializer: ConstExpr(
            interpreter.addLiteral(0), curTok.line, curTok.column,
            _curFileName)));
    // 指针
    var varname = match(HT_Lexicon.identifier);
    var typeid = HT_Type.ANY;
    if (expect([HT_Lexicon.colon], consume: true, error: false)) {
      typeid = _parseTypeId();
    }
    list_stmt.add(VarDeclStmt(varname, declType: typeid));
    expect([HT_Lexicon.IN], consume: true);
    var list_obj = _parseExpr();
    // 条件语句
    var get_length =
    MemberGetExpr(list_obj,
        TokenIdentifier(HT_Lexicon.length, curTok.line, curTok.column),
        _curFileName);
    var condition = BinaryExpr(SymbolExpr(
        TokenIdentifier(i, curTok.line, curTok.column), _curFileName),
        Token(HT_Lexicon.lesser, curTok.line, curTok.column), get_length,
        _curFileName);
    // 在循环体之前手动插入递增语句和指针语句
    // 按下标取数组元素
    var loop_body = <Stmt>[];
    // 这里一定要复制一个list_obj的表达式，否则在resolve的时候会因为是相同的对象出错，覆盖掉上面那个表达式的位置
    var sub_get_value = SubGetExpr(
        list_obj.clone(), SymbolExpr(
        TokenIdentifier(i, curTok.line, curTok.column), _curFileName),
        _curFileName);
    var assign_stmt = ExprStmt(
        AssignExpr(TokenIdentifier(varname.lexeme, curTok.line, curTok.column),
            Token(HT_Lexicon.assign, curTok.line, curTok.column), sub_get_value,
            _curFileName));
    loop_body.add(assign_stmt);
    // 递增下标变量
    var increment_expr = BinaryExpr(
        SymbolExpr(
            TokenIdentifier(i, curTok.line, curTok.column), _curFileName),
        Token(HT_Lexicon.add, curTok.line, curTok.column),
        ConstExpr(interpreter.addLiteral(1), curTok.line, curTok.column,
            _curFileName),
        _curFileName);
    var increment_stmt = ExprStmt(
        AssignExpr(TokenIdentifier(i, curTok.line, curTok.column),
            Token(HT_Lexicon.assign, curTok.line, curTok.column),
            increment_expr, _curFileName));
    loop_body.add(increment_stmt);
    // 循环体
    expect([HT_Lexicon.roundRight], consume: true);
    if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
      loop_body.addAll(_parseBlock(style: ParseStyle.function));
    } else {
      loop_body.add(_parseStmt(style: ParseStyle.function));
    }
    list_stmt.add(WhileStmt(condition, BlockStmt(loop_body)));
    return BlockStmt(list_stmt);
  }

  List<VarDeclStmt> _parseParameters() {
    var params = <VarDeclStmt>[];
    var optionalStarted = false;
    var namedStarted = false;
    while ((curTok.type != HT_Lexicon.roundRight) &&
        (curTok.type != HT_Lexicon.squareRight) &&
        (curTok.type != HT_Lexicon.curlyRight) &&
        (curTok.type != HT_Lexicon.endOfFile)) {
      if (params.isNotEmpty) {
        expect([HT_Lexicon.comma], consume: true, error: false);
      }
      // 可选参数，根据是否有方括号判断，一旦开始了可选参数，则不再增加参数数量arity要求
      if (!optionalStarted && !namedStarted) {
        optionalStarted =
            expect([HT_Lexicon.squareLeft], error: false, consume: true);
        if (!optionalStarted) {
          //检查命名参数，根据是否有花括号判断，同可选参数
          namedStarted =
              expect([HT_Lexicon.curlyLeft], error: false, consume: true);
        }
      }
      var name = match(HT_Lexicon.identifier);
      var typeid = HT_Type.ANY;
      if (expect([HT_Lexicon.colon], consume: true, error: false)) {
        typeid = _parseTypeId();
      }

      Expr initializer;
      if (optionalStarted || namedStarted) {
        //参数默认值
        if (expect([HT_Lexicon.assign], error: false, consume: true)) {
          initializer = _parseExpr();
        }
      }
      params.add(VarDeclStmt(name, declType: typeid,
          initializer: initializer,
          isOptional: optionalStarted,
          isNamed: namedStarted));
    }

    if (optionalStarted) expect([HT_Lexicon.squareRight], consume: true);
    if (namedStarted) expect([HT_Lexicon.curlyRight], consume: true);
    expect([HT_Lexicon.roundRight], consume: true);
    return params;
  }

  FuncDeclStmt _parseFuncDeclStmt(FuncStmtType functype,
      {bool is_extern = false, bool is_static = false}) {
    final keyword = advance(1);
    String func_name;
    var typeParams = <String>[];
    if (curTok.type == HT_Lexicon.identifier) {
      func_name = advance(1).lexeme;

      if (expect([HT_Lexicon.angleLeft], consume: true, error: false)) {
        while ((curTok.type != HT_Lexicon.angleRight) &&
            (curTok.type != HT_Lexicon.endOfFile)) {
          if (typeParams.isNotEmpty) {
            expect([HT_Lexicon.comma], consume: true);
          }
          typeParams.add(advance(1).lexeme);
        }
        expect([HT_Lexicon.angleRight], consume: true);
      }
    } else {
      if (functype == FuncStmtType.constructor) {
        func_name = _curClassName;
      }
    }

    var arity = 0;
    var params = <VarDeclStmt>[];

    if (functype != FuncStmtType.getter) {
      // 之前还没有校验过左括号
      if (expect([HT_Lexicon.roundLeft], consume: true, error: false)) {
        if (expect([HT_Lexicon.variadicArguments])) {
          arity = -1;
          advance(1);
        }
        params = _parseParameters();

        if (arity != -1) {
          for (var i = 0; i < params.length; ++i) {
            if (params[i].isOptional || params[i].isNamed) break;
            ++arity;
          }
        }

        // setter只能有一个参数，就是赋值语句的右值，但此处并不需要判断类型
        if ((functype == FuncStmtType.setter) && (arity != 1)) {
          throw HTErr_Setter(curTok.line, curTok.column, _curFileName);
        }
      }
    }

    var return_type = HT_Type.ANY;
    if (functype == FuncStmtType.procedure) {
      return_type = HT_Type.VOID;
    } else if ((functype != FuncStmtType.constructor) &&
        (expect([HT_Lexicon.colon], consume: true, error: false))) {
      return_type = _parseTypeId();
    }

    var body = <Stmt>[];
    if (!is_extern) {
      // 处理函数定义部分的语句块
      expect([HT_Lexicon.curlyLeft], consume: true);
      body = _parseBlock(style: ParseStyle.function);
    } else {
      expect([HT_Lexicon.semicolon], consume: true, error: false);
    }
    return FuncDeclStmt(keyword, func_name, return_type, params,
        typeParams: typeParams,
        arity: arity,
        definition: body,
        className: _curClassName,
        isExtern: is_extern,
        isStatic: is_static,
        funcType: functype);
  }

  ClassDeclStmt _parseClassDeclStmt() {
    ClassDeclStmt stmt;
    // 已经判断过了所以直接跳过Class关键字
    final keyword = advance(1);

    final class_name = advance(1).lexeme;
    _curClassName = class_name;

    var typeParams = <String>[];
    if (expect([HT_Lexicon.angleLeft], consume: true, error: false)) {
      while ((curTok.type != HT_Lexicon.angleRight) &&
          (curTok.type != HT_Lexicon.endOfFile)) {
        if (typeParams.isNotEmpty) {
          expect([HT_Lexicon.comma], consume: true);
        }
        typeParams.add(advance(1).lexeme);
      }
      expect([HT_Lexicon.angleRight], consume: true);
    }

    SymbolExpr super_class;
    HT_Type super_class_type;
    // 继承父类
    if (expect([HT_Lexicon.EXTENDS], consume: true, error: false)) {
      super_class = SymbolExpr(curTok, _curFileName);
      super_class_type = _parseTypeId();
    }
    // 类的定义体
    expect([HT_Lexicon.curlyLeft], consume: true);
    var variables = <VarDeclStmt>[];
    var methods = <FuncDeclStmt>[];
    if (curTok.type != HT_Lexicon.curlyRight) {
      while ((curTok.type != HT_Lexicon.curlyRight) &&
          (curTok.type != HT_Lexicon.endOfFile)) {
        var stmt = _parseStmt(style: ParseStyle.classDefinition);
        if (stmt is VarDeclStmt) {
          variables.add(stmt);
        } else if (stmt is FuncDeclStmt) {
          methods.add(stmt);
        }
      }
      expect([HT_Lexicon.curlyRight], consume: true);
    } else {
      advance(1);
    }

    stmt =
        ClassDeclStmt(
            keyword, class_name, super_class, super_class_type, variables,
            methods, typeParams: typeParams);
    _curClassName = null;
    return stmt;
  }
}
