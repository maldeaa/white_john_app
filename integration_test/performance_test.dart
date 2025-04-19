import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:white_john_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Stress test: 50 random button clicks with SnackBar and Win/Lose handling', (WidgetTester tester) async {
    await tester.pumpWidget(const BlackjackApp());
    await tester.pumpAndSettle();
    print('Запущено главное меню');

    await tester.tap(find.text('Играть'));
    await tester.pumpAndSettle();
    print('Нажата кнопка "Играть"');

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    print('Прокручено вниз');

    await tester.tap(find.text('Выбрать колоду'));
    await tester.pumpAndSettle(Duration(seconds: 2));
    print('Нажата кнопка "Выбрать колоду"');

    await dismissSnackBar(tester);
    print('Стартовый SnackBar смахнут');

    int clicks = 0;
    bool hitPhase = true;
    final random = Random();

    while (clicks < 50) {
      if (find.text('Вы проиграли!').evaluate().isNotEmpty) {
        await tester.tap(find.text('Новая игра'));
        await tester.pumpAndSettle();
        await dismissSnackBar(tester);
        print('Обработан Lose экран, кликов: $clicks');
      } else if (find.text('Победа! Комбо 15 достигнуто и пройдено!').evaluate().isNotEmpty) {
        await tester.tap(find.text('Новая игра'));
        await tester.pumpAndSettle();
        await dismissSnackBar(tester);
        print('Обработан Win экран, кликов: $clicks');
      } else {
        await dismissSnackBar(tester);

        int presses = random.nextInt(3) + 1;
        if (hitPhase) {
          for (int i = 0; i < presses && clicks < 50; i++) {
            if (find.text('Ещё').evaluate().isNotEmpty) {
              await tester.tap(find.text('Ещё'));
              print('Клик ${clicks + 1}: Нажата кнопка "Ещё"');
              clicks++;
            } else {
              print('Клик ${clicks + 1}: Кнопка "Ещё" не найдена, пропускаем');
              break;
            }
            await tester.pumpAndSettle();
            await Future.delayed(Duration(milliseconds: 10));
          }
          hitPhase = false;
        } else {
          for (int i = 0; i < presses && clicks < 50; i++) {
            if (find.text('Хватит').evaluate().isNotEmpty) {
              await tester.tap(find.text('Хватит'));
              print('Клик ${clicks + 1}: Нажата кнопка "Хватит"');
              clicks++;
            } else {
              print('Клик ${clicks + 1}: Кнопка "Хватит" не найдена, пропускаем');
              break;
            }
            await tester.pumpAndSettle();
            await Future.delayed(Duration(milliseconds: 10));
          }
          hitPhase = true;
        }

        if (find.text('Новая партия').evaluate().isNotEmpty && clicks < 50) {
          await dismissSnackBar(tester);
          await tester.tap(find.text('Новая партия'), warnIfMissed: false);
          print('Клик ${clicks + 1}: Нажата кнопка "Новая партия"');
          clicks++;
          await tester.pumpAndSettle();
          await Future.delayed(Duration(milliseconds: 10));
        }
      }
    }
    print('Тест завершен: $clicks кликов выполнено');
  });
}

Future<void> dismissSnackBar(WidgetTester tester) async {
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.drag(find.byType(SnackBar), const Offset(0, 300));
    await tester.pumpAndSettle();
    print('SnackBar смахнут');
  }
}