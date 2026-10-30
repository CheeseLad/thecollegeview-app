import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../providers/article_provider.dart';
import '../widgets/search_bar.dart' as custom_search_bar;
import '../widgets/article_list.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Article> _filteredArticles = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _filteredArticles = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final articleProvider =
          Provider.of<ArticleProvider>(context, listen: false);
      final results = await articleProvider.searchArticles(query);

      if (!mounted) return;
      setState(() {
        _filteredArticles = results;
        _isLoading = false;
        _hasSearched = true;
      });
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    setState(() {
      _searchController.clear();
      _filteredArticles = [];
      _isLoading = false;
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isInitial = !_hasSearched && _searchController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: custom_search_bar.SearchBar(
          controller: _searchController,
          onSearchChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ArticleList(
        categoryName: 'Search Results',
        articles: _filteredArticles,
        isLoading: _isLoading,
        emptyIcon: isInitial ? Icons.search : Icons.search_off,
        emptyMessage:
            isInitial ? 'Type to search articles...' : 'No articles found.',
      ),
    );
  }
}
