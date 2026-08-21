import 'package:flutter/foundation.dart';

/// Desteklenen matematik işlemleri.
enum MathOp { add, sub, mul, div }

extension MathOpSymbol on MathOp {
  /// Çark üzerinde ve soru metninde gösterilecek sembol.
  String get symbol {
    switch (this) {
      case MathOp.add:
        return '+';
      case MathOp.sub:
        return '-';
      case MathOp.mul:
        return '×';
      case MathOp.div:
        return '÷';
    }
  }
}

/// Soruda hangi alanın boş (bilinmeyen) olduğunu belirtir.
///
/// [operandB] => "A op ? = C"  (ikinci operand bilinmiyor)
/// [result]   => "A op B = ?"  (sonuç bilinmiyor)
enum MissingSlot { operandB, result }

/// Tek bir matematik sorusunu temsil eder.
@immutable
class Question {
  /// Birinci sayı (sol çark).
  final int a;

  /// İkinci sayı (sağ çark).
  final int b;

  /// İşlem türü (orta çark).
  final MathOp op;

  /// Doğru tam sonuç (A op B).
  final int result;

  /// Hangi alanın bilinmediği.
  final MissingSlot missing;

  const Question({
    required this.a,
    required this.b,
    required this.op,
    required this.result,
    required this.missing,
  });

  /// Oyuncudan beklenen doğru sayısal cevap.
  ///
  /// Eğer sonuç bilinmiyorsa => result, ikinci operand bilinmiyorsa => b.
  int get correctAnswer => missing == MissingSlot.result ? result : b;

  /// İnsan tarafından okunabilir soru metni, ör: "3 + ? = 7".
  String get prompt {
    final left = a.toString();
    final mid = op.symbol;
    final right = missing == MissingSlot.operandB ? '?' : b.toString();
    final res = missing == MissingSlot.result ? '?' : result.toString();
    return '$left $mid $right = $res';
  }

  /// Tam (çözülmüş) soru metni, ör: "3 + 4 = 7".
  String get solvedPrompt => '$a ${op.symbol} $b = $result';
}

/// Sonuç ekranında her sorunun özetini tutar.
@immutable
class QuestionResult {
  final Question question;
  final bool correct;

  /// Oyuncunun girdiği son cevap (boş geçildiyse null).
  final int? givenAnswer;

  const QuestionResult({
    required this.question,
    required this.correct,
    required this.givenAnswer,
  });
}
