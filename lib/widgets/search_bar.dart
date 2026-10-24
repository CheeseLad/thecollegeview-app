import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearchChanged;
  final VoidCallback? onClear;

  const SearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onChanged: (value) => onSearchChanged(),
      decoration: InputDecoration(
        hintText: 'Search articles...',
        border: InputBorder.none,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  if (onClear != null) {
                    onClear!();
                  } else {
                    onSearchChanged();
                  }
                },
              )
            : null,
      ),
    );
  }
}
