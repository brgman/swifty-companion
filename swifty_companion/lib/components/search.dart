import 'package:flutter/material.dart';
import 'dart:async';

class SearchWidget extends StatefulWidget {
  final SearchController controller;
  final VoidCallback onSearch;

  const SearchWidget({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (widget.controller.text.isNotEmpty) {
        widget.onSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(42.0),
      child: Column(
        children: [
          Flexible(
            flex: 2,
            child: Image.asset(
              'looney-tunes-telescope.gif',
              width: 330,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: TextField(
              controller: widget.controller,
              decoration: const InputDecoration(
                // hintText: "abergman",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => widget.onSearch(),
            ),
          ),
        ],
      ),
    );
  }
}