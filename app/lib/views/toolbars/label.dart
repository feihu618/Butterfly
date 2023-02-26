import 'package:butterfly/actions/packs.dart';
import 'package:butterfly/dialogs/color_pick.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:butterfly_api/butterfly_text.dart' as text;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lw_sysinfo/lw_sysinfo.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../bloc/document_bloc.dart';
import '../../models/text.dart';

class LabelToolbarView extends StatelessWidget {
  final TextContext value;
  final ValueChanged<TextContext> onChanged;
  final ScrollController _scrollController = ScrollController();

  LabelToolbarView({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DocumentBloc>();
    final state = bloc.state;
    if (state is! DocumentLoadSuccess) return Container();
    final document = state.document;
    final paragraph = value.getDefinedProperty(document) ??
        const text.DefinedParagraphProperty();
    final span = value.getDefinedSpanProperty(document);
    void updateSpan(text.DefinedSpanProperty property) {
      final selection = value.selection;
      var element = value.element;
      if (element == null) {
        onChanged(value.copyWith(
            forcedProperty: text.ParagraphProperty.defined(
          span: property,
        )));
        return;
      }
      if (selection == null || selection.start == selection.end) {
        final currentParagraphProperty =
            document.getStyle(element.styleSheet).resolveParagraphProperty(
                  element.area.paragraph.property,
                );
        element = element.copyWith(
          area: element.area.copyWith(
            paragraph: element.area.paragraph.copyWith(
              property: currentParagraphProperty?.copyWith(
                    span: property,
                  ) ??
                  element.area.paragraph.property,
            ),
          ),
        );
      } else {
        element = element.copyWith(
          area: element.area.copyWith(
            paragraph: element.area.paragraph.updateSpans(
                selection.start, selection.end - selection.start, (span) {
              return span.copyWith(property: property);
            }),
          ),
        );
      }
      onChanged(value.copyWith(element: element));
    }

    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(PhosphorIcons.articleLight),
                          isSelected: value.isParagraph(),
                          onPressed: value.area == null
                              ? null
                              : () => onChanged(value.copyWith(
                                  forceParagraph: !value.isParagraph())),
                        ),
                        const SizedBox(width: 16),
                        PopupMenuButton(
                          icon: const Icon(PhosphorIcons.packageLight),
                          tooltip: AppLocalizations.of(context).pack,
                          initialValue: value.styleSheet?.pack,
                          itemBuilder: (ctx) => <PopupMenuEntry>[
                            ...document.packs.map((e) {
                              return PopupMenuItem(
                                value: e.name,
                                child: Text(e.name),
                              );
                            }).toList(),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: null,
                              onTap: () {
                                Navigator.pop(ctx);
                                Actions.invoke(
                                  context,
                                  PacksIntent(context),
                                );
                              },
                              child: Text(AppLocalizations.of(context).packs),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: DropdownMenu<String>(
                            dropdownMenuEntries: const [
                              DropdownMenuEntry(
                                label: 'Heading 1',
                                value: 'Heading 1',
                              ),
                            ],
                            onSelected: (value) {},
                            label: Text(AppLocalizations.of(context).style),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      children: [
                        ToggleButtons(
                          isSelected: text.VerticalAlignment.values
                              .map((e) =>
                                  e == value.area?.areaProperty.alignment)
                              .toList(),
                          onPressed: value.area == null ? null : (value) {},
                          children: const [
                            Icon(PhosphorIcons.alignTopLight),
                            Icon(PhosphorIcons.alignCenterVerticalLight),
                            Icon(PhosphorIcons.alignBottomLight),
                          ],
                        ),
                        const SizedBox(width: 16),
                        ToggleButtons(
                          isSelected: text.HorizontalAlignment.values
                              .map((e) => e == paragraph.alignment)
                              .toList(),
                          children: const [
                            Icon(PhosphorIcons.textAlignLeftLight),
                            Icon(PhosphorIcons.textAlignCenterLight),
                            Icon(PhosphorIcons.textAlignRightLight),
                            Icon(PhosphorIcons.textAlignJustifyLight),
                          ],
                          onPressed: (current) {
                            onChanged(value.copyWith(
                              forcedProperty: paragraph.copyWith(
                                alignment:
                                    text.HorizontalAlignment.values[current],
                              ),
                            ));
                          },
                        ),
                        const SizedBox(width: 32),
                        FutureBuilder<List<String>?>(
                          future: Future.value(SysInfo.getFonts()),
                          builder: (context, snapshot) {
                            return DropdownMenu<String>(
                              dropdownMenuEntries: snapshot.data
                                      ?.map((e) => DropdownMenuEntry<String>(
                                            value: e,
                                            label: e,
                                          ))
                                      .toList() ??
                                  [],
                              enableFilter: true,
                              onSelected: (value) {
                                if (kDebugMode) {
                                  print(value);
                                }
                              },
                              width: 200,
                              label:
                                  Text(AppLocalizations.of(context).fontFamily),
                              inputDecorationTheme:
                                  const InputDecorationTheme(filled: true),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).size,
                              filled: true,
                              floatingLabelAlignment:
                                  FloatingLabelAlignment.center,
                              alignLabelWithHint: true,
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            initialValue: span.size.toString(),
                            onChanged: (current) => updateSpan(
                              span.copyWith(
                                size: double.tryParse(current) ?? span.size,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(32),
                          ),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Color(span.color),
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(32),
                              ),
                            ),
                          ),
                          onTap: () async {
                            final result = await showDialog<int>(
                              context: context,
                              builder: (_) => BlocProvider.value(
                                value: context.read<DocumentBloc>(),
                                child: ColorPickerDialog(
                                  defaultColor: Color(span.color),
                                ),
                              ),
                            );
                            if (result == null) return;
                            onChanged(value.copyWith(
                              forcedProperty: paragraph.copyWith(
                                span: span.copyWith(
                                  color: result,
                                ),
                              ),
                            ));
                          },
                        ),
                        const SizedBox(width: 16),
                        ToggleButtons(
                          isSelected: [
                            span.fontWeight != text.kFontWeightNormal,
                            span.italic,
                            span.underline,
                          ],
                          children: [
                            GestureDetector(
                              child: const Icon(PhosphorIcons.textBolderLight),
                              onLongPressEnd: (details) {
                                final RenderObject? overlay =
                                    Overlay.of(context)
                                        .context
                                        .findRenderObject();
                                final RenderBox referenceBox =
                                    context.findRenderObject() as RenderBox;
                                var tapPosition = referenceBox
                                    .globalToLocal(details.globalPosition);
                                showMenu(
                                  context: context,
                                  position: RelativeRect.fromRect(
                                      Rect.fromLTWH(tapPosition.dx,
                                          tapPosition.dy, 30, 30),
                                      Rect.fromLTWH(
                                          0,
                                          0,
                                          overlay!.paintBounds.size.width,
                                          overlay.paintBounds.size.height)),
                                  initialValue:
                                      FontWeight.values[span.fontWeight],
                                  items: List.generate(FontWeight.values.length,
                                      (index) {
                                    var text = ((index + 1) * 100).toString();
                                    if (index == 3) {
                                      text =
                                          AppLocalizations.of(context).normal;
                                    } else if (index == 6) {
                                      text = AppLocalizations.of(context).bold;
                                    }
                                    return PopupMenuItem(
                                        value: FontWeight.values[index],
                                        child: Text(text),
                                        onTap: () {
                                          updateSpan(
                                            span.copyWith(
                                              fontWeight: index,
                                            ),
                                          );
                                          Navigator.pop(context);
                                        });
                                  }),
                                );
                              },
                            ),
                            const Icon(PhosphorIcons.textItalicLight),
                            const Icon(PhosphorIcons.textUnderlineLight),
                          ],
                          onPressed: (current) {
                            switch (current) {
                              case 0:
                                updateSpan(
                                  span.copyWith(
                                    fontWeight: span.fontWeight ==
                                            text.kFontWeightNormal
                                        ? text.kFontWeightBold
                                        : text.kFontWeightNormal,
                                  ),
                                );
                                break;
                              case 1:
                                updateSpan(
                                  span.copyWith(
                                    italic: !span.italic,
                                  ),
                                );
                                break;
                              case 2:
                                updateSpan(
                                  span.copyWith(
                                    underline: !span.underline,
                                  ),
                                );
                                break;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
