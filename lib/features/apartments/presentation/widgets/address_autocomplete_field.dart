import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/geo/osm_geocoding_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Campo de texto para dirección con sugerencias en tiempo real mediante OpenStreetMap.
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final ValueChanged<LocationSuggestion> onSuggestionSelected;
  final ValueChanged<String>? onChanged;
  final OsmGeocodingService? geocodingService;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSuggestionSelected,
    this.errorText,
    this.onChanged,
    this.geocodingService,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  late final OsmGeocodingService _service;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _service = widget.geocodingService ?? OsmGeocodingService();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleControllerChange);
    _focusNode.dispose();
    _debounce?.cancel();
    if (widget.geocodingService == null) {
      _service.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      // Ocultar sugerencias si pierde el foco
      setState(() => _showSuggestions = false);
    } else if (widget.controller.text.trim().length >= 3 &&
        _suggestions.isNotEmpty) {
      setState(() => _showSuggestions = true);
    }
  }

  void _handleControllerChange() {
    setState(() {});
  }

  void _onTextChanged(String text) {
    widget.onChanged?.call(text);
    _debounce?.cancel();

    final query = text.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final results = await _service.search(query);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _suggestions = results;
        _showSuggestions = results.isNotEmpty && _focusNode.hasFocus;
      });
    });
  }

  void _selectSuggestion(LocationSuggestion s) {
    _debounce?.cancel();
    widget.controller.text = s.addressLine;
    widget.onSuggestionSelected(s);
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  void _clearField() {
    widget.controller.clear();
    widget.onChanged?.call('');
    _debounce?.cancel();
    setState(() {
      _suggestions = [];
      _isLoading = false;
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final line = hasError ? Colors.red.shade400 : AppColors.blue;
    final hasText = widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: const BorderSide(color: AppColors.border),
              left: const BorderSide(color: AppColors.border),
              right: const BorderSide(color: AppColors.border),
              bottom: BorderSide(color: line, width: 2),
            ),
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            cursorColor: AppColors.navy,
            style: const TextStyle(fontSize: 15, color: AppColors.text),
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle:
                  const TextStyle(color: Color(0xFFA3ABB8), fontSize: 15),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blue,
                        ),
                      ),
                    )
                  else if (hasText)
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.muted),
                      splashRadius: 18,
                      onPressed: _clearField,
                      tooltip: 'Limpiar',
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFFA3ABB8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              widget.errorText!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
          ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 14, color: AppColors.blue),
                      const SizedBox(width: 6),
                      Text(
                        'SUGERENCIAS ENCONTRADAS (${_suggestions.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                for (int i = 0; i < _suggestions.length; i++) ...[
                  _SuggestionTile(
                    suggestion: _suggestions[i],
                    onTap: () => _selectSuggestion(_suggestions[i]),
                  ),
                  if (i < _suggestions.length - 1)
                    const Divider(height: 1, color: AppColors.divider),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(7),
                      bottomRight: Radius.circular(7),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.public, size: 12, color: AppColors.muted),
                      SizedBox(width: 4),
                      Text(
                        'Datos por OpenStreetMap Nominatim',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final LocationSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 10),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.orange,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  if (suggestion.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(
                Icons.north_west,
                size: 15,
                color: Color(0xFFA3ABB8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
