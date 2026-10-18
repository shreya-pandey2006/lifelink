import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import 'ui.dart';

class CitySearchField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;
  final String hintText;
  final IconData icon;

  const CitySearchField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.hintText = 'Search or enter any city (e.g. Delhi, Pune)',
    this.icon = Icons.location_city_outlined,
  });

  @override
  State<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<CitySearchField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant CitySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null &&
        widget.initialValue != _controller.text &&
        oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) {
              return kPopularCities.take(6);
            }
            return kPopularCities
                .where((c) => c.toLowerCase().contains(query))
                .take(10);
          },
          onSelected: (String selection) {
            _controller.text = selection;
            widget.onChanged(selection);
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: textEditingController,
              builder: (context, val, _) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: fieldDecoration(
                    hint: widget.hintText,
                    icon: widget.icon,
                    suffix: val.text.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(Icons.clear, size: 18, color: kMuted),
                            onPressed: () {
                              textEditingController.clear();
                              widget.onChanged('');
                            },
                          )
                        : null,
                  ),
                  validator: widget.validator ??
                      (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a city'
                          : null,
                  onChanged: (v) {
                    widget.onChanged(v.trim());
                  },
                );
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final list = options.toList();
            if (list.isEmpty) return const SizedBox.shrink();

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                shadowColor: Colors.black26,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth,
                    maxHeight: 220,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final option = list[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined,
                            size: 18, color: kPrimary),
                        title: Text(
                          option,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: kInk,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
