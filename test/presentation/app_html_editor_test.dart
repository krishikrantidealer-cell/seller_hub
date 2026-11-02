import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:seller_hub/presentation/dashboard/widgets/app_html_editor.dart';

void main() {
  group('AppHtmlEditor Widget Tests', () {
    testWidgets('Renders visual mode, toolbar buttons, numeric font size, and live character/word count', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(text: '<p>Initial organic bio solution.</p>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                  label: 'Product Detail Description',
                  hintText: 'Enter agronomic details...',
                  isRequired: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify label and status cues
      expect(find.text('Product Detail Description'), findsOneWidget);
      expect(find.text('✎ Visual'), findsOneWidget);
      expect(find.text('</> HTML Source'), findsOneWidget);
      expect(find.text('👁 Preview'), findsOneWidget);

      // Verify Quill toolbar is present
      expect(find.byType(QuillSimpleToolbar), findsOneWidget);

      // Verify numeric font size displays a number (14)
      expect(find.text('14'), findsOneWidget);

      // Verify Agronomy Inserts bar is completely removed
      expect(find.text('Agronomy Inserts:'), findsNothing);
      expect(find.text('+ Dosage Table'), findsNothing);
      expect(find.text('+ Benefits'), findsNothing);
      expect(find.text('+ Application Guide'), findsNothing);

      // Verify status bar
      expect(find.text('WYSIWYG Rich Editor'), findsOneWidget);
      expect(find.textContaining('Words:'), findsOneWidget);
      expect(find.textContaining('Characters:'), findsOneWidget);
    });

    testWidgets('Editing existing HTML loads as clean human text without exposing tags in visual mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(
        text: '<h2>Pralaya Super - Cypermethrin 25% EC</h2><p>Pralaya Super is a highly effective insecticide.</p><ul><li>Active Ingredient: Cypermethrin 25% EC</li></ul>',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure raw HTML tags are NOT rendered as literal text in the visual editor
      expect(find.textContaining('<h2>'), findsNothing);
      expect(find.textContaining('<p>'), findsNothing);
      expect(find.textContaining('<ul>'), findsNothing);
      expect(find.textContaining('<li>'), findsNothing);
    });

    testWidgets('Switching to Storefront Preview mode displays HtmlWidget with parsed content', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(text: '<h3>Bio Fungicide</h3><p>Protects crops from blast.</p>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Storefront Preview tab
      await tester.tap(find.text('👁 Preview'));
      await tester.pumpAndSettle();

      expect(find.byType(HtmlWidget), findsOneWidget);
    });

    testWidgets('Switching to HTML Source mode displays raw markup in editable TextField', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(text: '<p>Direct raw HTML editing</p>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap HTML Source tab
      await tester.tap(find.text('</> HTML Source'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(controller.text, equals('<p>Direct raw HTML editing</p>'));
    });

    testWidgets('Live preview reflects content updates with inline CSS styling', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(text: '<p>Initial text</p>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Source mode and edit text with inline font and size style
      await tester.tap(find.text('</> HTML Source'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '<p><span style="color:#ef4444;font-family: Georgia;font-size: 24px">Updated Bio Agri Content</span></p>');
      await tester.pumpAndSettle();

      // Switch to preview mode
      await tester.tap(find.text('👁 Preview'));
      await tester.pumpAndSettle();

      // Verify HtmlWidget renders and contains updated content
      expect(find.byType(HtmlWidget), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Updated Bio Agri Content')),
        findsOneWidget,
      );
    });

    testWidgets('Visual editor converts font and numeric font-size to inline CSS in exported HTML', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(
        text: '<p>Specialized Bio Inoculant</p>',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final quillEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      final quill = quillEditor.controller;

      // Select "Specialized"
      quill.updateSelection(const TextSelection(baseOffset: 0, extentOffset: 11), ChangeSource.local);
      await tester.pumpAndSettle();

      final fontBtn = find.text('Font');
      await tester.tap(fontBtn);
      await tester.pumpAndSettle();

      final poppinsItem = find.text('Poppins (Geometric Sans)');
      await tester.tap(poppinsItem);
      await tester.pumpAndSettle();

      // Verify exported HTML contains font-family
      expect(controller.text, contains('font-family: Poppins'));

      // Switch to preview mode
      await tester.tap(find.text('👁 Preview'));
      await tester.pumpAndSettle();

      // Verify the rendered TextSpan in HtmlWidget has Poppins font loaded
      bool foundPoppins = false;
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      for (final rt in richTexts) {
        rt.text.visitChildren((span) {
          if (span.toPlainText().contains('Specialized') &&
              (span.style?.fontFamily == 'Poppins_regular' ||
               span.style?.fontFamily == 'Poppins' ||
               (span.style?.fontFamilyFallback?.contains('Poppins') ?? false))) {
            foundPoppins = true;
          }
          return true;
        });
      }
      expect(foundPoppins, isTrue, reason: 'Preview should render text with Poppins font family');
    });

    testWidgets('Maximize to full-screen and minimize back works properly without scroll or focus assertion errors', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(text: '<p>Fullscreen testing content</p>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the Maximize button on the toolbar
      final maximizeFinder = find.byTooltip('Maximize Editor (Full Screen)');
      expect(maximizeFinder, findsOneWidget);
      await tester.tap(maximizeFinder);
      await tester.pumpAndSettle();

      // Verify the Full-Screen dialog is open and shows badge
      expect(find.text('Full-Screen Focus Mode'), findsOneWidget);

      // Verify minimize button is available in the toolbar
      final minimizeFinder = find.byTooltip('Minimize Editor (Exit Fullscreen)');
      expect(minimizeFinder, findsOneWidget);

      // Tap minimize to exit full screen
      await tester.tap(minimizeFinder);
      await tester.pumpAndSettle();

      // Verify back in normal view with Maximize button restored
      expect(find.byTooltip('Maximize Editor (Full Screen)'), findsOneWidget);
      expect(find.text('Full-Screen Focus Mode'), findsNothing);
    });

    testWidgets('Tapping Insert Table toolbar button opens table dialog and inserts normal table', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(text: '<p>Initial text</p>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the Insert Table button exists
      final tableButton = find.byTooltip('Insert Table');
      expect(tableButton, findsOneWidget);

      // Tap the button
      await tester.tap(tableButton);
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.text('Insert Normal Table'), findsOneWidget);
      expect(find.text('Quick Presets'), findsOneWidget);
      expect(find.text('3 x 3 (Standard)'), findsOneWidget);

      // Tap Insert Table button in dialog
      final insertButton = find.widgetWithText(FilledButton, 'Insert Table');
      expect(insertButton, findsOneWidget);
      await tester.tap(insertButton);
      await tester.pumpAndSettle();

      // Verify dialog closed
      expect(find.text('Insert Normal Table'), findsNothing);

      // Verify the controller content now includes table or visual table
      expect(controller.text, anyOf(contains('<table'), contains('| Column 1')));
    });

    testWidgets('Tapping Insert Box Container toolbar button opens dialog and inserts normal box', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(text: '<p>Initial text</p>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the Insert Box Container button exists
      final boxButton = find.byTooltip('Insert Box Container');
      expect(boxButton, findsOneWidget);

      // Tap the button
      await tester.tap(boxButton);
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.text('Insert Box Container'), findsOneWidget);
      expect(find.text('Standard Bordered Container'), findsOneWidget);
      expect(find.text('Feature Highlight Container'), findsOneWidget);

      // Tap Insert on the first template
      final insertButtons = find.widgetWithText(FilledButton, 'Insert');
      expect(insertButtons, findsWidgets);
      await tester.tap(insertButtons.first);
      await tester.pumpAndSettle();

      // Verify dialog closed
      expect(find.text('Insert Box Container'), findsNothing);

      // Verify the controller content now includes the box container
      expect(controller.text, anyOf(contains('BOX: Section Title'), contains('border: 1px solid')));
    });

    testWidgets('Visual editor and preview share matching typography, spacing, and customStylesBuilder', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = TextEditingController(
        text: '<h2>Product Title</h2><p>Description paragraph.</p><ul><li>Spec 1</li></ul>',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check QuillEditor has customStyles configured
      final quillEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
      expect(quillEditor.config.customStyles, isNotNull);
      expect(quillEditor.config.customStyles!.paragraph?.style.fontSize, equals(14.0));

      // Switch to preview mode
      await tester.tap(find.text('👁 Preview'));
      await tester.pumpAndSettle();

      // Verify HtmlWidget has customStylesBuilder configured
      final htmlWidget = tester.widget<HtmlWidget>(find.byType(HtmlWidget));
      expect(htmlWidget.customStylesBuilder, isNotNull);
      expect(htmlWidget.textStyle?.fontSize, equals(14.0));
    });

    testWidgets('Visual table and box containers render as real interactive widgets with Edit and Delete controls', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // HTML containing both a table and a box container
      const initialHtml = '<p>Intro paragraph</p>'
          '<table style="width: 100%;">'
          '  <thead><tr><th>Crop</th><th>Dosage</th></tr></thead>'
          '  <tbody><tr><td>Cotton</td><td>2.5 ml</td></tr></tbody>'
          '</table>'
          '<div style="background-color: #ECFDF5; border: 1.5px solid #10B981; border-radius: 8px; padding: 16px;">'
          '  <h4>✨ Key Highlights</h4>'
          '  <p>Rapid translaminar absorption</p>'
          '</div>';

      final controller = TextEditingController(text: initialHtml);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify visual table widget rendered in Quill canvas
      expect(find.byType(AppTableVisualWidget), findsOneWidget);
      expect(find.text('Edit Data'), findsOneWidget);
      expect(find.text('Crop'), findsOneWidget);
      expect(find.text('Cotton'), findsOneWidget);

      // Verify visual box container rendered in Quill canvas
      expect(find.byType(AppBoxVisualWidget), findsOneWidget);
      expect(find.text('Edit Box'), findsOneWidget);
      expect(find.text('Key Highlights'), findsOneWidget);

      // Tap Edit Data button to verify dialog opens
      await tester.tap(find.text('Edit Data'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Table Data & Cells'), findsOneWidget);
      expect(find.text('+ Column'), findsOneWidget);
      expect(find.text('+ Row'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Table Data & Cells'), findsNothing);

      // Tap Edit Box button to verify dialog opens
      await tester.tap(find.text('Edit Box'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Box Container'), findsOneWidget);
      expect(find.text('Box Title'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Box Container'), findsNothing);
    });

    testWidgets('Editing table colors and theme preset in Edit Table Data dialog updates visual widget and exported HTML', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const initialHtml =
          '<table style="width: 100%; border-collapse: collapse; border: 1.5px solid #A7F3D0;">'
          '  <thead><tr style="background-color: #059669;"><th style="color: #FFFFFF;">Crop</th><th style="color: #FFFFFF;">Dosage</th></tr></thead>'
          '  <tbody><tr style="background-color: #FFFFFF;"><td style="color: #064E3B;">Cotton</td><td style="color: #064E3B;">2.5 ml</td></tr></tbody>'
          '</table>';

      final controller = TextEditingController(text: initialHtml);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Edit Data dialog
      await tester.tap(find.text('Edit Data'));
      await tester.pumpAndSettle();

      // Verify Theme presets exist
      expect(find.text('Agri Emerald'), findsOneWidget);
      expect(find.text('Corporate Navy'), findsOneWidget);
      expect(find.text('Modern Charcoal'), findsOneWidget);
      expect(find.text('Classic Gray'), findsOneWidget);
      expect(find.text('Warm Amber'), findsOneWidget);
      expect(find.text('Royal Indigo'), findsOneWidget);

      // Select Corporate Navy
      await tester.tap(find.text('Corporate Navy'));
      await tester.pumpAndSettle();

      // Apply changes
      await tester.tap(find.text('Apply Changes'));
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.text('Edit Table Data & Cells'), findsNothing);

      // Verify controller HTML has Corporate Navy background color #1E3A8A
      expect(controller.text, contains('#1E3A8A'));
    });

    testWidgets('Editing box colors, theme presets, and emoji in Edit Box dialog updates visual widget and exported HTML', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const initialHtml =
          '<div style="background-color: #ECFDF5; border: 1px solid #10B981; border-radius: 8px; padding: 16px;">'
          '  <h4 style="color: #065F46;">✨ Key Highlights</h4>'
          '  <p style="color: #047857;">Rapid translaminar absorption</p>'
          '</div>';

      final controller = TextEditingController(text: initialHtml);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Edit Box dialog
      await tester.tap(find.text('Edit Box'));
      await tester.pumpAndSettle();

      // Verify box presets exist
      expect(find.text('Agri Feature Emerald'), findsOneWidget);
      expect(find.text('Safety Caution Amber'), findsOneWidget);
      expect(find.text('Tech Specs Purple'), findsOneWidget);

      // Select Safety Caution Amber
      await tester.tap(find.text('Safety Caution Amber'));
      await tester.pumpAndSettle();

      // Apply changes
      await tester.tap(find.text('Apply Changes'));
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.text('Edit Box Container'), findsNothing);

      // Verify controller HTML has Safety Amber colors #FFFBEB and #F59E0B
      expect(controller.text, contains('#FFFBEB'));
      expect(controller.text, contains('#F59E0B'));
    });

    testWidgets('All 6 box templates render cleanly in Visual Mode and Storefront Preview without border errors and support interactive bullet controls', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Combine HTML from all 6 templates to verify multi-box round-tripping and Storefront Preview
      final combinedBoxesHtml = kNormalBoxTemplates.map((t) {
        return BoxEmbedData(
          type: t.id,
          title: t.title,
          content: t.defaultContent,
          bgColor: t.bgColor,
          borderColor: t.borderColor,
          titleColor: t.titleColor,
          contentColor: t.contentColor,
          iconEmoji: t.iconEmoji,
        ).toHtml();
      }).join('\n');

      final controller = TextEditingController(text: combinedBoxesHtml);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppHtmlEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 6 boxes rendered as AppBoxVisualWidget in Visual Mode
      expect(find.byType(AppBoxVisualWidget), findsNWidgets(6));
      expect(find.text('Standard Bordered Container'), findsOneWidget);
      expect(find.text('Feature Highlight Container'), findsOneWidget);
      expect(find.text('Info & Notice Callout'), findsOneWidget);
      expect(find.text('Caution & Precaution Alert'), findsOneWidget);
      expect(find.text('Specification Card Box'), findsOneWidget);
      expect(find.text('Crop Protection & Target Shield'), findsOneWidget);

      // Switch to Storefront Preview and ensure all 6 boxes render in HtmlWidget with zero border exceptions
      await tester.tap(find.text('👁 Preview'));
      await tester.pumpAndSettle();
      expect(find.byType(HtmlWidget), findsOneWidget);

      // Switch back to Visual Mode and test interactive bullet buttons on the first box
      await tester.tap(find.text('✎ Visual'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Box').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('box_add_bullet_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('box_bullet_all_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('box_clear_bullets_btn')), findsOneWidget);

      // Click Plain Text to strip bullets, then Bullet All Lines to re-bullet, then + Add Bullet
      await tester.tap(find.byKey(const ValueKey('box_clear_bullets_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('box_bullet_all_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('box_add_bullet_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply Changes'));
      await tester.pumpAndSettle();

      expect(controller.text, contains('<ul'));
      expect(controller.text, contains('<li'));
    });
  });
}
