import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

@Freezed(toJson: false, fromJson: false)
abstract class HudConfig with _$HudConfig {
  const factory HudConfig({
    required int version,
    required HudTheme theme,
    required Map<String, HudLayout> layouts,
  }) = _HudConfig;

  factory HudConfig.fromJson(Map<String, dynamic> json) {
    return HudConfig(
      version: json['version'] as int,
      theme: HudTheme.fromJson(json['theme'] as Map<String, dynamic>),
      layouts: (json['layouts'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, HudLayout.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}

@Freezed(toJson: false, fromJson: false)
abstract class HudTheme with _$HudTheme {
  const factory HudTheme({
    required String background,
    required String border,
    required String text,
    required num borderRadius,
  }) = _HudTheme;

  factory HudTheme.fromJson(Map<String, dynamic> json) => HudTheme(
        background: json['background'] as String,
        border: json['border'] as String,
        text: json['text'] as String,
        borderRadius: json['borderRadius'] as num,
      );
}

@Freezed(toJson: false, fromJson: false)
abstract class HudLayout with _$HudLayout {
  const factory HudLayout({
    required List<num> canvasSize,
    required HudElement root,
  }) = _HudLayout;

  factory HudLayout.fromJson(Map<String, dynamic> json) => HudLayout(
        canvasSize: (json['canvasSize'] as List).cast<num>(),
        root: HudElement.fromJson(json['root'] as Map<String, dynamic>),
      );
}

sealed class HudElement {
  const HudElement();

  String get id;
  int? get row;
  int? get col;
  int? get rowSpan;
  int? get colSpan;
  Map<String, dynamic>? get style;
  String? get description;

  factory HudElement.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'grid':
        return HudGrid.fromJson(json);
      case 'label':
        return HudLabel.fromJson(json);
      case 'button':
        return HudButton.fromJson(json);
      case 'icon':
        return HudIcon.fromJson(json);
      case 'list':
        return HudList.fromJson(json);
      case 'cardhand':
        return HudCardHand.fromJson(json);
      default:
        throw FormatException('Unknown HUD element type: $type (id=${json['id']})');
    }
  }
}

class HudGrid extends HudElement {
  @override
  final String id;
  final List<String> rows;
  final List<String> cols;
  final List<HudElement> children;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudGrid({
    required this.id,
    required this.rows,
    required this.cols,
    required this.children,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudGrid.fromJson(Map<String, dynamic> json) => HudGrid(
        id: json['id'] as String,
        rows: (json['rows'] as List).cast<String>(),
        cols: (json['cols'] as List).cast<String>(),
        children: (json['children'] as List? ?? [])
            .map((c) => HudElement.fromJson(c as Map<String, dynamic>))
            .toList(),
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudLabel extends HudElement {
  @override
  final String id;
  final String? text;
  final String? binding;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudLabel({
    required this.id,
    this.text,
    this.binding,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudLabel.fromJson(Map<String, dynamic> json) => HudLabel(
        id: json['id'] as String,
        text: json['text'] as String?,
        binding: json['binding'] as String?,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudButton extends HudElement {
  @override
  final String id;
  final String? text;
  final String? action;
  final String? selectedWhen;
  final Map<String, dynamic>? selectedStyle;
  final String? group;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudButton({
    required this.id,
    this.text,
    this.action,
    this.selectedWhen,
    this.selectedStyle,
    this.group,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudButton.fromJson(Map<String, dynamic> json) => HudButton(
        id: json['id'] as String,
        text: json['text'] as String?,
        action: json['action'] as String?,
        selectedWhen: json['selectedWhen'] as String?,
        selectedStyle: json['selectedStyle'] as Map<String, dynamic>?,
        group: json['group'] as String?,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudIcon extends HudElement {
  @override
  final String id;
  final String name;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudIcon({
    required this.id,
    required this.name,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudIcon.fromJson(Map<String, dynamic> json) => HudIcon(
        id: json['id'] as String,
        name: json['name'] as String,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudList extends HudElement {
  @override
  final String id;
  final int maxItems;
  final String itemBinding;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudList({
    required this.id,
    required this.maxItems,
    required this.itemBinding,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudList.fromJson(Map<String, dynamic> json) => HudList(
        id: json['id'] as String,
        maxItems: json['maxItems'] as int,
        itemBinding: json['itemBinding'] as String,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}

class HudCardHand extends HudElement {
  @override
  final String id;
  @override
  final int? row;
  @override
  final int? col;
  @override
  final int? rowSpan;
  @override
  final int? colSpan;
  @override
  final Map<String, dynamic>? style;
  @override
  final String? description;

  const HudCardHand({
    required this.id,
    this.row,
    this.col,
    this.rowSpan,
    this.colSpan,
    this.style,
    this.description,
  });

  factory HudCardHand.fromJson(Map<String, dynamic> json) => HudCardHand(
        id: json['id'] as String,
        row: json['row'] as int?,
        col: json['col'] as int?,
        rowSpan: json['rowSpan'] as int?,
        colSpan: json['colSpan'] as int?,
        style: json['style'] as Map<String, dynamic>?,
        description: json['description'] as String?,
      );
}
