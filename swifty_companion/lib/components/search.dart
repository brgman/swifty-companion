import 'package:flutter/material.dart';

class SearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final String? accessToken;

  const SearchWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.accessToken,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(42.0),
      child: Column(
      children: [
        Image.asset(
          'looney-tunes-telescope.gif',
          width: 350,
          height: 350,
          fit: BoxFit.contain,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "abergman",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (_) => onSearch(),
              ),
            ),

            const SizedBox(width: 12),
            
            ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Icon(Icons.send),
            ),
          ],
        )
      ]
    ),
    );
  }
}