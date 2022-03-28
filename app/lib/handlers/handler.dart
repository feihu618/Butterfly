import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly/cubits/settings.dart';
import 'package:butterfly/cubits/transform.dart';
import 'package:butterfly/models/elements/element.dart';
import 'package:butterfly/models/painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../dialogs/background/context.dart';
import '../dialogs/elements/general.dart';
import '../dialogs/elements/image.dart';
import '../dialogs/elements/label.dart';
import '../dialogs/select.dart';
import '../widgets/context_menu.dart';

part 'pen.dart';
part 'eraser.dart';
part 'hand.dart';
part 'label.dart';
part 'area.dart';
part 'path_eraser.dart';
part 'layer.dart';

abstract class Handler {
  const Handler();

  List<PadElement> createForegrounds() => [];
  List<Rect> createSelections() => [];

  void onTapUp(BuildContext context, TapUpDetails details) {}
  void onTapDown(BuildContext context, TapDownDetails details) {}
  void onSecondaryTapUp(BuildContext context, TapUpDetails details) {}
  void onSecondaryTapDown(BuildContext context, TapDownDetails details) {}
  void onPointerDown(BuildContext context, PointerDownEvent event) {}
  void onPointerMove(BuildContext context, PointerMoveEvent event) {}
  void onPointerUp(BuildContext context, PointerUpEvent event) {}
  void onPointerHover(BuildContext context, PointerHoverEvent event) {}
  void onLongPressEnd(BuildContext context, LongPressEndDetails details) {}

  factory Handler.fromBloc(DocumentBloc bloc, [int? index]) {
    final state = bloc.state;
    if (state is! DocumentLoadSuccess) {
      throw Exception('Invalid document state');
    }
    final painter =
        index != null ? state.document.painters[index] : state.currentPainter;
    if (painter is PenPainter) {
      return PenHandler(painter);
    }
    if (painter is EraserPainter) {
      return EraserHandler(painter);
    }
    if (painter is LabelPainter) {
      return LabelHandler(painter);
    }
    if (painter is AreaPainter) {
      return AreaHandler(painter);
    }
    if (painter is PathEraserPainter) {
      return PathEraserHandler(painter);
    }
    if (painter is LayerPainter) {
      return LayerHandler(painter);
    }
    return HandHandler();
  }
}

class _RayCastParams {
  final List<String> invisibleLayers;
  final List<PadElement> elements;
  final Offset globalPosition;
  final double selectSensitivity;
  final double size;

  const _RayCastParams(this.invisibleLayers, this.elements, this.globalPosition,
      this.selectSensitivity, this.size);
}

Future<Set<PadElement>> rayCast(
    BuildContext context, Offset localPosition) async {
  final bloc = context.read<DocumentBloc>();
  final settings = context.read<SettingsCubit>().state;
  final transform = context.read<TransformCubit>().state;
  final state = bloc.state;
  if (state is! DocumentLoadSuccess) return {};
  final globalPosition = transform.localToGlobal(localPosition);
  return compute(
      _executeRayCast,
      _RayCastParams(state.invisibleLayers, state.document.content,
          globalPosition, settings.selectSensitivity, transform.size));
}

Set<PadElement> _executeRayCast(_RayCastParams params) {
  return params.elements
      .where((element) => !params.invisibleLayers.contains(element.layer))
      .where((element) => element.hit(
          params.globalPosition, params.selectSensitivity / params.size))
      .toList()
      .reversed
      .toSet();
}
