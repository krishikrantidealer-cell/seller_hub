import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/presentation/dashboard/widgets/app_html_editor.dart';

void main() {
  test('sanitizePastedHtml strips ChatGPT wrapper attributes and keeps rich tags', () {
    const rawChatGptHtml = '''
      <div class="markdown prose" data-start="0">
        <h2 data-start="1" data-end="20"><span style="color: inherit;">Key Benefits</span></h2>
        <p data-start="21"><strong data-start="22">Fast Action:</strong> Works within <em>24 hours</em>.</p>
        <ul><li>Safe for crops</li></ul>
        <table><thead><tr><th>Crop</th><th>Dosage</th></tr></thead><tbody><tr><td>Cotton</td><td>2 ml/L</td></tr></tbody></table>
        <script>alert(1)</script>
      </div>
    ''';

    final cleaned = sanitizePastedHtml(rawChatGptHtml);
    expect(cleaned, contains('<h2>Key Benefits</h2>'));
    expect(cleaned, contains('<strong>Fast Action:</strong>'));
    expect(cleaned, contains('<em>24 hours</em>'));
    expect(cleaned, contains('<ul><li>Safe for crops</li></ul>'));
    expect(cleaned, contains('<table><thead><tr><th>Crop</th><th>Dosage</th></tr></thead>'));
    expect(cleaned, isNot(contains('<script>')));
    expect(cleaned, isNot(contains('data-start')));
    expect(cleaned, isNot(contains('<span')));
  });

  test('looksLikeRichMarkdown and markdownToHtml convert ChatGPT Markdown accurately', () {
    const chatGptMarkdown = '''
## Product Overview

**BioShield Pro** is a *broad-spectrum* bio-fungicide.

- Controls leaf spot and blight
- Safe for **organic farming**

1. Mix 2 ml per liter of water
2. Spray evenly on foliage

| Crop | Dosage |
| --- | --- |
| Paddy | 2 ml/L |
| Tomato | 1.5 ml/L |
''';

    expect(looksLikeRichMarkdown(chatGptMarkdown), isTrue);
    final html = markdownToHtml(chatGptMarkdown);
    expect(html, contains('<h2>Product Overview</h2>'));
    expect(html, contains('<strong>BioShield Pro</strong>'));
    expect(html, contains('<em>broad-spectrum</em>'));
    expect(html, contains('<ul>'));
    expect(html, contains('<li>Controls leaf spot and blight</li>'));
    expect(html, contains('<li>Safe for <strong>organic farming</strong></li>'));
    expect(html, contains('<ol>'));
    expect(html, contains('<li>Mix 2 ml per liter of water</li>'));
    expect(html, contains('<table><thead><tr><th>Crop</th><th>Dosage</th></tr></thead>'));
    expect(html, contains('<td>Paddy</td><td>2 ml/L</td>'));
  });

  testWidgets('AppHtmlEditor pastes ChatGPT Markdown as rich formatted HTML', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{
            'text': '## Overview\n\n**Fast** action for crops.\n\n- Item one\n- Item two',
          };
        }
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppHtmlEditor(
              controller: controller,
              label: 'Full Commercial Description',
              hintText: 'Enter description...',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final quillFinder = find.byType(QuillEditor);
    expect(quillFinder, findsOneWidget);
    final quillEditor = tester.widget<QuillEditor>(quillFinder);
    // ignore: experimental_member_use
    final handled = await quillEditor.controller.clipboardPaste();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(controller.text, contains('Overview'));
    expect(controller.text, contains('<strong>Fast</strong>'));
    expect(controller.text, contains('<li>Item one</li>'));
    expect(controller.text, contains('<li>Item two</li>'));
  });

  testWidgets('AppHtmlEditor upgrades direct plain-text insertion (Web Cmd+V path) from ChatGPT Markdown', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppHtmlEditor(
              controller: controller,
              label: 'Full Commercial Description',
              hintText: 'Enter description...',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const chatGptPaste = '''# Technology and Business Growth

Technology is transforming the way businesses operate.

## Quarterly Revenue Report

| Quarter | Revenue (₹ Lakhs) | Growth |
|---|---:|---:|
| Q1 | 10 | — |
| **Total** | **77** | — |

## Revenue Growth Chart

```text
Q1 | █████ 10
```

## Conclusion

The chart shows a consistent increase.''';

    final quillEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    quillEditor.controller.replaceText(
      0,
      0,
      chatGptPaste,
      const TextSelection.collapsed(offset: chatGptPaste.length),
    );
    await tester.pumpAndSettle();

    expect(controller.text, contains('<h1>Technology and Business Growth</h1>'));
    expect(controller.text, contains('<h2>Quarterly Revenue Report</h2>'));
    expect(controller.text, contains('<table'));
    expect(controller.text, contains('<h2>Conclusion</h2>'));
    expect(controller.text, isNot(contains('# Technology and Business Growth')));
  });
}
