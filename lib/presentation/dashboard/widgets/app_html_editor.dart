import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart' hide DefaultStyles;
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart' hide TableRow;

enum EditorMode {
  visual,
  source,
  preview,
}

class AppHtmlEditor extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? subtitle;
  final String hintText;
  final bool isRequired;
  final double minHeight;

  const AppHtmlEditor({
    super.key,
    required this.controller,
    this.label = 'Product Detail Description',
    this.subtitle,
    this.hintText = 'Write a comprehensive description with dosage, application, and benefits...',
    this.isRequired = false,
    this.minHeight = 260,
  });

  @override
  State<AppHtmlEditor> createState() => _AppHtmlEditorState();
}

Color _parseHexColor(String? hex, {Color fallback = const Color(0xFF1E293B)}) {
  if (hex == null || hex.trim().isEmpty) return fallback;
  var clean = hex.replaceAll('#', '').trim();
  if (clean.length == 3) {
    clean = '${clean[0]}${clean[0]}${clean[1]}${clean[1]}${clean[2]}${clean[2]}';
  }
  if (clean.length == 6) {
    clean = 'FF$clean';
  }
  final val = int.tryParse(clean, radix: 16);
  return val != null ? Color(val) : fallback;
}

const List<Map<String, dynamic>> kColorSwatches = [
  {'name': 'Agri Emerald', 'color': Color(0xFF059669), 'hex': '#059669'},
  {'name': 'Teal', 'color': Color(0xFF0D9488), 'hex': '#0D9488'},
  {'name': 'Navy Blue', 'color': Color(0xFF1E3A8A), 'hex': '#1E3A8A'},
  {'name': 'Royal Indigo', 'color': Color(0xFF6366F1), 'hex': '#6366F1'},
  {'name': 'Deep Purple', 'color': Color(0xFF7C3AED), 'hex': '#7C3AED'},
  {'name': 'Rose Red', 'color': Color(0xFFE11D48), 'hex': '#E11D48'},
  {'name': 'Amber Gold', 'color': Color(0xFFD97706), 'hex': '#D97706'},
  {'name': 'Modern Slate', 'color': Color(0xFF1E293B), 'hex': '#1E293B'},
  {'name': 'Pure White', 'color': Color(0xFFFFFFFF), 'hex': '#FFFFFF'},
  {'name': 'Mint Tint', 'color': Color(0xFFECFDF5), 'hex': '#ECFDF5'},
  {'name': 'Sky Tint', 'color': Color(0xFFEFF6FF), 'hex': '#EFF6FF'},
  {'name': 'Amber Tint', 'color': Color(0xFFFFFBEB), 'hex': '#FFFBEB'},
  {'name': 'Purple Tint', 'color': Color(0xFFF5F3FF), 'hex': '#F5F3FF'},
  {'name': 'Rose Tint', 'color': Color(0xFFFFF1F2), 'hex': '#FFF1F2'},
  {'name': 'Slate Tint', 'color': Color(0xFFF8FAFC), 'hex': '#F8FAFC'},
  {'name': 'Border Gray', 'color': Color(0xFFCBD5E1), 'hex': '#CBD5E1'},
];

