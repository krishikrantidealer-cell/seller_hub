import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/technical_name.dart';
import 'package:seller_hub/presentation/dashboard/widgets/technical_name_selector.dart';

void main() {
  final sampleItems = <TechnicalNameModel>[
    const TechnicalNameModel(
      id: '1',
      name: 'Abamectin 1.9% EC',
      letter: 'A',
      commissionPercentage: 15.0,
    ),
    const TechnicalNameModel(
      id: '2',
      name: 'Acetobacter',
      letter: 'A',
      commissionPercentage: 25.0,
    ),
    const TechnicalNameModel(
      id: '3',
      name: 'Chlorpyrifos 20% EC',
      letter: 'C',
      commissionPercentage: 12.0,
    ),
    const TechnicalNameModel(
      id: '4',
      name: 'Chlorpyrifos 50% + Cypermethrin 5% EC',
      letter: 'C',
      commissionPercentage: 18.0,
    ),
    const TechnicalNameModel(
      id: '5',
      name: 'Imidacloprid 17.8% SL',
      letter: 'I',
      commissionPercentage: 10.0,
    ),
    const TechnicalNameModel(
      id: '6',
      name: 'Bio Chlorpyrifos Granules',
      letter: 'B',
      commissionPercentage: 14.0,
    ),
    const TechnicalNameModel(
      id: '7',
      name: 'Microchlor Formulation',
      letter: 'M',
      commissionPercentage: 8.0,
    ),
  ];

  group('filterAndRankTechnicalNames', () {
    test('returns all items when query is empty', () {
      final res = filterAndRankTechnicalNames(sampleItems, '   ');
      expect(res.length, sampleItems.length);
    });

    test('supports multi-token search across non-adjacent words', () {
      final res = filterAndRankTechnicalNames(sampleItems, 'chlo ec');
      expect(res.map((e) => e.name).toList(), [
        'Chlorpyrifos 20% EC',
        'Chlorpyrifos 50% + Cypermethrin 5% EC',
      ]);
    });

    test('ranks exact > prefix > word-boundary > substring', () {
      final items = [
        const TechnicalNameModel(id: 'sub', name: 'Microchlor', letter: 'M'),
        const TechnicalNameModel(id: 'word', name: 'Bio Chlor', letter: 'B'),
        const TechnicalNameModel(id: 'prefix', name: 'Chlorpyrifos', letter: 'C'),
        const TechnicalNameModel(id: 'exact', name: 'Chlor', letter: 'C'),
      ];
      final res = filterAndRankTechnicalNames(items, 'chlor');
      expect(res.map((e) => e.id).toList(), ['exact', 'prefix', 'word', 'sub']);
    });

    test('returns all items to browse when query exactly equals matchedItem', () {
      final matched = sampleItems[1];
      final res = filterAndRankTechnicalNames(
        sampleItems,
        'Acetobacter',
        matchedItem: matched,
      );
      expect(res.length, sampleItems.length);
    });
  });

  group('TechnicalNameSelector widget', () {
    testWidgets('filters on typing, selects item, and clears with X button',
        (tester) async {
      final controller = TextEditingController();
      TechnicalNameModel? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: TechnicalNameSelector(
                controller: controller,
                isDark: false,
                initialItems: sampleItems,
                onSelected: (item) => selected = item,
              ),
            ),
          ),
        ),
      );

      // Tap field to open dropdown
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      expect(find.text('7 technical names'), findsOneWidget);

      // Type multi-token query
      await tester.enterText(find.byType(TextFormField), 'chlo 50');
      await tester.pumpAndSettle();
      expect(find.text('1 technical name'), findsOneWidget);

      // Press ArrowDown + Enter to select highlighted match
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selected?.id, '4');
      expect(selected?.commissionPercentage, 18.0);
      expect(controller.text, 'Chlorpyrifos 50% + Cypermethrin 5% EC');

      // Tap Clear (X) button to reset and reopen full list
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(find.text('7 technical names'), findsOneWidget);

      controller.dispose();
    });
  });
}