void _showColorPickerModal(
  BuildContext context, {
  required String title,
  required String currentColorHex,
  required ValueChanged<String> onColorSelected,
}) {
  showDialog(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Dialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_rounded, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kColorSwatches.map((swatch) {
                    final color = swatch['color'] as Color;
                    final hex = swatch['hex'] as String;
                    final name = swatch['name'] as String;
                    final isSelected = hex.toLowerCase() == currentColorHex.toLowerCase();
                    return InkWell(
                      onTap: () {
                        onColorSelected(hex);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Tooltip(
                        message: '$name ($hex)',
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF059669)
                                  : (color == Colors.white ? const Color(0xFFCBD5E1) : Colors.transparent),
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class TableThemePreset {
  final String id;
  final String name;
  final Color previewColor;
  final String headerBgColor;
  final String headerTextColor;
  final String rowBgColor;
  final String altRowBgColor;
  final String rowTextColor;
  final String borderColor;

  const TableThemePreset({
    required this.id,
    required this.name,
    required this.previewColor,
    required this.headerBgColor,
    required this.headerTextColor,
    required this.rowBgColor,
    required this.altRowBgColor,
    required this.rowTextColor,
    required this.borderColor,
  });
}

const List<TableThemePreset> kTableThemePresets = [
  TableThemePreset(
    id: 'emerald',
    name: 'Agri Emerald',
    previewColor: Color(0xFF059669),
    headerBgColor: '#059669',
    headerTextColor: '#FFFFFF',
    rowBgColor: '#FFFFFF',
    altRowBgColor: '#ECFDF5',
    rowTextColor: '#064E3B',
    borderColor: '#A7F3D0',
  ),
  TableThemePreset(
    id: 'navy',
    name: 'Corporate Navy',
    previewColor: Color(0xFF1E3A8A),
    headerBgColor: '#1E3A8A',
    headerTextColor: '#FFFFFF',
    rowBgColor: '#FFFFFF',
    altRowBgColor: '#EFF6FF',
    rowTextColor: '#1E3A8A',
    borderColor: '#BFDBFE',
  ),
  TableThemePreset(
    id: 'slate',
    name: 'Modern Charcoal',
    previewColor: Color(0xFF1E293B),
    headerBgColor: '#1E293B',
    headerTextColor: '#FFFFFF',
    rowBgColor: '#FFFFFF',
    altRowBgColor: '#F1F5F9',
    rowTextColor: '#0F172A',
    borderColor: '#94A3B8',
  ),
  TableThemePreset(
    id: 'classic',
    name: 'Classic Gray',
    previewColor: Color(0xFF64748B),
    headerBgColor: '#E2E8F0',
    headerTextColor: '#0F172A',
    rowBgColor: '#FFFFFF',
    altRowBgColor: '#F8FAFC',
    rowTextColor: '#334155',
    borderColor: '#CBD5E1',
  ),
  TableThemePreset(
    id: 'amber',
    name: 'Warm Amber',
    previewColor: Color(0xFFD97706),
    headerBgColor: '#D97706',
    headerTextColor: '#FFFFFF',
    rowBgColor: '#FFFFFF',
    altRowBgColor: '#FFFBEB',
    rowTextColor: '#78350F',
    borderColor: '#FDE68A',
  ),
  TableThemePreset(
    id: 'purple',
    name: 'Royal Indigo',
    previewColor: Color(0xFF6366F1),
    headerBgColor: '#6366F1',
    headerTextColor: '#FFFFFF',
    rowBgColor: '#FFFFFF',
    altRowBgColor: '#EEF2FF',
    rowTextColor: '#312E81',
    borderColor: '#C7D2FE',
  ),
];

class BoxThemePreset {
  final String id;
  final String name;
  final Color previewColor;
  final String bgColor;
  final String borderColor;
  final String titleColor;
  final String contentColor;
  final String iconEmoji;

  const BoxThemePreset({
    required this.id,
    required this.name,
    required this.previewColor,
    required this.bgColor,
    required this.borderColor,
    required this.titleColor,
    required this.contentColor,
    required this.iconEmoji,
  });
}

const List<BoxThemePreset> kBoxThemePresets = [
  BoxThemePreset(
    id: 'box_standard',
    name: 'Standard Clean Slate',
    previewColor: Color(0xFF64748B),
    bgColor: '#FFFFFF',
    borderColor: '#CBD5E1',
    titleColor: '#1E293B',
    contentColor: '#475569',
    iconEmoji: '📦',
  ),
  BoxThemePreset(
    id: 'box_highlight',
    name: 'Agri Feature Emerald',
    previewColor: Color(0xFF059669),
    bgColor: '#ECFDF5',
    borderColor: '#10B981',
    titleColor: '#065F46',
    contentColor: '#047857',
    iconEmoji: '✨',
  ),
  BoxThemePreset(
    id: 'box_info',
    name: 'Info Notice Sky',
    previewColor: Color(0xFF2563EB),
    bgColor: '#EFF6FF',
    borderColor: '#3B82F6',
    titleColor: '#1E40AF',
    contentColor: '#1E3A8A',
    iconEmoji: '💡',
  ),
  BoxThemePreset(
    id: 'box_warning',
    name: 'Safety Caution Amber',
    previewColor: Color(0xFFD97706),
    bgColor: '#FFFBEB',
    borderColor: '#F59E0B',
    titleColor: '#92400E',
    contentColor: '#78350F',
    iconEmoji: '⚠️',
  ),
  BoxThemePreset(
    id: 'box_card',
    name: 'Tech Specs Purple',
    previewColor: Color(0xFF7C3AED),
    bgColor: '#F5F3FF',
    borderColor: '#7C3AED',
    titleColor: '#4C1D95',
    contentColor: '#475569',
    iconEmoji: '📋',
  ),
  BoxThemePreset(
    id: 'box_rose',
    name: 'Protection Rose',
    previewColor: Color(0xFFE11D48),
    bgColor: '#FFF1F2',
    borderColor: '#E11D48',
    titleColor: '#9F1239',
    contentColor: '#881337',
    iconEmoji: '🛡️',
  ),
];

class TableEmbedData {
  final List<String> headers;
  final List<List<String>> rows;
  final String style;
  final String headerBgColor;
  final String headerTextColor;
  final String rowBgColor;
  final String altRowBgColor;
  final String rowTextColor;
  final String borderColor;

  const TableEmbedData({
    required this.headers,
    required this.rows,
    this.style = 'emerald',
    this.headerBgColor = '#059669',
    this.headerTextColor = '#FFFFFF',
    this.rowBgColor = '#FFFFFF',
    this.altRowBgColor = '#ECFDF5',
    this.rowTextColor = '#064E3B',
    this.borderColor = '#A7F3D0',
  });

  Map<String, dynamic> toJson() => {
        'headers': headers,
        'rows': rows,
        'style': style,
        'headerBgColor': headerBgColor,
        'headerTextColor': headerTextColor,
        'rowBgColor': rowBgColor,
        'altRowBgColor': altRowBgColor,
        'rowTextColor': rowTextColor,
        'borderColor': borderColor,
      };

  String toJsonString() => jsonEncode(toJson());

  factory TableEmbedData.fromJson(Map<String, dynamic> json) {
    return TableEmbedData(
      headers: (json['headers'] as List? ?? []).map((e) => e.toString()).toList(),
      rows: (json['rows'] as List? ?? [])
          .map((r) => (r as List).map((c) => c.toString()).toList())
          .toList(),
      style: json['style']?.toString() ?? 'emerald',
      headerBgColor: json['headerBgColor']?.toString() ?? '#059669',
      headerTextColor: json['headerTextColor']?.toString() ?? '#FFFFFF',
      rowBgColor: json['rowBgColor']?.toString() ?? '#FFFFFF',
      altRowBgColor: json['altRowBgColor']?.toString() ?? '#ECFDF5',
      rowTextColor: json['rowTextColor']?.toString() ?? '#064E3B',
      borderColor: json['borderColor']?.toString() ?? '#A7F3D0',
    );
  }

  factory TableEmbedData.fromJsonString(String str) {
    try {
      final decoded = jsonDecode(str);
      if (decoded is Map<String, dynamic>) {
        return TableEmbedData.fromJson(decoded);
      }
    } catch (_) {}
    return const TableEmbedData(headers: ['Col 1', 'Col 2'], rows: [['', '']]);
  }

  String toHtml() {
    final buf = StringBuffer();
    buf.writeln('<table style="width: 100%; border-collapse: collapse; margin: 16px 0; border: 1.5px solid $borderColor;">');
    buf.writeln('  <thead>');
    buf.writeln('    <tr style="background-color: $headerBgColor;">');
    for (final h in headers) {
      buf.writeln('      <th style="padding: 10px 14px; border: 1px solid $borderColor; font-weight: 700; font-size: 13px; text-align: left; color: $headerTextColor;">$h</th>');
    }
    buf.writeln('    </tr>');
    buf.writeln('  </thead>');
    buf.writeln('  <tbody>');
    for (int r = 0; r < rows.length; r++) {
      final rowBg = r.isEven ? rowBgColor : altRowBgColor;
      buf.writeln('    <tr style="background-color: $rowBg;">');
      for (final c in rows[r]) {
        buf.writeln('      <td style="padding: 9px 14px; border: 1px solid $borderColor; font-size: 13px; color: $rowTextColor;">$c</td>');
      }
      buf.writeln('    </tr>');
    }
    buf.writeln('  </tbody>');
    buf.writeln('</table>');
    return buf.toString();
  }

  static TableEmbedData? fromTableElement(dom.Element table) {
    final thElements = table.querySelectorAll('th');
    final headers = thElements.isNotEmpty
        ? thElements.map((th) => th.text.trim()).toList()
        : <String>[];
    final trElements = table.querySelectorAll('tr');
    final rows = <List<String>>[];
    for (final tr in trElements) {
      final tds = tr.querySelectorAll('td');
      if (tds.isNotEmpty) {
        rows.add(tds.map((td) => td.text.trim()).toList());
      }
    }
    if (headers.isEmpty && rows.isNotEmpty) {
      headers.addAll(List.generate(rows.first.length, (i) => 'Col ${i + 1}'));
    }
    if (headers.isEmpty) return null;

    String headerBg = '#059669';
    String headerText = '#FFFFFF';
    String border = '#A7F3D0';
    String rowBg = '#FFFFFF';
    String altRowBg = '#ECFDF5';
    String rowText = '#064E3B';

    final tableStyle = (table.attributes['style'] ?? '').toLowerCase();
    final borderMatch = RegExp(r'border(?:-[a-z]+)?:\s*[^;]*?(#[0-9a-fA-F]{3,8})').firstMatch(tableStyle);
    if (borderMatch != null) border = borderMatch.group(1)!;

    if (thElements.isNotEmpty) {
      final thStyle = (thElements.first.attributes['style'] ?? '').toLowerCase();
      final bgMatch = RegExp(r'background-color:\s*(#[0-9a-fA-F]{3,8})').firstMatch(thStyle);
      if (bgMatch != null) headerBg = bgMatch.group(1)!;
      final colorMatch = RegExp(r'(?:^|;\s*)color:\s*(#[0-9a-fA-F]{3,8})').firstMatch(thStyle);
      if (colorMatch != null) headerText = colorMatch.group(1)!;
    }

    if (rows.isNotEmpty) {
      final firstTr = trElements.firstWhere((tr) => tr.querySelectorAll('td').isNotEmpty, orElse: () => trElements.first);
      final firstTd = firstTr.querySelector('td');
      if (firstTd != null) {
        final tdStyle = (firstTd.attributes['style'] ?? '').toLowerCase();
        final textMatch = RegExp(r'(?:^|;\s*)color:\s*(#[0-9a-fA-F]{3,8})').firstMatch(tdStyle);
        if (textMatch != null) rowText = textMatch.group(1)!;
      }
    }

    return TableEmbedData(
      headers: headers,
      rows: rows,
      headerBgColor: headerBg,
      headerTextColor: headerText,
      rowBgColor: rowBg,
      altRowBgColor: altRowBg,
      rowTextColor: rowText,
      borderColor: border,
    );
  }

  static TableEmbedData? fromMarkdown(String text) {
    final lines = text.trim().split('\n').where((l) => l.trim().startsWith('|')).toList();
    if (lines.length < 2) return null;
    final headerCells = lines[0]
        .split('|')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (headerCells.isEmpty) return null;
    int startRow = 1;
    if (lines.length > 1 && lines[1].contains('---')) {
      startRow = 2;
    }
    final rows = <List<String>>[];
    for (int i = startRow; i < lines.length; i++) {
      final cells = lines[i]
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (cells.isNotEmpty) {
        while (cells.length < headerCells.length) {
          cells.add('');
        }
        rows.add(cells.take(headerCells.length).toList());
      }
    }
    return TableEmbedData(headers: headerCells, rows: rows);
  }
}

class BoxEmbedData {
  final String type;
  final String title;
  final String content;
  final String bgColor;
  final String borderColor;
  final String titleColor;
  final String contentColor;
  final String iconEmoji;

  const BoxEmbedData({
    required this.type,
    required this.title,
    required this.content,
    this.bgColor = '#ECFDF5',
    this.borderColor = '#10B981',
    this.titleColor = '#065F46',
    this.contentColor = '#047857',
    this.iconEmoji = '✨',
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'content': content,
        'bgColor': bgColor,
        'borderColor': borderColor,
        'titleColor': titleColor,
        'contentColor': contentColor,
        'iconEmoji': iconEmoji,
      };

  String toJsonString() => jsonEncode(toJson());

  factory BoxEmbedData.fromJson(Map<String, dynamic> json) {
    return BoxEmbedData(
      type: json['type']?.toString() ?? 'box_highlight',
      title: json['title']?.toString() ?? 'Title',
      content: json['content']?.toString() ?? '',
      bgColor: json['bgColor']?.toString() ?? '#ECFDF5',
      borderColor: json['borderColor']?.toString() ?? '#10B981',
      titleColor: json['titleColor']?.toString() ?? '#065F46',
      contentColor: json['contentColor']?.toString() ?? '#047857',
      iconEmoji: json['iconEmoji']?.toString() ?? '✨',
    );
  }

  factory BoxEmbedData.fromJsonString(String str) {
    try {
      final decoded = jsonDecode(str);
      if (decoded is Map<String, dynamic>) {
        return BoxEmbedData.fromJson(decoded);
      }
    } catch (_) {}
    return const BoxEmbedData(type: 'box_standard', title: 'Box', content: '');
  }

  String toHtml() {
    final iconPart = iconEmoji.isNotEmpty ? '$iconEmoji ' : '';
    return '<div style="background-color: $bgColor; border: 1px solid $borderColor; border-radius: 8px; padding: 16px; margin: 14px 0;">\n'
        '  <h4 style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: $titleColor;">$iconPart$title</h4>\n'
        '  ${_formatContentToHtml(content, contentColor)}\n'
        '</div>';
  }

  static String _formatContentToHtml(String content, String contentColor) {
    final lines = content.split('\n');
    final buf = StringBuffer();
    bool inList = false;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
        if (!inList) {
          buf.write('<ul style="margin: 0 0 6px 0; padding-left: 20px; font-size: 13.5px; color: $contentColor; line-height: 1.6;">');
          inList = true;
        }
        final itemText = line.substring(1).trim();
        buf.write('<li style="margin: 2px 0; color: $contentColor;">$itemText</li>');
      } else {
        if (inList) {
          buf.write('</ul>');
          inList = false;
        }
        buf.write('<p style="margin: 0 0 6px 0; font-size: 13.5px; color: $contentColor; line-height: 1.6;">$line</p>');
      }
    }
    if (inList) buf.write('</ul>');
    return buf.toString();
  }

  static BoxEmbedData? fromBracketTag(String tagType, String title, String body) {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    switch (tagType.toUpperCase()) {
      case 'HIGHLIGHT':
        return BoxEmbedData(
          type: 'box_highlight',
          title: cleanTitle,
          content: cleanBody,
          bgColor: '#ECFDF5',
          borderColor: '#10B981',
          titleColor: '#065F46',
          contentColor: '#047857',
          iconEmoji: '✨',
        );
      case 'NOTE':
        return BoxEmbedData(
          type: 'box_info',
          title: cleanTitle,
          content: cleanBody,
          bgColor: '#EFF6FF',
          borderColor: '#3B82F6',
          titleColor: '#1E40AF',
          contentColor: '#1E3A8A',
          iconEmoji: '💡',
        );
      case 'WARNING':
        return BoxEmbedData(
          type: 'box_warning',
          title: cleanTitle,
          content: cleanBody,
          bgColor: '#FFFBEB',
          borderColor: '#F59E0B',
          titleColor: '#92400E',
          contentColor: '#78350F',
          iconEmoji: '⚠️',
        );
      case 'CARD':
        return BoxEmbedData(
          type: 'box_card',
          title: cleanTitle,
          content: cleanBody,
          bgColor: '#F5F3FF',
          borderColor: '#7C3AED',
          titleColor: '#4C1D95',
          contentColor: '#475569',
          iconEmoji: '📋',
        );
      case 'BOX':
      default:
        return BoxEmbedData(
          type: 'box_standard',
          title: cleanTitle,
          content: cleanBody,
          bgColor: '#FFFFFF',
          borderColor: '#CBD5E1',
          titleColor: '#1E293B',
          contentColor: '#475569',
          iconEmoji: '📦',
        );
    }
  }

  static BoxEmbedData? fromDivElement(dom.Element div, String style) {
    final lowerStyle = style.toLowerCase();
    if (!lowerStyle.contains('border') && !lowerStyle.contains('background-color')) {
      return null;
    }

    final h4 = div.querySelector('h4, h3, h2, h5, h6, strong');
    final rawTitle = h4 != null ? h4.text.trim() : 'Section Title';
    final h4Style = (h4?.attributes['style'] ?? '').toLowerCase();
    h4?.remove();

    final contentLines = <String>[];
    String? extractedContentColor;

    for (final child in div.children) {
      final tag = child.localName?.toLowerCase() ?? '';
      final childStyle = (child.attributes['style'] ?? '').toLowerCase();
      if (extractedContentColor == null) {
        final cMatch = RegExp(r'(?:^|;\s*)color:\s*(#[0-9a-fA-F]{3,8})').firstMatch(childStyle);
        if (cMatch != null) extractedContentColor = cMatch.group(1)!.toUpperCase();
      }
      if (tag == 'ul' || tag == 'ol') {
        for (final li in child.querySelectorAll('li')) {
          final liText = li.text.trim();
          if (liText.isNotEmpty) {
            contentLines.add(liText.startsWith('•') ? liText : '• $liText');
          }
        }
      } else if (tag == 'p' || tag == 'div') {
        final innerLis = child.querySelectorAll('li');
        if (innerLis.isNotEmpty) {
          for (final li in innerLis) {
            final liText = li.text.trim();
            if (liText.isNotEmpty) {
              contentLines.add(liText.startsWith('•') ? liText : '• $liText');
            }
          }
        } else {
          final pText = child.text.trim();
          if (pText.isNotEmpty) contentLines.add(pText);
        }
      }
    }

    final content = contentLines.isNotEmpty ? contentLines.join('\n') : div.text.trim();

    String iconEmoji = '';
    String title = rawTitle;
    const knownEmojis = ['✨', '🌿', '💡', '⚠️', '📋', '📦', '🛡️', '🎯', '🔬'];
    for (final e in knownEmojis) {
      if (rawTitle.startsWith(e)) {
        iconEmoji = e;
        title = rawTitle.substring(e.length).trim();
        break;
      }
    }

    String bgColor = '#ECFDF5';
    String borderColor = '#10B981';
    String titleColor = '#065F46';
    String contentColor = '#047857';

    final bgMatch = RegExp(r'background-color:\s*(#[0-9a-fA-F]{3,8})').firstMatch(lowerStyle);
    if (bgMatch != null) bgColor = bgMatch.group(1)!.toUpperCase();

    final borderMatches = RegExp(r'border(?:-[a-z]+)?:\s*[^;]*?(#[0-9a-fA-F]{3,8})').allMatches(lowerStyle);
    if (borderMatches.isNotEmpty) {
      borderColor = borderMatches.last.group(1)!.toUpperCase();
    }

    String boxType = 'box_highlight';
    if (lowerStyle.contains('#eff6ff') || lowerStyle.contains('#3b82f6')) {
      boxType = 'box_info';
      titleColor = '#1E40AF';
      contentColor = '#1E3A8A';
      if (iconEmoji.isEmpty) iconEmoji = '💡';
    } else if (lowerStyle.contains('#fffbeb') || lowerStyle.contains('#f59e0b')) {
      boxType = 'box_warning';
      titleColor = '#92400E';
      contentColor = '#78350F';
      if (iconEmoji.isEmpty) iconEmoji = '⚠️';
    } else if (lowerStyle.contains('#7c3aed') || lowerStyle.contains('#f5f3ff')) {
      boxType = 'box_card';
      titleColor = '#4C1D95';
      contentColor = '#475569';
      if (iconEmoji.isEmpty) iconEmoji = '📋';
    } else if (lowerStyle.contains('#e11d48') || lowerStyle.contains('#fff1f2')) {
      boxType = 'box_rose';
      titleColor = '#9F1239';
      contentColor = '#881337';
      if (iconEmoji.isEmpty) iconEmoji = '🛡️';
    } else if (lowerStyle.contains('#cbd5e1') || lowerStyle.contains('#ffffff')) {
      boxType = 'box_standard';
      titleColor = '#1E293B';
      contentColor = '#475569';
      if (iconEmoji.isEmpty) iconEmoji = '📦';
    }

    final h4ColorMatch = RegExp(r'(?:^|;\s*)color:\s*(#[0-9a-fA-F]{3,8})').firstMatch(h4Style);
    if (h4ColorMatch != null) {
      titleColor = h4ColorMatch.group(1)!.toUpperCase();
    }
    if (extractedContentColor != null) {
      contentColor = extractedContentColor;
    }

    return BoxEmbedData(
      type: boxType,
      title: title,
      content: content,
      bgColor: bgColor,
      borderColor: borderColor,
      titleColor: titleColor,
      contentColor: contentColor,
      iconEmoji: iconEmoji,
    );
  }
}

class AppTableVisualWidget extends StatelessWidget {
  final TableEmbedData tableData;
  final EmbedContext embedContext;
  final bool isDark;

  const AppTableVisualWidget({
    super.key,
    required this.tableData,
    required this.embedContext,
    required this.isDark,
  });

  void _openEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditTableDataDialog(
        initialData: tableData,
        isDark: isDark,
        onSave: (newData) {
          final offset = embedContext.node.documentOffset;
          final len = embedContext.node.length;
          embedContext.controller.document.delete(offset, len);
          embedContext.controller.document.insert(
            offset,
            BlockEmbed('app_table', newData.toJsonString()),
          );
        },
      ),
    );
  }

  void _deleteTable() {
    final offset = embedContext.node.documentOffset;
    final len = embedContext.node.length;
    embedContext.controller.replaceText(offset, len, '', null);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF131D33) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    final headerBg = _parseHexColor(tableData.headerBgColor, fallback: const Color(0xFF059669));
    final headerTextColor = _parseHexColor(tableData.headerTextColor, fallback: Colors.white);
    final rowBg = _parseHexColor(tableData.rowBgColor, fallback: Colors.white);
    final altRowBg = _parseHexColor(tableData.altRowBgColor, fallback: const Color(0xFFECFDF5));
    final rowTextColor = _parseHexColor(tableData.rowTextColor, fallback: const Color(0xFF064E3B));
    final tableBorderColor = _parseHexColor(tableData.borderColor, fallback: borderColor);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: headerBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
                const Icon(Icons.table_chart_rounded, size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Text(
                  'Standard Table (${tableData.headers.length} cols × ${tableData.rows.length + 1} rows)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _openEditDialog(context),
                  icon: const Icon(Icons.palette_outlined, size: 14),
                  label: Text(
                    'Edit Data',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 28),
                    side: BorderSide(color: borderColor),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                  tooltip: 'Delete Table',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: _deleteTable,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(140),
                border: TableBorder.all(
                  color: tableBorderColor,
                  width: 1.2,
                  borderRadius: BorderRadius.circular(4),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: headerBg,
                    ),
                    children: tableData.headers.map((h) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(
                          h,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: headerTextColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  ...tableData.rows.asMap().entries.map((entry) {
                    final rIndex = entry.key;
                    final row = entry.value;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: rIndex.isEven ? rowBg : altRowBg,
                      ),
                      children: List.generate(tableData.headers.length, (cIndex) {
                        final val = cIndex < row.length ? row[cIndex] : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(
                            val,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: rowTextColor,
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditTableDataDialog extends StatefulWidget {
  final TableEmbedData initialData;
  final bool isDark;
  final ValueChanged<TableEmbedData> onSave;

  const _EditTableDataDialog({
    required this.initialData,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_EditTableDataDialog> createState() => _EditTableDataDialogState();
}

class _EditTableDataDialogState extends State<_EditTableDataDialog> {
  late List<TextEditingController> _headerControllers;
  late List<List<TextEditingController>> _rowControllers;

  late String _headerBgColor;
  late String _headerTextColor;
  late String _rowBgColor;
  late String _altRowBgColor;
  late String _rowTextColor;
  late String _borderColor;
  late String _activePresetId;

  @override
  void initState() {
    super.initState();
    _headerControllers = widget.initialData.headers
        .map((h) => TextEditingController(text: h))
        .toList();
    _rowControllers = widget.initialData.rows
        .map((r) => r.map((c) => TextEditingController(text: c)).toList())
        .toList();

    _headerBgColor = widget.initialData.headerBgColor;
    _headerTextColor = widget.initialData.headerTextColor;
    _rowBgColor = widget.initialData.rowBgColor;
    _altRowBgColor = widget.initialData.altRowBgColor;
    _rowTextColor = widget.initialData.rowTextColor;
    _borderColor = widget.initialData.borderColor;
    _activePresetId = widget.initialData.style;
  }

  @override
  void dispose() {
    for (final c in _headerControllers) {
      c.dispose();
    }
    for (final r in _rowControllers) {
      for (final c in r) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _applyThemePreset(TableThemePreset preset) {
    setState(() {
      _activePresetId = preset.id;
      _headerBgColor = preset.headerBgColor;
      _headerTextColor = preset.headerTextColor;
      _rowBgColor = preset.rowBgColor;
      _altRowBgColor = preset.altRowBgColor;
      _rowTextColor = preset.rowTextColor;
      _borderColor = preset.borderColor;
    });
  }

  void _addRow() {
    setState(() {
      _rowControllers.add(
        List.generate(
          _headerControllers.length,
          (i) => TextEditingController(text: ''),
        ),
      );
    });
  }

  void _removeRow(int index) {
    if (_rowControllers.length > 1) {
      setState(() {
        final removed = _rowControllers.removeAt(index);
        for (final c in removed) {
          c.dispose();
        }
      });
    }
  }

  void _addColumn() {
    setState(() {
      final colNum = _headerControllers.length + 1;
      _headerControllers.add(TextEditingController(text: 'Column $colNum'));
      for (final r in _rowControllers) {
        r.add(TextEditingController(text: ''));
      }
    });
  }

  void _removeColumn(int index) {
    if (_headerControllers.length > 2) {
      setState(() {
        _headerControllers.removeAt(index).dispose();
        for (final r in _rowControllers) {
          if (index < r.length) {
            r.removeAt(index).dispose();
          }
        }
      });
    }
  }

  void _save() {
    final headers = _headerControllers.map((c) => c.text.trim()).toList();
    final rows = _rowControllers
        .map((r) => r.map((c) => c.text.trim()).toList())
        .toList();
    widget.onSave(
      TableEmbedData(
        headers: headers,
        rows: rows,
        style: _activePresetId,
        headerBgColor: _headerBgColor,
        headerTextColor: _headerTextColor,
        rowBgColor: _rowBgColor,
        altRowBgColor: _altRowBgColor,
        rowTextColor: _rowTextColor,
        borderColor: _borderColor,
      ),
    );
    Navigator.of(context).pop();
  }

  Widget _buildColorControlPill({
    required String label,
    required String hexColor,
    required ValueChanged<String> onColorChanged,
    required bool isDark,
    required Color borderColor,
  }) {
    final color = _parseHexColor(hexColor);
    return InkWell(
      onTap: () {
        _showColorPickerModal(
          context,
          title: 'Select $label',
          currentColorHex: hexColor,
          onColorSelected: onColorChanged,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color == Colors.white ? const Color(0xFF94A3B8) : Colors.white,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final currentHeaderBg = _parseHexColor(_headerBgColor);
    final currentHeaderTextColor = _parseHexColor(_headerTextColor);
    final currentRowBg = _parseHexColor(_rowBgColor);
    final currentAltRowBg = _parseHexColor(_altRowBgColor);
    final currentRowTextColor = _parseHexColor(_rowTextColor);
    final currentTableBorder = _parseHexColor(_borderColor);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
                color: isDark ? const Color(0xFF131D33) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.table_chart_rounded, size: 18, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Edit Table Data & Cells',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: currentHeaderBg.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: currentHeaderBg.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${_headerControllers.length} cols × ${_rowControllers.length + 1} rows',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: currentHeaderBg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _addColumn,
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('+ Column'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 30),
                      side: BorderSide(color: borderColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('+ Row'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 30),
                      side: BorderSide(color: borderColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Color Themes & Swatches Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Theme Presets:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: kTableThemePresets.map((preset) {
                              final isSelected = _activePresetId == preset.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => _applyThemePreset(preset),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? preset.previewColor.withValues(alpha: 0.15)
                                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected ? preset.previewColor : borderColor,
                                        width: isSelected ? 1.8 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 11,
                                          height: 11,
                                          decoration: BoxDecoration(
                                            color: preset.previewColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          preset.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? preset.previewColor : textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          'Customize Colors:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildColorControlPill(
                          label: 'Header Fill',
                          hexColor: _headerBgColor,
                          onColorChanged: (c) => setState(() => _headerBgColor = c),
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                        const SizedBox(width: 8),
                        _buildColorControlPill(
                          label: 'Header Text',
                          hexColor: _headerTextColor,
                          onColorChanged: (c) => setState(() => _headerTextColor = c),
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                        const SizedBox(width: 8),
                        _buildColorControlPill(
                          label: 'Zebra Tint',
                          hexColor: _altRowBgColor,
                          onColorChanged: (c) => setState(() => _altRowBgColor = c),
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                        const SizedBox(width: 8),
                        _buildColorControlPill(
                          label: 'Border Color',
                          hexColor: _borderColor,
                          onColorChanged: (c) => setState(() => _borderColor = c),
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Connected Spreadsheet Table Grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: currentTableBorder, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Container(
                              decoration: BoxDecoration(
                                color: currentHeaderBg,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(right: BorderSide(color: currentTableBorder)),
                                    ),
                                    child: Text(
                                      '#',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: currentHeaderTextColor,
                                      ),
                                    ),
                                  ),
                                  ..._headerControllers.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final ctrl = entry.value;
                                    return Container(
                                      width: 170,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: idx < _headerControllers.length - 1
                                              ? BorderSide(color: currentTableBorder)
                                              : BorderSide.none,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: ctrl,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                filled: true,
                                                fillColor: Colors.black.withValues(alpha: 0.12),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(5),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: currentHeaderTextColor,
                                              ),
                                            ),
                                          ),
                                          if (_headerControllers.length > 2)
                                            IconButton(
                                              icon: Icon(
                                                Icons.close_rounded,
                                                size: 15,
                                                color: currentHeaderTextColor.withValues(alpha: 0.8),
                                              ),
                                              tooltip: 'Delete Column',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                              onPressed: () => _removeColumn(idx),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            // Data Rows
                            ..._rowControllers.asMap().entries.map((rEntry) {
                              final rIdx = rEntry.key;
                              final rowCtrls = rEntry.value;
                              final isEvenRow = rIdx.isEven;
                              final rowBg = isEvenRow ? currentRowBg : currentAltRowBg;

                              return Container(
                                decoration: BoxDecoration(
                                  color: rowBg,
                                  border: Border(
                                    top: BorderSide(color: currentTableBorder),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border(right: BorderSide(color: currentTableBorder)),
                                      ),
                                      child: _rowControllers.length > 1
                                          ? IconButton(
                                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 15, color: Colors.redAccent),
                                              tooltip: 'Remove Row',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                              onPressed: () => _removeRow(rIdx),
                                            )
                                          : Text(
                                              '${rIdx + 1}',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary),
                                            ),
                                    ),
                                    ...rowCtrls.asMap().entries.map((cEntry) {
                                      final cIdx = cEntry.key;
                                      final ctrl = cEntry.value;
                                      return Container(
                                        width: 170,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: cIdx < rowCtrls.length - 1
                                                ? BorderSide(color: currentTableBorder)
                                                : BorderSide.none,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        child: TextField(
                                          controller: ctrl,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            filled: true,
                                            fillColor: isDark
                                                ? Colors.black.withValues(alpha: 0.2)
                                                : Colors.black.withValues(alpha: 0.03),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5),
                                              borderSide: BorderSide(color: borderColor.withValues(alpha: 0.4)),
                                            ),
                                          ),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: currentRowTextColor,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('+ Add Row Below'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _addColumn,
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('+ Add Column to Right'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tip: Use quick presets or customize borders & zebra striping above.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Apply Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildFormattedBoxContent(
  String content,
  Color contentColor,
  Color bulletColor,
) {
  final rawLines = content.split('\n');
  final nonEmpty = rawLines.where((l) => l.trim().isNotEmpty).toList();
  if (nonEmpty.isEmpty) {
    return Text(
      'Write description or notes here...',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        height: 1.5,
        color: contentColor.withValues(alpha: 0.7),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: nonEmpty.map((rawLine) {
      final line = rawLine.trim();
      final isBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('*');
      if (isBullet) {
        final itemText = line.substring(1).trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 7, right: 8),
                decoration: BoxDecoration(
                  color: bulletColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  itemText.isNotEmpty ? itemText : ' ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.5,
                    color: contentColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          line,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.5,
            color: contentColor,
          ),
        ),
      );
    }).toList(),
  );
}

class AppBoxVisualWidget extends StatelessWidget {
  final BoxEmbedData boxData;
  final EmbedContext embedContext;
  final bool isDark;

  const AppBoxVisualWidget({
    super.key,
    required this.boxData,
    required this.embedContext,
    required this.isDark,
  });

  void _openEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditBoxDataDialog(
        initialData: boxData,
        isDark: isDark,
        onSave: (newData) {
          final offset = embedContext.node.documentOffset;
          final len = embedContext.node.length;
          embedContext.controller.document.delete(offset, len);
          embedContext.controller.document.insert(
            offset,
            BlockEmbed('app_box', newData.toJsonString()),
          );
        },
      ),
    );
  }

  void _deleteBox() {
    final offset = embedContext.node.documentOffset;
    final len = embedContext.node.length;
    embedContext.controller.replaceText(offset, len, '', null);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final boxBg = _parseHexColor(boxData.bgColor, fallback: const Color(0xFFECFDF5));
    final boxBorder = _parseHexColor(boxData.borderColor, fallback: const Color(0xFF10B981));
    final titleColor = _parseHexColor(boxData.titleColor, fallback: const Color(0xFF065F46));
    final contentColor = _parseHexColor(boxData.contentColor, fallback: const Color(0xFF047857));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: boxBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: boxBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (boxData.iconEmoji.isNotEmpty) ...[
                Text(boxData.iconEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  boxData.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openEditDialog(context),
                icon: const Icon(Icons.palette_outlined, size: 14),
                label: Text(
                  'Edit Box',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 28),
                  side: BorderSide(color: borderColor),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                tooltip: 'Delete Box',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _deleteBox,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFormattedBoxContent(boxData.content, contentColor, boxBorder),
        ],
      ),
    );
  }
}

class _EditBoxDataDialog extends StatefulWidget {
  final BoxEmbedData initialData;
  final bool isDark;
  final ValueChanged<BoxEmbedData> onSave;

  const _EditBoxDataDialog({
    required this.initialData,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_EditBoxDataDialog> createState() => _EditBoxDataDialogState();
}

class _EditBoxDataDialogState extends State<_EditBoxDataDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  String _previousContentText = '';

  late String _bgColor;
  late String _borderColor;
  late String _titleColor;
  late String _contentColor;
  late String _iconEmoji;
  String _activePresetId = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData.title);
    _contentController = TextEditingController(text: widget.initialData.content);
    _previousContentText = widget.initialData.content;

    _bgColor = widget.initialData.bgColor;
    _borderColor = widget.initialData.borderColor;
    _titleColor = widget.initialData.titleColor;
    _contentColor = widget.initialData.contentColor;
    _iconEmoji = widget.initialData.iconEmoji;
    _activePresetId = widget.initialData.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _applyBoxPreset(BoxThemePreset preset) {
    setState(() {
      _activePresetId = preset.id;
      _bgColor = preset.bgColor;
      _borderColor = preset.borderColor;
      _titleColor = preset.titleColor;
      _contentColor = preset.contentColor;
      _iconEmoji = preset.iconEmoji;
    });
  }

  void _insertBulletPointAtCursor() {
    final text = _contentController.text;
    final sel = _contentController.selection;
    setState(() {
      if (text.trim().isEmpty) {
        _contentController.text = '• ';
        _contentController.selection = const TextSelection.collapsed(offset: 2);
      } else if (!sel.isValid || sel.baseOffset < 0) {
        final next = text.endsWith('\n') ? '$text• ' : '$text\n• ';
        _contentController.text = next;
        _contentController.selection = TextSelection.collapsed(offset: next.length);
      } else {
        final cursor = sel.baseOffset.clamp(0, text.length);
        final lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0) + 1;
        final currentLinePrefix = text.substring(lineStart, cursor);
        if (currentLinePrefix.trim().isEmpty && !text.substring(lineStart).trimLeft().startsWith('•')) {
          final next = '${text.substring(0, lineStart)}• ${text.substring(lineStart)}';
          _contentController.text = next;
          _contentController.selection = TextSelection.collapsed(offset: cursor + 2);
        } else {
          final next = '${text.substring(0, cursor)}\n• ${text.substring(cursor)}';
          _contentController.text = next;
          _contentController.selection = TextSelection.collapsed(offset: cursor + 3);
        }
      }
      _previousContentText = _contentController.text;
    });
  }

  void _formatAllLinesAsBullets() {
    final lines = _contentController.text.split('\n');
    final converted = lines.map((raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return '';
      if (trimmed.startsWith('•')) return '• ${trimmed.substring(1).trim()}';
      if (trimmed.startsWith('-') || trimmed.startsWith('*')) {
        return '• ${trimmed.substring(1).trim()}';
      }
      return '• $trimmed';
    }).where((l) => l.isNotEmpty).toList();
    setState(() {
      final next = converted.isNotEmpty ? converted.join('\n') : '• ';
      _contentController.text = next;
      _contentController.selection = TextSelection.collapsed(offset: next.length);
      _previousContentText = next;
    });
  }

  void _clearAllBullets() {
    final lines = _contentController.text.split('\n');
    final cleaned = lines.map((raw) {
      final trimmed = raw.trim();
      if (trimmed.startsWith('•') || trimmed.startsWith('-') || trimmed.startsWith('*')) {
        return trimmed.substring(1).trim();
      }
      return trimmed;
    }).toList();
    setState(() {
      final next = cleaned.join('\n');
      _contentController.text = next;
      _contentController.selection = TextSelection.collapsed(offset: next.length);
      _previousContentText = next;
    });
  }

  void _handleContentTextChanged(String newValue) {
    final sel = _contentController.selection;
    if (newValue.length == _previousContentText.length + 1 &&
        sel.isValid &&
        sel.baseOffset > 0 &&
        newValue[sel.baseOffset - 1] == '\n') {
      final newlineIdx = sel.baseOffset - 1;
      final prevLineStart = newValue.lastIndexOf('\n', newlineIdx > 0 ? newlineIdx - 1 : 0) + 1;
      final prevLine = newValue.substring(prevLineStart, newlineIdx).trimLeft();
      if (prevLine.startsWith('•') || prevLine.startsWith('-') || prevLine.startsWith('*')) {
        final bulletBody = prevLine.substring(1).trim();
        if (bulletBody.isNotEmpty) {
          final updated = '${newValue.substring(0, sel.baseOffset)}• ${newValue.substring(sel.baseOffset)}';
          _previousContentText = updated;
          _contentController.value = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: sel.baseOffset + 2),
          );
          setState(() {});
          return;
        }
      }
    }
    _previousContentText = newValue;
    setState(() {});
  }

  void _save() {
    widget.onSave(
      BoxEmbedData(
        type: _activePresetId.isNotEmpty ? _activePresetId : 'box_custom',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        bgColor: _bgColor,
        borderColor: _borderColor,
        titleColor: _titleColor,
        contentColor: _contentColor,
        iconEmoji: _iconEmoji,
      ),
    );
    Navigator.of(context).pop();
  }

  Widget _buildColorControlPill({
    required String label,
    required String hexColor,
    required ValueChanged<String> onColorChanged,
    required bool isDark,
    required Color borderColor,
  }) {
    final color = _parseHexColor(hexColor);
    return InkWell(
      onTap: () {
        _showColorPickerModal(
          context,
          title: 'Select $label',
          currentColorHex: hexColor,
          onColorSelected: onColorChanged,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color == Colors.white ? const Color(0xFF94A3B8) : Colors.white,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final currentBoxBg = _parseHexColor(_bgColor);
    final currentBoxBorder = _parseHexColor(_borderColor);
    final currentTitleColor = _parseHexColor(_titleColor);
    final currentContentColor = _parseHexColor(_contentColor);

    const availableEmojis = ['✨', '🌿', '💡', '⚠️', '📋', '📦', '🛡️', '🎯', '🔬', ''];

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
                color: isDark ? const Color(0xFF131D33) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_box_outline_blank_rounded, size: 18, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Edit Box Container',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Theme Presets Bar
                    Text(
                      'Box Theme Presets:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kBoxThemePresets.map((preset) {
                        final isSelected = _activePresetId == preset.id;
                        return InkWell(
                          onTap: () => _applyBoxPreset(preset),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? preset.previewColor.withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? preset.previewColor : borderColor,
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(preset.iconEmoji, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 6),
                                Text(
                                  preset.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? preset.previewColor : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Icon / Emoji Selector
                    Text(
                      'Box Icon Badge:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: availableEmojis.map((emoji) {
                        final isSelected = _iconEmoji == emoji;
                        return InkWell(
                          onTap: () => setState(() => _iconEmoji = emoji),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF059669).withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF059669) : borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              emoji.isNotEmpty ? emoji : 'None',
                              style: TextStyle(
                                fontSize: emoji.isNotEmpty ? 16 : 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? const Color(0xFF059669) : textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Color Controls
                    Text(
                      'Box Colors:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildColorControlPill(
                          label: 'Background Tint',
                          hexColor: _bgColor,
                          onColorChanged: (c) => setState(() => _bgColor = c),
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                        _buildColorControlPill(
                          label: 'Border Color',
                          hexColor: _borderColor,
                          onColorChanged: (c) => setState(() => _borderColor = c),
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                        _buildColorControlPill(
                          label: 'Title Color',
                          hexColor: _titleColor,
                          onColorChanged: (c) => setState(() => _titleColor = c),
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                        _buildColorControlPill(
                          label: 'Content Color',
                          hexColor: _contentColor,
                          onColorChanged: (c) => setState(() => _contentColor = c),
                          isDark: isDark,
                          borderColor: borderColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Inputs
                    Text(
                      'Box Title',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Box Content (supports bullet points •)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const ValueKey('box_add_bullet_btn'),
                          onPressed: _insertBulletPointAtCursor,
                          icon: const Icon(Icons.format_list_bulleted_rounded, size: 14),
                          label: const Text('+ Add Bullet •'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 28),
                            side: BorderSide(color: borderColor),
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          key: const ValueKey('box_bullet_all_btn'),
                          onPressed: _formatAllLinesAsBullets,
                          icon: const Icon(Icons.checklist_rounded, size: 14),
                          label: const Text('Bullet All Lines'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 28),
                            side: BorderSide(color: borderColor),
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          key: const ValueKey('box_clear_bullets_btn'),
                          onPressed: _clearAllBullets,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 28),
                            side: BorderSide(color: borderColor),
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Plain Text'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _contentController,
                      onChanged: _handleContentTextChanged,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type text or click "+ Add Bullet •" above. Pressing Enter on a bullet line automatically adds the next bullet!',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 18),

                    // Live Box Preview
                    Text(
                      'Live Storefront Preview:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: currentBoxBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: currentBoxBorder, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (_iconEmoji.isNotEmpty) ...[
                                Text(_iconEmoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  _titleController.text.isNotEmpty ? _titleController.text : 'Section Title',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: currentTitleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildFormattedBoxContent(
                            _contentController.text,
                            currentContentColor,
                            currentBoxBorder,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Apply Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppTableEmbedBuilder extends EmbedBuilder {
  final bool isDark;
  const AppTableEmbedBuilder({this.isDark = false});

  @override
  String get key => 'app_table';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final tableData = TableEmbedData.fromJsonString(embedContext.node.value.data.toString());
    return AppTableVisualWidget(
      tableData: tableData,
      embedContext: embedContext,
      isDark: isDark,
    );
  }
}

class AppBoxEmbedBuilder extends EmbedBuilder {
  final bool isDark;
  const AppBoxEmbedBuilder({this.isDark = false});

  @override
  String get key => 'app_box';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final boxData = BoxEmbedData.fromJsonString(embedContext.node.value.data.toString());
    return AppBoxVisualWidget(
      boxData: boxData,
      embedContext: embedContext,
      isDark: isDark,
    );
  }
}

String _visualTablesToHtml(String html) {
  final tableBlockRegex = RegExp(r'(<p>\|[^<]+\|</p>\s*)+');
  return html.replaceAllMapped(tableBlockRegex, (match) {
    final matchedText = match.group(0)!;
    final rowMatches = RegExp(r'<p>\|(.*)\|</p>').allMatches(matchedText);
    final rows = <List<String>>[];
    for (final rm in rowMatches) {
      final inner = rm.group(1)!;
      if (inner.replaceAll(RegExp(r'[\s\-:|]'), '').isEmpty) continue;
      final cells = inner.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
      if (cells.isNotEmpty) rows.add(cells);
    }
    if (rows.isEmpty) return matchedText;

    final buf = StringBuffer();
    buf.writeln('<table style="width: 100%; border-collapse: collapse; margin: 14px 0; border: 1px solid #CBD5E1;">');
    final header = rows.first;
    buf.writeln('  <thead>');
    buf.writeln('    <tr style="background-color: #F8FAFC;">');
    for (final col in header) {
      buf.writeln('      <th style="border: 1px solid #CBD5E1; padding: 10px 14px; text-align: left; font-weight: 700; font-size: 13px;">$col</th>');
    }
    buf.writeln('    </tr>');
    buf.writeln('  </thead>');
    buf.writeln('  <tbody>');
    for (int i = 1; i < rows.length; i++) {
      buf.writeln('    <tr>');
      for (final cell in rows[i]) {
        buf.writeln('      <td style="border: 1px solid #CBD5E1; padding: 10px 14px; font-size: 13px;">$cell</td>');
      }
      buf.writeln('    </tr>');
    }
    buf.writeln('  </tbody>');
    buf.writeln('</table>');
    return buf.toString();
  });
}

String _convertBoxTagsToHtml(String html) {
  var result = html;
  result = result.replaceAllMapped(
    RegExp(r'<p>\[\s*BOX:\s*([^\]]+)\]</p>([\s\S]*?)<p>\[\s*/BOX\s*\]</p>', caseSensitive: false),
    (m) =>
        '<div style="border: 1px solid #CBD5E1; border-radius: 8px; padding: 16px; margin: 14px 0; background-color: #FFFFFF;">'
        '<h4 style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #1E293B;">${m.group(1)!.trim()}</h4>'
        '${m.group(2)!.trim()}'
        '</div>',
  );
  result = result.replaceAllMapped(
    RegExp(r'<p>\[\s*HIGHLIGHT:\s*([^\]]+)\]</p>([\s\S]*?)<p>\[\s*/HIGHLIGHT\s*\]</p>', caseSensitive: false),
    (m) =>
        '<div style="background-color: #ECFDF5; border: 1px solid #10B981; border-radius: 8px; padding: 16px; margin: 14px 0;">'
        '<h4 style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #065F46;">✨ ${m.group(1)!.trim()}</h4>'
        '${m.group(2)!.trim()}'
        '</div>',
  );
  result = result.replaceAllMapped(
    RegExp(r'<p>\[\s*NOTE:\s*([^\]]+)\]</p>([\s\S]*?)<p>\[\s*/NOTE\s*\]</p>', caseSensitive: false),
    (m) =>
        '<div style="background-color: #EFF6FF; border: 1px solid #3B82F6; border-radius: 8px; padding: 16px; margin: 14px 0;">'
        '<h4 style="margin: 0 0 6px 0; font-size: 15px; font-weight: 700; color: #1E40AF;">💡 ${m.group(1)!.trim()}</h4>'
        '${m.group(2)!.trim()}'
        '</div>',
  );
  result = result.replaceAllMapped(
    RegExp(r'<p>\[\s*WARNING:\s*([^\]]+)\]</p>([\s\S]*?)<p>\[\s*/WARNING\s*\]</p>', caseSensitive: false),
    (m) =>
        '<div style="background-color: #FFFBEB; border: 1px solid #F59E0B; border-radius: 8px; padding: 16px; margin: 14px 0;">'
        '<h4 style="margin: 0 0 6px 0; font-size: 15px; font-weight: 700; color: #92400E;">⚠️ ${m.group(1)!.trim()}</h4>'
        '${m.group(2)!.trim()}'
        '</div>',
  );
  result = result.replaceAllMapped(
    RegExp(r'<p>\[\s*CARD:\s*([^\]]+)\]</p>([\s\S]*?)<p>\[\s*/CARD\s*\]</p>', caseSensitive: false),
    (m) =>
        '<div style="border: 1px solid #7C3AED; border-radius: 8px; padding: 16px; margin: 14px 0; background-color: #F5F3FF;">'
        '<h4 style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #4C1D95;">📋 ${m.group(1)!.trim()}</h4>'
        '${m.group(2)!.trim()}'
        '</div>',
  );
  result = result.replaceAll(
    RegExp(r'<p>\s*---\s*</p>'),
    '<hr style="border: none; border-top: 1px solid #CBD5E1; margin: 16px 0;" />',
  );
  return result;
}

Delta _parseHtmlToDelta(String html) {
  if (html.trim().isEmpty) {
    return Delta()..insert('\n');
  }
  try {
    final tables = <String, TableEmbedData>{};
    var processed = html;

    // 1. Detect and extract HTML <table> elements
    if (processed.contains('<table')) {
      final fragment = html_parser.parseFragment(processed);
      final tableNodes = fragment.querySelectorAll('table');
      int tIndex = 0;
      for (final t in tableNodes) {
        final tableData = TableEmbedData.fromTableElement(t);
        if (tableData != null) {
          final placeholder = '@@APPTABLE${tIndex}XYZ@@';
          tables[placeholder] = tableData;
          t.replaceWith(dom.Element.tag('p')..text = placeholder);
          tIndex++;
        }
      }
      processed = fragment.outerHtml;
    }

    // 2. Detect and extract markdown table blocks (like | Col 1 | Col 2 | ...)
    final mdTableRegex = RegExp(r'(\|[^|\n]+\|(\s*\|[^|\n]+\|)*\n?)+');
    processed = processed.replaceAllMapped(mdTableRegex, (match) {
      final md = match.group(0)!;
      final tableData = TableEmbedData.fromMarkdown(md);
      if (tableData != null) {
        final placeholder = '@@APPTABLE${tables.length}XYZ@@';
        tables[placeholder] = tableData;
        return '<p>$placeholder</p>';
      }
      return md;
    });

    // 3. Detect and extract bracket box tags ([BOX: ...], [HIGHLIGHT: ...], etc.)
    final boxes = <String, BoxEmbedData>{};
    final boxRegex = RegExp(
      r'\[\s*(BOX|HIGHLIGHT|NOTE|WARNING|CARD):\s*([^\]]+)\]([\s\S]*?)\[\s*/\1\s*\]',
      caseSensitive: false,
    );
    processed = processed.replaceAllMapped(boxRegex, (match) {
      final tagType = match.group(1)!;
      final title = match.group(2)!;
      final body = match.group(3)!;
      final boxData = BoxEmbedData.fromBracketTag(tagType, title, body);
      if (boxData != null) {
        final placeholder = '@@APPBOX${boxes.length}XYZ@@';
        boxes[placeholder] = boxData;
        return '<p>$placeholder</p>';
      }
      return match.group(0)!;
    });

    // 4. Detect and extract styled HTML divs (box containers)
    if (processed.toLowerCase().contains('<div')) {
      final fragment = html_parser.parseFragment(processed);
      final divNodes = fragment.querySelectorAll('div');
      for (final d in divNodes) {
        if (d.parentNode == null) continue;
        final style = d.attributes['style'] ?? '';
        final boxData = BoxEmbedData.fromDivElement(d, style);
        if (boxData != null) {
          final placeholder = '@@APPBOX${boxes.length}XYZ@@';
          boxes[placeholder] = boxData;
          d.replaceWith(dom.Element.tag('p')..text = placeholder);
        }
      }
      processed = fragment.outerHtml;
    }

    final baseDelta = HtmlToDelta().convert(processed);
    if (baseDelta.isEmpty) {
      return Delta()..insert('\n');
    }

    // Expand placeholders in Delta into BlockEmbed
    final allEntries = <String, Object>{
      ...tables,
      ...boxes,
    };

    final finalDelta = Delta();
    String lastInsertedText = '\n';
    for (final op in baseDelta.toList()) {
      if (op.data is String) {
        List<dynamic> segments = [op.data as String];
        for (final entry in allEntries.entries) {
          final nextSegments = <dynamic>[];
          for (final seg in segments) {
            if (seg is String && seg.contains(entry.key)) {
              final parts = seg.split(entry.key);
              for (int i = 0; i < parts.length; i++) {
                var part = parts[i];
                if (i > 0 && part.startsWith('\n')) {
                  part = part.substring(1);
                }
                if (part.isNotEmpty) {
                  nextSegments.add(part);
                }
                if (i < parts.length - 1) {
                  if (entry.value is TableEmbedData) {
                    nextSegments.add(BlockEmbed('app_table', (entry.value as TableEmbedData).toJsonString()));
                  } else if (entry.value is BoxEmbedData) {
                    nextSegments.add(BlockEmbed('app_box', (entry.value as BoxEmbedData).toJsonString()));
                  }
                  nextSegments.add('\n');
                }
              }
            } else {
              nextSegments.add(seg);
            }
          }
          segments = nextSegments;
        }

        for (final item in segments) {
          if (item is String) {
            if (item.trim().isEmpty && !item.contains('\n')) {
              continue;
            }
            finalDelta.insert(item, op.attributes);
            lastInsertedText = item;
          } else if (item is BlockEmbed) {
            if (!lastInsertedText.endsWith('\n')) {
              finalDelta.insert('\n');
            }
            finalDelta.insert(item.toJson());
            lastInsertedText = '';
          }
        }
      } else {
        finalDelta.push(op);
      }
    }

    if (finalDelta.isEmpty) {
      return Delta()..insert('\n');
    }
    return finalDelta;
  } catch (_) {
    final text = html.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    return Delta()..insert(text.isNotEmpty ? '$text\n' : '\n');
  }
}

String _deltaToHtml(Document doc) {
  try {
    final deltaOps = doc.toDelta().toJson().cast<Map<String, dynamic>>();
    final converter = QuillDeltaToHtmlConverter(
      deltaOps,
      ConverterOptions(
        multiLineParagraph: false,
        converterOptions: OpConverterOptions(
          inlineStylesFlag: true,
          inlineStyles: InlineStyles({
            'size': InlineStyleType(fn: (value, _) {
              final numVal = double.tryParse(value.toString());
              if (numVal != null && numVal > 0) return 'font-size: ${numVal.toInt()}px';
              return null;
            }),
            'font': InlineStyleType(fn: (value, _) => 'font-family: $value'),
          }),
        ),
      ),
    );

    converter.renderCustomWith = (op, _) {
      if (op.insert.type == 'app_table') {
        final table = TableEmbedData.fromJsonString(op.insert.value.toString());
        return table.toHtml();
      }
      if (op.insert.type == 'app_box') {
        final box = BoxEmbedData.fromJsonString(op.insert.value.toString());
        return box.toHtml();
      }
      return '';
    };

    var rawHtml = converter.convert();
    rawHtml = rawHtml.replaceAll(RegExp(r'<p><br/></p>$'), '').trim();
    rawHtml = _visualTablesToHtml(rawHtml);
    rawHtml = _convertBoxTagsToHtml(rawHtml);
    return rawHtml.trim();
  } catch (_) {
    return doc.toPlainText().trim();
  }
}

class _AppHtmlEditorState extends State<AppHtmlEditor> {
  EditorMode _mode = EditorMode.visual;
  late QuillController _quillController;
  late TextEditingController _sourceController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  StreamSubscription? _docChangesSub;
  Timer? _syncDebounceTimer;

  bool _isSyncing = false;
  String _lastSyncedHtml = '';
  int _wordCount = 0;
  int _charCount = 0;
  bool _showSplitPreview = false;
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController(text: widget.controller.text);
    _lastSyncedHtml = widget.controller.text;

    final initialDelta = _parseHtmlToDelta(widget.controller.text);
    _quillController = QuillController(
      document: Document.fromDelta(initialDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _updateCounts();
    _docChangesSub = _quillController.document.changes.listen((_) => _onQuillDocChanged());
    widget.controller.addListener(_onExternalControllerChanged);
    _sourceController.addListener(_onSourceChanged);
  }

  @override
  void dispose() {
    _syncDebounceTimer?.cancel();
    _flushSync();
    _docChangesSub?.cancel();
    widget.controller.removeListener(_onExternalControllerChanged);
    _sourceController.removeListener(_onSourceChanged);
    _sourceController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  TextStyle _resolveFontTextStyle(String fontName, {TextStyle? textStyle}) {
    var clean = fontName
        .replaceAll('"', '')
        .replaceAll("'", "")
        .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
        .replaceAll(RegExp(r'_\w+$'), '')
        .trim();

    if (clean.isEmpty || clean.toLowerCase() == 'clear' || clean.toLowerCase() == 'default') {
      return textStyle ?? const TextStyle();
    }

    final normalized = clean.toLowerCase();
    switch (normalized) {
      case 'poppins':
        return GoogleFonts.poppins(textStyle: textStyle);
      case 'montserrat':
        return GoogleFonts.montserrat(textStyle: textStyle);
      case 'open sans':
        return GoogleFonts.openSans(textStyle: textStyle);
      case 'lato':
        return GoogleFonts.lato(textStyle: textStyle);
      case 'inter':
        return GoogleFonts.inter(textStyle: textStyle);
      case 'merriweather':
      case 'georgia':
      case 'serif':
        return GoogleFonts.merriweather(textStyle: textStyle);
      case 'lora':
        return GoogleFonts.lora(textStyle: textStyle);
      case 'playfair display':
        return GoogleFonts.playfairDisplay(textStyle: textStyle);
      case 'pt serif':
      case 'times new roman':
      case 'times':
      case 'tinos':
        return GoogleFonts.ptSerif(textStyle: textStyle);
      case 'courier prime':
      case 'courier new':
      case 'courier':
      case 'monospace':
        return GoogleFonts.courierPrime(textStyle: textStyle);
      case 'inconsolata':
        return GoogleFonts.inconsolata(textStyle: textStyle);
      case 'oswald':
        return GoogleFonts.oswald(textStyle: textStyle);
      case 'caveat':
        return GoogleFonts.caveat(textStyle: textStyle);
      case 'roboto':
      case 'arial':
      case 'sans-serif':
        return GoogleFonts.roboto(textStyle: textStyle);
      default:
        try {
          return GoogleFonts.getFont(clean, textStyle: textStyle);
        } catch (_) {
          return textStyle != null
              ? textStyle.copyWith(fontFamily: clean)
              : TextStyle(fontFamily: clean);
        }
    }
  }

  void _onQuillDocChanged() {
    if (_isSyncing) return;
    _syncDebounceTimer?.cancel();
    _syncQuillToHtml();
  }

  void _syncQuillToHtml() {
    if (_isSyncing || !mounted) return;
    _isSyncing = true;
    final html = _deltaToHtml(_quillController.document);
    final hasChanged = html != _lastSyncedHtml;
    if (hasChanged) {
      _lastSyncedHtml = html;
      widget.controller.text = html;
      if (_sourceController.text != html) {
        _sourceController.text = html;
      }
      _updateCounts();
      if (mounted) {
        setState(() {});
      }
    }
    _isSyncing = false;
  }

  void _flushSync() {
    _syncDebounceTimer?.cancel();
    if (_isSyncing) return;
    if (_mode == EditorMode.source) {
      _isSyncing = true;
      final newDelta = _parseHtmlToDelta(_sourceController.text);
      _quillController.document = Document.fromDelta(newDelta);
      _lastSyncedHtml = _sourceController.text;
      widget.controller.text = _sourceController.text;
      _updateCounts();
      _isSyncing = false;
    } else {
      _isSyncing = true;
      final html = _deltaToHtml(_quillController.document);
      final hasChanged = html != _lastSyncedHtml;
      if (hasChanged) {
        _lastSyncedHtml = html;
        widget.controller.text = html;
        if (_sourceController.text != html) {
          _sourceController.text = html;
        }
        _updateCounts();
      }
      _isSyncing = false;
    }
  }

  void _onSourceChanged() {
    if (_isSyncing || _mode != EditorMode.source) return;
    _isSyncing = true;

    final html = _sourceController.text;
    _lastSyncedHtml = html;
    widget.controller.text = html;

    _updateCounts();
    _isSyncing = false;
    setState(() {});
  }

  void _onExternalControllerChanged() {
    if (_isSyncing || widget.controller.text == _lastSyncedHtml) return;
    _isSyncing = true;

    _lastSyncedHtml = widget.controller.text;
    _sourceController.text = widget.controller.text;

    final newDelta = _parseHtmlToDelta(widget.controller.text);
    _quillController.document = Document.fromDelta(newDelta);

    _updateCounts();
    _isSyncing = false;
    setState(() {});
  }

  void _updateCounts() {
    final plainText = _quillController.document.toPlainText().trim();
    _charCount = plainText.length;
    _wordCount = plainText.isEmpty
        ? 0
        : plainText.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  void _switchMode(EditorMode newMode) {
    if (_mode == newMode) return;
    _flushSync();
    setState(() {
      _mode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final surfaceColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final toolbarBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return SelectionContainer.disabled(
      child: Localizations.override(
        context: context,
        delegates: const [
          FlutterQuillLocalizations.delegate,
        ],
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Bar: Label, Badge, Mode Switcher
          LayoutBuilder(
            builder: (context, constraints) {
              final labelWidget = ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 350
                      ? constraints.maxWidth - 240
                      : constraints.maxWidth,
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    if (widget.isRequired)
                      Text(
                        '*',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF059669).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 11,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Visual WYSIWYG',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              final modeSelector = Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeTab('✎ Visual', EditorMode.visual, isDark),
                    _buildModeTab('</> HTML Source', EditorMode.source, isDark),
                    _buildModeTab('👁 Preview', EditorMode.preview, isDark),
                  ],
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      labelWidget,
                      modeSelector,
                    ],
                  ),
                  if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),

          // Main Editor Container
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full WYSIWYG Toolbar (Shown in Visual Mode)
                  if (_mode == EditorMode.visual) ...[
                    _buildWysiwygToolbar(isDark, toolbarBgColor, borderColor),
                    Divider(height: 1, color: borderColor),
                  ],

                  // Toolbar for Source Mode
                  if (_mode == EditorMode.source) ...[
                    _buildSourceModeToolbar(isDark, toolbarBgColor, borderColor),
                    Divider(height: 1, color: borderColor),
                  ],

                  // Main Content Canvas
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: widget.minHeight),
                    child: _mode == EditorMode.preview
                        ? _buildPreviewArea(isDark, textSecondary)
                        : (_mode == EditorMode.visual
                            ? _buildVisualArea(isDark, borderColor, textPrimary, textSecondary)
                            : _buildSourceEditingArea(isDark, textPrimary, textSecondary)),
                  ),

                  // Footer Status Bar
                  Divider(height: 1, color: borderColor),
                  _buildStatusBar(isDark, toolbarBgColor, textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildModeTab(String title, EditorMode mode, bool isDark) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () => _switchMode(mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF059669)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  void _openInsertTableDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => _InsertTableDialog(
        isDark: isDark,
        onInsert: _insertNormalTable,
      ),
    );
  }

  void _insertNormalTable(int columns, int rows, String style) {
    final preset = kTableThemePresets.firstWhere(
      (p) => p.id == style,
      orElse: () => kTableThemePresets.first,
    );
    final headers = List.generate(columns, (i) => 'Column ${i + 1}');
    final tableRows = List.generate(
      rows - 1,
      (r) => List.generate(columns, (c) => 'Row ${r + 1} Col ${c + 1}'),
    );
    final tableData = TableEmbedData(
      headers: headers,
      rows: tableRows,
      style: preset.id,
      headerBgColor: preset.headerBgColor,
      headerTextColor: preset.headerTextColor,
      rowBgColor: preset.rowBgColor,
      altRowBgColor: preset.altRowBgColor,
      rowTextColor: preset.rowTextColor,
      borderColor: preset.borderColor,
    );

    if (_mode == EditorMode.source) {
      final curPos = _sourceController.selection.baseOffset >= 0
          ? _sourceController.selection.baseOffset
          : _sourceController.text.length;
      final prefix = _sourceController.text.substring(0, curPos);
      final suffix = _sourceController.text.substring(curPos);
      final snippet = '\n${tableData.toHtml()}\n';
      _sourceController.text = '$prefix$snippet$suffix';
      _sourceController.selection = TextSelection.collapsed(offset: curPos + snippet.length);
    } else {
      final maxOffset = (_quillController.document.length - 1).clamp(0, 999999);
      final offset = _quillController.selection.baseOffset >= 0
          ? _quillController.selection.baseOffset.clamp(0, maxOffset)
          : maxOffset;
      _quillController.document.insert(offset, BlockEmbed('app_table', tableData.toJsonString()));
      _quillController.document.insert(offset + 1, '\n');
      _quillController.updateSelection(
        TextSelection.collapsed(offset: offset + 2),
        ChangeSource.local,
      );
    }
  }

  void _openInsertBoxDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => _InsertBoxDialog(
        isDark: isDark,
        onInsert: _insertNormalBox,
      ),
    );
  }

  void _insertNormalBox(NormalBoxTemplate template) {
    final boxData = BoxEmbedData(
      type: template.id,
      title: template.title,
      content: template.defaultContent,
      bgColor: template.bgColor,
      borderColor: template.borderColor,
      titleColor: template.titleColor,
      contentColor: template.contentColor,
      iconEmoji: template.iconEmoji,
    );

    if (_mode == EditorMode.source) {
      final curPos = _sourceController.selection.baseOffset >= 0
          ? _sourceController.selection.baseOffset
          : _sourceController.text.length;
      final prefix = _sourceController.text.substring(0, curPos);
      final suffix = _sourceController.text.substring(curPos);
      final snippet = '\n${boxData.toHtml()}\n';
      _sourceController.text = '$prefix$snippet$suffix';
      _sourceController.selection = TextSelection.collapsed(offset: curPos + snippet.length);
    } else {
      final maxOffset = (_quillController.document.length - 1).clamp(0, 999999);
      final offset = _quillController.selection.baseOffset >= 0
          ? _quillController.selection.baseOffset.clamp(0, maxOffset)
          : maxOffset;
      _quillController.document.insert(offset, BlockEmbed('app_box', boxData.toJsonString()));
      _quillController.document.insert(offset + 1, '\n');
      _quillController.updateSelection(
        TextSelection.collapsed(offset: offset + 2),
        ChangeSource.local,
      );
    }
  }

  void _insertHorizontalDivider() {
    if (_mode == EditorMode.source) {
      final curPos = _sourceController.selection.baseOffset >= 0
          ? _sourceController.selection.baseOffset
          : _sourceController.text.length;
      final prefix = _sourceController.text.substring(0, curPos);
      final suffix = _sourceController.text.substring(curPos);
      const snippet = '\n<hr style="border: none; border-top: 1px solid #CBD5E1; margin: 16px 0;" />\n';
      _sourceController.text = '$prefix$snippet$suffix';
      _sourceController.selection = TextSelection.collapsed(offset: curPos + snippet.length);
    } else {
      final offset = _quillController.selection.baseOffset >= 0
          ? _quillController.selection.baseOffset
          : _quillController.document.length - 1;
      const divider = '\n---\n';
      _quillController.document.insert(offset, divider);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: offset + divider.length),
        ChangeSource.local,
      );
    }
  }

  void _openFullscreenDialog(BuildContext context) {
    _flushSync();
    setState(() {
      _isMaximized = true;
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Fullscreen Editor',
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _FullscreenEditorDialog(
          quillController: _quillController,
          sourceController: _sourceController,
          externalController: widget.controller,
          label: widget.label,
          hintText: widget.hintText,
          initialMode: _mode,
          isDark: isDark,
          fontResolver: _resolveFontTextStyle,
          insertDivider: _insertHorizontalDivider,
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    ).then((_) {
      _flushSync();
      if (mounted) {
        setState(() {
          _isMaximized = false;
        });
      }
    });
  }

  Widget _buildWysiwygToolbar(bool isDark, Color bgColor, Color borderColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: QuillSimpleToolbarConfig(
          multiRowsDisplay: true,
          toolbarIconAlignment: WrapAlignment.start,
          toolbarIconCrossAlignment: WrapCrossAlignment.center,
          showDividers: true,
          showFontFamily: true,
          showFontSize: true,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showInlineCode: true,
          showColorButton: true,
          showBackgroundColorButton: true,
          showClearFormat: true,
          showAlignmentButtons: true,
          showLeftAlignment: true,
          showCenterAlignment: true,
          showRightAlignment: true,
          showJustifyAlignment: true,
          showHeaderStyle: true,
          headerStyleType: HeaderStyleType.original,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          showCodeBlock: true,
          showQuote: true,
          showIndent: true,
          showLink: true,
          showUndo: true,
          showRedo: true,
          showDirection: true,
          showSearchButton: true,
          showSubscript: true,
          showSuperscript: true,
          // ignore: experimental_member_use
          showClipboardCut: true,
          // ignore: experimental_member_use
          showClipboardCopy: true,
          // ignore: experimental_member_use
          showClipboardPaste: true,
          customButtons: [
            QuillToolbarCustomButtonOptions(
              icon: const Icon(Icons.table_chart_rounded, size: 18),
              tooltip: 'Insert Table',
              onPressed: () => _openInsertTableDialog(context),
            ),
            QuillToolbarCustomButtonOptions(
              icon: const Icon(Icons.check_box_outline_blank_rounded, size: 18),
              tooltip: 'Insert Box Container',
              onPressed: () => _openInsertBoxDialog(context),
            ),
            QuillToolbarCustomButtonOptions(
              icon: const Icon(Icons.horizontal_rule_rounded, size: 18),
              tooltip: 'Insert Divider Line',
              onPressed: _insertHorizontalDivider,
            ),
            QuillToolbarCustomButtonOptions(
              icon: Icon(
                _showSplitPreview ? Icons.vertical_split_rounded : Icons.splitscreen_rounded,
                size: 18,
              ),
              tooltip: _showSplitPreview ? 'Hide Live Storefront Preview' : 'Show Live Storefront Preview',
              onPressed: () => setState(() => _showSplitPreview = !_showSplitPreview),
            ),
            QuillToolbarCustomButtonOptions(
              icon: const Icon(Icons.fullscreen_rounded, size: 18),
              tooltip: 'Maximize Editor (Full Screen)',
              onPressed: () => _openFullscreenDialog(context),
            ),
          ],
          buttonOptions: QuillSimpleToolbarButtonOptions(
            fontFamily: const QuillToolbarFontFamilyButtonOptions(
              items: {
                'Roboto (Modern Sans)': 'Roboto',
                'Poppins (Geometric Sans)': 'Poppins',
                'Open Sans (Editorial)': 'Open Sans',
                'Montserrat (Display)': 'Montserrat',
                'Lato (Soft Sans)': 'Lato',
                'Inter (Clean UI)': 'Inter',
                'Merriweather (Classic Serif)': 'Merriweather',
                'Lora (Elegant Serif)': 'Lora',
                'Playfair Display (Luxury Serif)': 'Playfair Display',
                'PT Serif (Traditional)': 'PT Serif',
                'Courier Prime (Monospace)': 'Courier Prime',
                'Inconsolata (Code)': 'Inconsolata',
                'Oswald (Bold Headline)': 'Oswald',
                'Caveat (Handwritten)': 'Caveat',
                'Clear Custom Font': 'Clear',
              },
              defaultDisplayText: 'Font',
            ),
            fontSize: const QuillToolbarFontSizeButtonOptions(
              items: {
                '8': '8',
                '9': '9',
                '10': '10',
                '11': '11',
                '12': '12',
                '14': '14',
                '16': '16',
                '18': '18',
                '20': '20',
                '22': '22',
                '24': '24',
                '26': '26',
                '28': '28',
                '36': '36',
                '48': '48',
                '72': '72',
                'Default': '0',
              },
              defaultDisplayText: '14',
            ),
            selectHeaderStyleDropdownButton: const QuillToolbarSelectHeaderStyleDropdownButtonOptions(
              defaultDisplayText: 'Format',
            ),
            base: QuillToolbarBaseButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonSelectedData: IconButtonData(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF059669).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF059669),
                  ),
                ),
                iconButtonUnselectedData: IconButtonData(
                  style: IconButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceModeToolbar(bool isDark, Color bgColor, Color borderColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.code_rounded, size: 14, color: isDark ? Colors.amber : const Color(0xFFD97706)),
          const SizedBox(width: 6),
          Text(
            'HTML Source Mode — Direct Semantic Markup Editing',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.amber : const Color(0xFFD97706),
            ),
          ),
          const Spacer(),
          Text(
            'Changes sync automatically to Visual Mode',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualArea(
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_isMaximized) {
      return Container(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fullscreen_rounded, color: Color(0xFF059669), size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              'Editor is currently expanded in Full-Screen Mode',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All changes sync live. Click Minimize or Done in the full-screen view to return.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 850;

        final editorCanvas = Container(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: QuillEditor.basic(
            controller: _quillController,
            focusNode: _editorFocusNode,
            scrollController: _editorScrollController,
            config: QuillEditorConfig(
              autoFocus: false,
              placeholder: widget.hintText,
              padding: EdgeInsets.zero,
              scrollable: true,
              embedBuilders: [
                AppTableEmbedBuilder(isDark: isDark),
                AppBoxEmbedBuilder(isDark: isDark),
              ],
              customStyles: buildAppQuillDefaultStyles(context, isDark),
              customStyleBuilder: (Attribute attribute) {
                if (attribute.key == Attribute.font.key && attribute.value != null) {
                  return _resolveFontTextStyle(attribute.value.toString());
                }
                return const TextStyle();
              },
            ),
          ),
        );

        if (!_showSplitPreview || !isWideScreen) {
          return editorCanvas;
        }

        // Live Side-by-Side Storefront Preview on Wide Screens (when toggled on)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Interactive WYSIWYG
            Expanded(
              flex: 6,
              child: editorCanvas,
            ),
            // Middle Divider
            Container(
              width: 1,
              color: borderColor,
              height: widget.minHeight,
            ),
            // Right Column: Live Storefront Customer View
            Expanded(
              flex: 4,
              child: Container(
                color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 13,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live Storefront Preview',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => _showSplitPreview = false),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close_rounded, size: 14, color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    if (widget.controller.text.trim().isEmpty)
                      Text(
                        'Live customer preview will render here...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: textSecondary,
                        ),
                      )
                    else
                      HtmlWidget(
                        widget.controller.text,
                        key: ValueKey(widget.controller.text),
                        rebuildTriggers: [widget.controller.text],
                        factoryBuilder: () => AppHtmlWidgetFactory(resolveFontStyle: _resolveFontTextStyle),
                        customStylesBuilder: (element) => buildAppHtmlCustomStyles(element, isDark),
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          height: 1.5,
                          letterSpacing: 0.1,
                          color: textPrimary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSourceEditingArea(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      color: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: TextField(
        controller: _sourceController,
        maxLines: null,
        minLines: 10,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12.5,
          height: 1.5,
          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: '<p>Enter raw HTML markup here...</p>',
          hintStyle: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea(bool isDark, Color textSecondary) {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 36, color: textSecondary),
              const SizedBox(height: 8),
              Text(
                'No description content entered yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: HtmlWidget(
        text,
        key: ValueKey(text),
        rebuildTriggers: [text],
        factoryBuilder: () => AppHtmlWidgetFactory(resolveFontStyle: _resolveFontTextStyle),
        customStylesBuilder: (element) => buildAppHtmlCustomStyles(element, isDark),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.5,
          letterSpacing: 0.1,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool isDark, Color bgColor, Color textColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _mode == EditorMode.visual
                    ? 'WYSIWYG Rich Editor'
                    : (_mode == EditorMode.source ? 'Raw HTML Source' : 'Storefront Preview'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Words: $_wordCount',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Characters: $_charCount',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenEditorDialog extends StatefulWidget {
  final QuillController quillController;
  final TextEditingController sourceController;
  final TextEditingController externalController;
  final String label;
  final String hintText;
  final EditorMode initialMode;
  final bool isDark;
  final TextStyle Function(String, {TextStyle? textStyle}) fontResolver;
  final VoidCallback insertDivider;
  final VoidCallback onClose;

  const _FullscreenEditorDialog({
    required this.quillController,
    required this.sourceController,
    required this.externalController,
    required this.label,
    required this.hintText,
    required this.initialMode,
    required this.isDark,
    required this.fontResolver,
    required this.insertDivider,
    required this.onClose,
  });

  @override
  State<_FullscreenEditorDialog> createState() => _FullscreenEditorDialogState();
}

class _FullscreenEditorDialogState extends State<_FullscreenEditorDialog> {
  late final ScrollController _fullscreenScrollController;
  late final FocusNode _fullscreenFocusNode;
  late EditorMode _mode;
  bool _showSplitPreview = false;
  int _wordCount = 0;
  int _charCount = 0;
  StreamSubscription? _docChangesSub;
  Timer? _fullscreenDebounceTimer;

  @override
  void initState() {
    super.initState();
    _fullscreenScrollController = ScrollController();
    _fullscreenFocusNode = FocusNode();
    _mode = widget.initialMode;
    _updateCounts();
    _docChangesSub = widget.quillController.document.changes.listen((_) => _onDocChangedDebounced());
    widget.sourceController.addListener(_onSourceChangedDebounced);
  }

  @override
  void dispose() {
    _docChangesSub?.cancel();
    _fullscreenDebounceTimer?.cancel();
    widget.sourceController.removeListener(_onSourceChangedDebounced);
    _fullscreenScrollController.dispose();
    _fullscreenFocusNode.dispose();
    super.dispose();
  }

  void _syncVisualToExternal() {
    final html = _deltaToHtml(widget.quillController.document);
    widget.externalController.text = html;
    if (widget.sourceController.text != html) {
      widget.sourceController.text = html;
    }
  }

  void _syncSourceToExternal() {
    final html = widget.sourceController.text;
    widget.externalController.text = html;
    final delta = _parseHtmlToDelta(html);
    widget.quillController.document = Document.fromDelta(delta);
  }

  void _onDocChangedDebounced() {
    _fullscreenDebounceTimer?.cancel();
    _fullscreenDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        _syncVisualToExternal();
        _updateCounts();
        if (_showSplitPreview) {
          setState(() {});
        }
      }
    });
  }

  void _onSourceChangedDebounced() {
    if (_mode != EditorMode.source) return;
    _fullscreenDebounceTimer?.cancel();
    _fullscreenDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        _syncSourceToExternal();
        _updateCounts();
        if (_showSplitPreview) {
          setState(() {});
        }
      }
    });
  }

  void _updateCounts() {
    final plainText = widget.quillController.document.toPlainText().trim();
    _charCount = plainText.length;
    _wordCount = plainText.isEmpty
        ? 0
        : plainText.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  void _switchMode(EditorMode newMode) {
    if (_mode == newMode) return;
    _fullscreenDebounceTimer?.cancel();
    if (_mode == EditorMode.visual) {
      _syncVisualToExternal();
    } else if (_mode == EditorMode.source) {
      _syncSourceToExternal();
    }
    setState(() {
      _mode = newMode;
    });
  }

  void _handleClose() {
    _fullscreenDebounceTimer?.cancel();
    if (_mode == EditorMode.visual) {
      _syncVisualToExternal();
    } else if (_mode == EditorMode.source) {
      _syncSourceToExternal();
    }
    widget.onClose();
  }

  void _openInsertTableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _InsertTableDialog(
        isDark: widget.isDark,
        onInsert: _insertNormalTable,
      ),
    );
  }

  void _insertNormalTable(int columns, int rows, String style) {
    final preset = kTableThemePresets.firstWhere(
      (p) => p.id == style,
      orElse: () => kTableThemePresets.first,
    );
    final headers = List.generate(columns, (i) => 'Column ${i + 1}');
    final tableRows = List.generate(
      rows - 1,
      (r) => List.generate(columns, (c) => 'Row ${r + 1} Col ${c + 1}'),
    );
    final tableData = TableEmbedData(
      headers: headers,
      rows: tableRows,
      style: preset.id,
      headerBgColor: preset.headerBgColor,
      headerTextColor: preset.headerTextColor,
      rowBgColor: preset.rowBgColor,
      altRowBgColor: preset.altRowBgColor,
      rowTextColor: preset.rowTextColor,
      borderColor: preset.borderColor,
    );

    if (_mode == EditorMode.source) {
      final curPos = widget.sourceController.selection.baseOffset >= 0
          ? widget.sourceController.selection.baseOffset
          : widget.sourceController.text.length;
      final prefix = widget.sourceController.text.substring(0, curPos);
      final suffix = widget.sourceController.text.substring(curPos);
      final snippet = '\n${tableData.toHtml()}\n';
      widget.sourceController.text = '$prefix$snippet$suffix';
      widget.sourceController.selection = TextSelection.collapsed(offset: curPos + snippet.length);
    } else {
      final maxOffset = (widget.quillController.document.length - 1).clamp(0, 999999);
      final offset = widget.quillController.selection.baseOffset >= 0
          ? widget.quillController.selection.baseOffset.clamp(0, maxOffset)
          : maxOffset;
      widget.quillController.document.insert(offset, BlockEmbed('app_table', tableData.toJsonString()));
      widget.quillController.document.insert(offset + 1, '\n');
      widget.quillController.updateSelection(
        TextSelection.collapsed(offset: offset + 2),
        ChangeSource.local,
      );
    }
  }

  void _openInsertBoxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _InsertBoxDialog(
        isDark: widget.isDark,
        onInsert: _insertNormalBox,
      ),
    );
  }

  void _insertNormalBox(NormalBoxTemplate template) {
    final boxData = BoxEmbedData(
      type: template.id,
      title: template.title,
      content: template.defaultContent,
      bgColor: template.bgColor,
      borderColor: template.borderColor,
      titleColor: template.titleColor,
      contentColor: template.contentColor,
      iconEmoji: template.iconEmoji,
    );

    if (_mode == EditorMode.source) {
      final curPos = widget.sourceController.selection.baseOffset >= 0
          ? widget.sourceController.selection.baseOffset
          : widget.sourceController.text.length;
      final prefix = widget.sourceController.text.substring(0, curPos);
      final suffix = widget.sourceController.text.substring(curPos);
      final snippet = '\n${boxData.toHtml()}\n';
      widget.sourceController.text = '$prefix$snippet$suffix';
      widget.sourceController.selection = TextSelection.collapsed(offset: curPos + snippet.length);
    } else {
      final maxOffset = (widget.quillController.document.length - 1).clamp(0, 999999);
      final offset = widget.quillController.selection.baseOffset >= 0
          ? widget.quillController.selection.baseOffset.clamp(0, maxOffset)
          : maxOffset;
      widget.quillController.document.insert(offset, BlockEmbed('app_box', boxData.toJsonString()));
      widget.quillController.document.insert(offset + 1, '\n');
      widget.quillController.updateSelection(
        TextSelection.collapsed(offset: offset + 2),
        ChangeSource.local,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surfaceColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final toolbarBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return SelectionContainer.disabled(
      child: Localizations.override(
        context: context,
        delegates: const [
          FlutterQuillLocalizations.delegate,
        ],
        child: Scaffold(
          backgroundColor: surfaceColor,
          appBar: AppBar(
            backgroundColor: toolbarBgColor,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.fullscreen_exit_rounded),
              tooltip: 'Minimize / Exit Fullscreen',
              onPressed: _handleClose,
            ),
            title: Row(
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Full-Screen Focus Mode',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeTab('✎ Visual', EditorMode.visual, isDark),
                    _buildModeTab('</> HTML Source', EditorMode.source, isDark),
                    _buildModeTab('👁 Preview', EditorMode.preview, isDark),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
                tooltip: 'Done & Return',
                onPressed: _handleClose,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (_mode == EditorMode.visual)
                  _buildFullscreenToolbar(isDark, toolbarBgColor, borderColor),
                if (_mode == EditorMode.source)
                  _buildSourceToolbar(isDark, toolbarBgColor),
                Divider(height: 1, color: borderColor),
                Expanded(
                  child: _mode == EditorMode.preview
                      ? SingleChildScrollView(child: _buildPreviewArea(isDark, textSecondary))
                      : (_mode == EditorMode.visual
                          ? _buildVisualArea(isDark, borderColor, textPrimary, textSecondary)
                          : _buildSourceArea(isDark, textPrimary, textSecondary)),
                ),
                Divider(height: 1, color: borderColor),
                _buildStatusBar(isDark, toolbarBgColor, textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(String title, EditorMode mode, bool isDark) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () => _switchMode(mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF059669)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenToolbar(bool isDark, Color bgColor, Color borderColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: QuillSimpleToolbar(
        controller: widget.quillController,
        config: QuillSimpleToolbarConfig(
          multiRowsDisplay: true,
          toolbarIconAlignment: WrapAlignment.start,
          toolbarIconCrossAlignment: WrapCrossAlignment.center,
          showDividers: true,
          showFontFamily: true,
          showFontSize: true,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showInlineCode: true,
          showColorButton: true,
          showBackgroundColorButton: true,
          showClearFormat: true,
          showAlignmentButtons: true,
          showLeftAlignment: true,
          showCenterAlignment: true,
          showRightAlignment: true,
          showJustifyAlignment: true,
          showHeaderStyle: true,
          headerStyleType: HeaderStyleType.original,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          showCodeBlock: true,
          showQuote: true,
          showIndent: true,
          showLink: true,
          showUndo: true,
          showRedo: true,
          showDirection: true,
          showSearchButton: true,
          showSubscript: true,
          showSuperscript: true,
          // ignore: experimental_member_use
          showClipboardCut: true,
          // ignore: experimental_member_use
          showClipboardCopy: true,
          // ignore: experimental_member_use
          showClipboardPaste: true,
          customButtons: [
            QuillToolbarCustomButtonOptions(
              icon: const Icon(Icons.table_chart_rounded, size: 18),
              tooltip: 'Insert Table',
              onPressed: () => _openInsertTableDialog(context),
            ),
            QuillToolbarCustomButtonOptions(
              icon: const Icon(Icons.check_box_outline_blank_rounded, size: 18),
              tooltip: 'Insert Box Container',
              onPressed: () => _openInsertBoxDialog(context),
            ),
            QuillToolbarCustomButtonOptions(
              icon: const Icon(Icons.horizontal_rule_rounded, size: 18),
              tooltip: 'Insert Divider Line',
              onPressed: widget.insertDivider,
            ),
            QuillToolbarCustomButtonOptions(
              icon: Icon(
                _showSplitPreview ? Icons.vertical_split_rounded : Icons.splitscreen_rounded,
                size: 18,
              ),
              tooltip: _showSplitPreview ? 'Hide Live Storefront Preview' : 'Show Live Storefront Preview',
              onPressed: () => setState(() => _showSplitPreview = !_showSplitPreview),
            ),
            QuillToolbarCustomButtonOptions(
              icon: const Icon(Icons.fullscreen_exit_rounded, size: 18),
              tooltip: 'Minimize Editor (Exit Fullscreen)',
              onPressed: widget.onClose,
            ),
          ],
          buttonOptions: QuillSimpleToolbarButtonOptions(
            fontFamily: const QuillToolbarFontFamilyButtonOptions(
              items: {
                'Roboto (Modern Sans)': 'Roboto',
                'Poppins (Geometric Sans)': 'Poppins',
                'Open Sans (Editorial)': 'Open Sans',
                'Montserrat (Display)': 'Montserrat',
                'Lato (Soft Sans)': 'Lato',
                'Inter (Clean UI)': 'Inter',
                'Merriweather (Classic Serif)': 'Merriweather',
                'Lora (Elegant Serif)': 'Lora',
                'Playfair Display (Luxury Serif)': 'Playfair Display',
                'PT Serif (Traditional)': 'PT Serif',
                'Courier Prime (Monospace)': 'Courier Prime',
                'Inconsolata (Code)': 'Inconsolata',
                'Oswald (Bold Headline)': 'Oswald',
                'Caveat (Handwritten)': 'Caveat',
                'Clear Custom Font': 'Clear',
              },
              defaultDisplayText: 'Font',
            ),
            fontSize: const QuillToolbarFontSizeButtonOptions(
              items: {
                '8': '8',
                '9': '9',
                '10': '10',
                '11': '11',
                '12': '12',
                '14': '14',
                '16': '16',
                '18': '18',
                '20': '20',
                '22': '22',
                '24': '24',
                '26': '26',
                '28': '28',
                '36': '36',
                '48': '48',
                '72': '72',
                'Default': '0',
              },
              defaultDisplayText: '14',
            ),
            selectHeaderStyleDropdownButton: const QuillToolbarSelectHeaderStyleDropdownButtonOptions(
              defaultDisplayText: 'Format',
            ),
            base: QuillToolbarBaseButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonSelectedData: IconButtonData(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF059669).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF059669),
                  ),
                ),
                iconButtonUnselectedData: IconButtonData(
                  style: IconButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceToolbar(bool isDark, Color bgColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.code_rounded, size: 14, color: isDark ? Colors.amber : const Color(0xFFD97706)),
          const SizedBox(width: 6),
          Text(
            'HTML Source Mode — Direct Semantic Markup Editing',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.amber : const Color(0xFFD97706),
            ),
          ),
          const Spacer(),
          Text(
            'Changes sync automatically to Visual Mode',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualArea(bool isDark, Color borderColor, Color textPrimary, Color textSecondary) {
    final editorCanvas = Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: QuillEditor.basic(
        controller: widget.quillController,
        focusNode: _fullscreenFocusNode,
        scrollController: _fullscreenScrollController,
        config: QuillEditorConfig(
          autoFocus: true,
          placeholder: widget.hintText,
          padding: EdgeInsets.zero,
          scrollable: true,
          embedBuilders: [
            AppTableEmbedBuilder(isDark: isDark),
            AppBoxEmbedBuilder(isDark: isDark),
          ],
          customStyles: buildAppQuillDefaultStyles(context, isDark),
          customStyleBuilder: (Attribute attribute) {
            if (attribute.key == Attribute.font.key && attribute.value != null) {
              return widget.fontResolver(attribute.value.toString());
            }
            return const TextStyle();
          },
        ),
      ),
    );

    if (!_showSplitPreview) {
      return editorCanvas;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: editorCanvas),
        Container(width: 1, color: borderColor),
        Expanded(
          flex: 4,
          child: Container(
            color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: HtmlWidget(
                widget.externalController.text,
                key: ValueKey(widget.externalController.text),
                rebuildTriggers: [widget.externalController.text],
                factoryBuilder: () => AppHtmlWidgetFactory(resolveFontStyle: widget.fontResolver),
                customStylesBuilder: (element) => buildAppHtmlCustomStyles(element, isDark),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.5,
                  letterSpacing: 0.1,
                  color: textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceArea(bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      color: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: widget.sourceController,
        maxLines: null,
        minLines: 15,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          height: 1.5,
          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: '<p>Enter raw HTML markup here...</p>',
          hintStyle: GoogleFonts.jetBrainsMono(fontSize: 12, color: textSecondary),
        ),
      ),
    );
  }

  Widget _buildPreviewArea(bool isDark, Color textSecondary) {
    final text = widget.externalController.text.trim();
    if (text.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Text(
            'No description content entered yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: HtmlWidget(
        text,
        key: ValueKey(text),
        rebuildTriggers: [text],
        factoryBuilder: () => AppHtmlWidgetFactory(resolveFontStyle: widget.fontResolver),
        customStylesBuilder: (element) => buildAppHtmlCustomStyles(element, isDark),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.5,
          letterSpacing: 0.1,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool isDark, Color bgColor, Color textColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Full-Screen Focus Mode: ${_mode == EditorMode.visual ? "WYSIWYG" : (_mode == EditorMode.source ? "HTML Source" : "Storefront Preview")}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text('Words: $_wordCount', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textColor)),
          const SizedBox(width: 14),
          Text('Characters: $_charCount', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textColor)),
        ],
      ),
    );
  }
}

class AppHtmlWidgetFactory extends WidgetFactory {
  final TextStyle Function(String fontName, {TextStyle? textStyle}) resolveFontStyle;

  AppHtmlWidgetFactory({required this.resolveFontStyle});

  @override
  InlineSpan? buildTextSpan({
    List<InlineSpan>? children,
    GestureRecognizer? recognizer,
    TextStyle? style,
    String? text,
  }) {
    TextStyle? effectiveStyle = style;
    final family = style?.fontFamily;
    if (family != null &&
        family.isNotEmpty &&
        !family.startsWith('PlusJakartaSans') &&
        family.toLowerCase() != 'plus jakarta sans') {
      effectiveStyle = resolveFontStyle(family, textStyle: style);
    }
    return super.buildTextSpan(
      children: children,
      recognizer: recognizer,
      style: effectiveStyle,
      text: text,
    );
  }
}

/// Default styles configured for QuillEditor to match Storefront Preview typography & spacing 1-to-1
DefaultStyles buildAppQuillDefaultStyles(BuildContext context, bool isDark) {
  final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  final baseFont = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 1.5,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  return DefaultStyles(
    paragraph: DefaultTextBlockStyle(
      baseFont,
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(0, 6),
      VerticalSpacing.zero,
      null,
    ),
    h1: DefaultTextBlockStyle(
      GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(14, 6),
      VerticalSpacing.zero,
      null,
    ),
    h2: DefaultTextBlockStyle(
      GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(12, 6),
      VerticalSpacing.zero,
      null,
    ),
    h3: DefaultTextBlockStyle(
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(10, 4),
      VerticalSpacing.zero,
      null,
    ),
    lists: DefaultListBlockStyle(
      baseFont,
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(4, 6),
      const VerticalSpacing(2, 2),
      null,
      null,
    ),
    quote: DefaultTextBlockStyle(
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        height: 1.5,
        color: textSecondary,
      ),
      const HorizontalSpacing(12, 0),
      const VerticalSpacing(8, 8),
      VerticalSpacing.zero,
      BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
            width: 3.5,
          ),
        ),
      ),
    ),
    code: DefaultTextBlockStyle(
      GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 1.4,
        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
      ),
      const HorizontalSpacing(8, 8),
      const VerticalSpacing(8, 8),
      VerticalSpacing.zero,
      BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
    ),
  );
}

/// Custom CSS styles applied to HTML elements in HtmlWidget to ensure exact 1-to-1 match with Quill
Map<String, String>? buildAppHtmlCustomStyles(dom.Element element, bool isDark) {
  switch (element.localName) {
    case 'p':
      final isOnlyBr = element.children.length == 1 && element.children.first.localName == 'br';
      return {
        'margin': isOnlyBr ? '0 0 2px 0' : '0 0 6px 0',
        'line-height': '1.5',
      };
    case 'h1':
      return {
        'margin': '14px 0 6px 0',
        'font-size': '22px',
        'font-weight': '700',
        'line-height': '1.3',
      };
    case 'h2':
      return {
        'margin': '12px 0 6px 0',
        'font-size': '18px',
        'font-weight': '700',
        'line-height': '1.3',
      };
    case 'h3':
      return {
        'margin': '10px 0 4px 0',
        'font-size': '16px',
        'font-weight': '600',
        'line-height': '1.35',
      };
    case 'ul':
    case 'ol':
      return {
        'margin': '4px 0 6px 0',
        'padding-left': '22px',
        'line-height': '1.5',
      };
    case 'li':
      return {
        'margin': '2px 0',
        'line-height': '1.5',
      };
    case 'blockquote':
      return {
        'margin': '8px 0',
        'padding': '8px 14px',
        'border-left': '3.5px solid #059669',
        'background-color': isDark ? '#1E293B' : '#F8FAFC',
        'font-style': 'italic',
        'line-height': '1.5',
      };
    case 'pre':
    case 'code':
      return {
        'margin': '8px 0',
        'padding': '6px 10px',
        'background-color': isDark ? '#1E293B' : '#F1F5F9',
        'border-radius': '6px',
        'font-family': 'monospace',
        'font-size': '13px',
        'line-height': '1.4',
      };
    case 'table':
      return {
        'margin': '12px 0',
        'border-collapse': 'collapse',
        'width': '100%',
      };
    case 'th':
      final thInline = (element.attributes['style'] ?? '').toLowerCase();
      return {
        if (!thInline.contains('background-color'))
          'background-color': isDark ? '#1E293B' : '#F1F5F9',
        'padding': '8px 12px',
        if (!thInline.contains('border'))
          'border': '1px solid ${isDark ? "#334155" : "#CBD5E1"}',
        'font-weight': '700',
        'font-size': '12px',
        'text-align': 'left',
      };
    case 'td':
      final tdInline = (element.attributes['style'] ?? '').toLowerCase();
      return {
        'padding': '8px 12px',
        if (!tdInline.contains('border'))
          'border': '1px solid ${isDark ? "#334155" : "#CBD5E1"}',
        'font-size': '12.5px',
      };
  }
  return null;
}

class NormalBoxTemplate {
  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String defaultContent;
  final String visualSnippet;
  final String htmlSnippet;
  final String bgColor;
  final String borderColor;
  final String titleColor;
  final String contentColor;
  final String iconEmoji;

  const NormalBoxTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.defaultContent,
    required this.visualSnippet,
    required this.htmlSnippet,
    this.bgColor = '#FFFFFF',
    this.borderColor = '#CBD5E1',
    this.titleColor = '#1E293B',
    this.contentColor = '#475569',
    this.iconEmoji = '📦',
  });
}

const List<NormalBoxTemplate> kNormalBoxTemplates = [
  NormalBoxTemplate(
    id: 'box_standard',
    title: 'Standard Bordered Container',
    category: 'Content Box',
    description: 'Clean minimalist bordered box for grouping content sections and bullet lists',
    icon: Icons.check_box_outline_blank_rounded,
    accentColor: Color(0xFF64748B),
    defaultContent:
        '• Key Product Detail 1: High-purity agricultural formulation\n'
        '• Key Product Detail 2: Suitable for foliar spray and soil drench\n'
        '• Key Product Detail 3: Compatible with standard crop nutrition programs',
    bgColor: '#FFFFFF',
    borderColor: '#CBD5E1',
    titleColor: '#1E293B',
    contentColor: '#475569',
    iconEmoji: '📦',
    visualSnippet:
        '[ BOX: Section Title ]\n'
        '• Key Product Detail 1: High-purity agricultural formulation\n'
        '• Key Product Detail 2: Suitable for foliar spray and soil drench\n'
        '[ /BOX ]',
    htmlSnippet:
        '<div style="border: 1px solid #CBD5E1; border-radius: 8px; padding: 16px; margin: 14px 0; background-color: #FFFFFF;">\n'
        '  <h4 style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #1E293B;">📦 Section Title</h4>\n'
        '  <ul style="margin: 0 0 6px 0; padding-left: 20px; font-size: 13.5px; color: #475569; line-height: 1.6;">\n'
        '    <li>Key Product Detail 1: High-purity agricultural formulation</li>\n'
        '    <li>Key Product Detail 2: Suitable for foliar spray and soil drench</li>\n'
        '  </ul>\n'
        '</div>',
  ),
  NormalBoxTemplate(
    id: 'box_highlight',
    title: 'Feature Highlight Container',
    category: 'Highlight Box',
    description: 'Fresh emerald-tinted container highlighting key features and core advantages',
    icon: Icons.auto_awesome_rounded,
    accentColor: Color(0xFF10B981),
    defaultContent:
        '• Point 1: Fast acting formulation with deep penetration\n'
        '• Point 2: Broad spectrum crop protection\n'
        '• Point 3: Safe for beneficial predatory insects',
    bgColor: '#ECFDF5',
    borderColor: '#10B981',
    titleColor: '#065F46',
    contentColor: '#047857',
    iconEmoji: '✨',
    visualSnippet:
        '[ HIGHLIGHT: Key Features & Benefits ]\n'
        '• Point 1: Fast acting formulation with deep penetration\n'
        '• Point 2: Broad spectrum crop protection\n'
        '• Point 3: Safe for beneficial predatory insects\n'
        '[ /HIGHLIGHT ]',
    htmlSnippet:
        '<div style="background-color: #ECFDF5; border: 1px solid #10B981; border-radius: 8px; padding: 16px; margin: 14px 0;">\n'
        '  <h4 style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #065F46;">✨ Key Features & Benefits</h4>\n'
        '  <ul style="margin: 0 0 6px 0; padding-left: 20px; font-size: 13.5px; color: #047857; line-height: 1.6;">\n'
        '    <li>Fast acting formulation with deep penetration</li>\n'
        '    <li>Broad spectrum crop protection</li>\n'
        '    <li>Safe for beneficial predatory insects</li>\n'
        '  </ul>\n'
        '</div>',
  ),
  NormalBoxTemplate(
    id: 'box_info',
    title: 'Info & Notice Callout',
    category: 'Notice Box',
    description: 'Subtle blue accent callout for important guidelines, tips, or dosages',
    icon: Icons.info_outline_rounded,
    accentColor: Color(0xFF3B82F6),
    defaultContent:
        '• Recommended Spray Time: Early morning (6–9 AM) or evening (4–7 PM)\n'
        '• Water Volume: Use 150–200 liters of clean water per acre',
    bgColor: '#EFF6FF',
    borderColor: '#3B82F6',
    titleColor: '#1E40AF',
    contentColor: '#1E3A8A',
    iconEmoji: '💡',
    visualSnippet:
        '[ NOTE: Important Application Notice ]\n'
        '• Recommended Spray Time: Early morning (6–9 AM) or evening (4–7 PM)\n'
        '[ /NOTE ]',
    htmlSnippet:
        '<div style="background-color: #EFF6FF; border: 1px solid #3B82F6; border-radius: 8px; padding: 16px; margin: 14px 0;">\n'
        '  <h4 style="margin: 0 0 6px 0; font-size: 15px; font-weight: 700; color: #1E40AF;">💡 Important Application Notice</h4>\n'
        '  <p style="margin: 0; font-size: 13.5px; color: #1E3A8A; line-height: 1.5;">Recommended application time: Early morning (6-9 AM) or late evening (4-7 PM) for best efficacy.</p>\n'
        '</div>',
  ),
  NormalBoxTemplate(
    id: 'box_warning',
    title: 'Caution & Precaution Alert',
    category: 'Alert Box',
    description: 'Amber warning container for safety precautions, toxicity, and harvest intervals',
    icon: Icons.warning_amber_rounded,
    accentColor: Color(0xFFF59E0B),
    defaultContent:
        '• Wear protective gloves and goggles during spray preparation.\n'
        '• Observe recommended harvest waiting period before picking.\n'
        '• Keep out of reach of children and pet animals.',
    bgColor: '#FFFBEB',
    borderColor: '#F59E0B',
    titleColor: '#92400E',
    contentColor: '#78350F',
    iconEmoji: '⚠️',
    visualSnippet:
        '[ WARNING: Safety & Precaution Advice ]\n'
        '• Wear protective gloves and goggles during spray preparation.\n'
        '• Observe recommended harvest waiting period before picking.\n'
        '• Keep out of reach of children and pet animals.\n'
        '[ /WARNING ]',
    htmlSnippet:
        '<div style="background-color: #FFFBEB; border: 1px solid #F59E0B; border-radius: 8px; padding: 16px; margin: 14px 0;">\n'
        '  <h4 style="margin: 0 0 6px 0; font-size: 15px; font-weight: 700; color: #92400E;">⚠️ Safety & Precaution Advice</h4>\n'
        '  <ul style="margin: 0 0 6px 0; padding-left: 20px; font-size: 13.5px; color: #78350F; line-height: 1.6;">\n'
        '    <li>Wear protective gloves and goggles during spray preparation.</li>\n'
        '    <li>Observe recommended harvest waiting period before picking.</li>\n'
        '    <li>Keep out of reach of children and pet animals.</li>\n'
        '  </ul>\n'
        '</div>',
  ),
  NormalBoxTemplate(
    id: 'box_card',
    title: 'Specification Card Box',
    category: 'Card Box',
    description: 'Structured purple accent card container for technical specifications',
    icon: Icons.dashboard_customize_outlined,
    accentColor: Color(0xFF7C3AED),
    defaultContent:
        '• Active Ingredient: Concentrated formulation\n'
        '• Recommended Dilution: 2 ml per liter of water\n'
        '• Shelf Life: 2 Years from manufacturing date',
    bgColor: '#F5F3FF',
    borderColor: '#7C3AED',
    titleColor: '#4C1D95',
    contentColor: '#475569',
    iconEmoji: '📋',
    visualSnippet:
        '[ CARD: Technical Specifications ]\n'
        '• Active Ingredient: Concentrated formulation\n'
        '• Recommended Dilution: 2 ml per liter of water\n'
        '• Shelf Life: 2 Years from manufacturing date\n'
        '[ /CARD ]',
    htmlSnippet:
        '<div style="border: 1px solid #7C3AED; border-radius: 8px; padding: 16px; margin: 14px 0; background-color: #F5F3FF;">\n'
        '  <h4 style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #4C1D95;">📋 Technical Specifications</h4>\n'
        '  <ul style="margin: 0 0 6px 0; padding-left: 20px; font-size: 13.5px; color: #475569; line-height: 1.6;">\n'
        '    <li>Active Ingredient: Concentrated formulation</li>\n'
        '    <li>Recommended Dilution: 2 ml per liter of water</li>\n'
        '    <li>Shelf Life: 2 Years from manufacturing date</li>\n'
        '  </ul>\n'
        '</div>',
  ),
  NormalBoxTemplate(
    id: 'box_rose',
    title: 'Crop Protection & Target Shield',
    category: 'Shield Box',
    description: 'Rose-tinted container for pest/disease targets and crop protection highlights',
    icon: Icons.shield_outlined,
    accentColor: Color(0xFFE11D48),
    defaultContent:
        '• Target Pests: Bollworms, Aphids, Whiteflies, and Thrips\n'
        '• Mode of Action: Dual-action contact and systemic protection\n'
        '• Rainfastness: Effective within 2 hours of foliar application',
    bgColor: '#FFF1F2',
    borderColor: '#E11D48',
    titleColor: '#9F1239',
    contentColor: '#881337',
    iconEmoji: '🛡️',
    visualSnippet:
        '[ BOX: Crop Protection & Target Shield ]\n'
        '• Target Pests: Bollworms, Aphids, Whiteflies, and Thrips\n'
        '[ /BOX ]',
    htmlSnippet:
        '<div style="border: 1px solid #E11D48; border-radius: 8px; padding: 16px; margin: 14px 0; background-color: #FFF1F2;">\n'
        '  <h4 style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #9F1239;">🛡️ Crop Protection & Target Shield</h4>\n'
        '  <ul style="margin: 0 0 6px 0; padding-left: 20px; font-size: 13.5px; color: #881337; line-height: 1.6;">\n'
        '    <li>Target Pests: Bollworms, Aphids, Whiteflies, and Thrips</li>\n'
        '  </ul>\n'
        '</div>',
  ),
];

String generateVisualTable({required int columns, required int rows}) {
  final buf = StringBuffer();
  buf.write('\n');
  buf.write('|');
  for (int c = 1; c <= columns; c++) {
    buf.write(' Column $c |');
  }
  buf.write('\n');
  for (int r = 1; r < rows; r++) {
    buf.write('|');
    for (int c = 1; c <= columns; c++) {
      buf.write(' Row $r Col $c |');
    }
    buf.write('\n');
  }
  buf.write('\n');
  return buf.toString();
}

String generateHtmlTable({required int columns, required int rows, String style = 'standard'}) {
  final buf = StringBuffer();
  buf.writeln('<table style="width: 100%; border-collapse: collapse; margin: 16px 0; border: 1px solid #CBD5E1;">');
  buf.writeln('  <thead>');
  buf.writeln('    <tr style="background-color: #F8FAFC;">');
  for (int c = 1; c <= columns; c++) {
    buf.writeln('      <th style="padding: 10px 14px; border: 1px solid #CBD5E1; font-weight: 700; font-size: 13px; text-align: left; color: #1E293B;">Column $c</th>');
  }
  buf.writeln('    </tr>');
  buf.writeln('  </thead>');
  buf.writeln('  <tbody>');
  for (int r = 1; r < rows; r++) {
    final rowBg = r.isEven ? 'background-color: #F8FAFC;' : 'background-color: #FFFFFF;';
    buf.writeln('    <tr style="$rowBg">');
    for (int c = 1; c <= columns; c++) {
      buf.writeln('      <td style="padding: 9px 14px; border: 1px solid #CBD5E1; font-size: 13px; color: #334155;">Row $r Col $c</td>');
    }
    buf.writeln('    </tr>');
  }
  buf.writeln('  </tbody>');
  buf.writeln('</table>');
  return buf.toString();
}

class _InsertTableDialog extends StatefulWidget {
  final bool isDark;
  final void Function(int columns, int rows, String style) onInsert;

  const _InsertTableDialog({
    required this.isDark,
    required this.onInsert,
  });

  @override
  State<_InsertTableDialog> createState() => _InsertTableDialogState();
}

class _InsertTableDialogState extends State<_InsertTableDialog> {
  int _columns = 3;
  int _rows = 3;
  String _selectedThemeId = 'emerald';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                  color: isDark ? const Color(0xFF131D33) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.table_chart_rounded, size: 20, color: Color(0xFF059669)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insert Normal Table',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Configure columns and rows to organize product specifications or data cleanly',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quick Presets
                    Text(
                      'Quick Presets',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildPresetChip('2 x 2', 2, 2, isDark, borderColor, textSecondary),
                        _buildPresetChip('2 x 3', 2, 3, isDark, borderColor, textSecondary),
                        _buildPresetChip('3 x 3 (Standard)', 3, 3, isDark, borderColor, textSecondary),
                        _buildPresetChip('4 x 3', 4, 3, isDark, borderColor, textSecondary),
                        _buildPresetChip('4 x 4', 4, 4, isDark, borderColor, textSecondary),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Dimensions Steppers
                    Row(
                      children: [
                        Expanded(
                          child: _buildDimensionStepper(
                            label: 'Columns',
                            value: _columns,
                            min: 2,
                            max: 6,
                            onChanged: (val) => setState(() => _columns = val),
                            isDark: isDark,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            cardBgColor: cardBgColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDimensionStepper(
                            label: 'Rows (incl. Header)',
                            value: _rows,
                            min: 2,
                            max: 8,
                            onChanged: (val) => setState(() => _rows = val),
                            isDark: isDark,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            cardBgColor: cardBgColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Color Themes
                    Text(
                      'Table Color Theme',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kTableThemePresets.map((preset) {
                        final isSelected = _selectedThemeId == preset.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedThemeId = preset.id),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? preset.previewColor.withValues(alpha: 0.15)
                                  : cardBgColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? preset.previewColor : borderColor,
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: preset.previewColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  preset.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? preset.previewColor : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Live Table Preview
                    Text(
                      'Live Table Preview ($_columns cols × $_rows rows)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    () {
                      final activePreset = kTableThemePresets.firstWhere(
                        (p) => p.id == _selectedThemeId,
                        orElse: () => kTableThemePresets.first,
                      );
                      final pHeaderBg = _parseHexColor(activePreset.headerBgColor);
                      final pHeaderText = _parseHexColor(activePreset.headerTextColor);
                      final pRowBg = _parseHexColor(activePreset.rowBgColor);
                      final pAltRowBg = _parseHexColor(activePreset.altRowBgColor);
                      final pRowText = _parseHexColor(activePreset.rowTextColor);
                      final pBorder = _parseHexColor(activePreset.borderColor);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Table(
                            defaultColumnWidth: const FixedColumnWidth(110),
                            border: TableBorder.all(
                              color: pBorder,
                              width: 1.2,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            children: [
                              // Header row
                              TableRow(
                                decoration: BoxDecoration(
                                  color: pHeaderBg,
                                ),
                                children: List.generate(
                                  _columns,
                                  (i) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Text(
                                      'Col ${i + 1}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: pHeaderText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Data rows
                              ...List.generate(
                                _rows - 1,
                                (r) => TableRow(
                                  decoration: BoxDecoration(
                                    color: r.isEven ? pRowBg : pAltRowBg,
                                  ),
                                  children: List.generate(
                                    _columns,
                                    (c) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Text(
                                        'R${r + 1} C${c + 1}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          color: pRowText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }(),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onInsert(_columns, _rows, _selectedThemeId);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.table_chart_rounded, size: 16),
                          label: Text(
                            'Insert Table',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    int cols,
    int rows,
    bool isDark,
    Color borderColor,
    Color textSecondary,
  ) {
    final isSelected = _columns == cols && _rows == rows;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _columns = cols;
            _rows = rows;
          });
        }
      },
      selectedColor: const Color(0xFF059669).withValues(alpha: 0.15),
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? const Color(0xFF059669) : textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF059669) : borderColor,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  Widget _buildDimensionStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color cardBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                onPressed: value > min ? () => onChanged(value - 1) : null,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                onPressed: value < max ? () => onChanged(value + 1) : null,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsertBoxDialog extends StatelessWidget {
  final bool isDark;
  final ValueChanged<NormalBoxTemplate> onInsert;

  const _InsertBoxDialog({
    required this.isDark,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
                color: isDark ? const Color(0xFF131D33) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_box_outline_blank_rounded, size: 20, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insert Box Container',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select a standard design container to structure and style your product description',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Box Templates List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: kNormalBoxTemplates.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final template = kNormalBoxTemplates[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(template.icon, size: 20, color: template.accentColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                template.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: template.accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                template.category,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: template.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                minimumSize: const Size(0, 32),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Insert',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                onInsert(template);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          template.description,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _parseHexColor(template.bgColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _parseHexColor(template.borderColor),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (template.iconEmoji.isNotEmpty) ...[
                                    Text(template.iconEmoji, style: const TextStyle(fontSize: 15)),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      '${template.category} Preview',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _parseHexColor(template.titleColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildFormattedBoxContent(
                                template.defaultContent,
                                _parseHexColor(template.contentColor),
                                _parseHexColor(template.borderColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


