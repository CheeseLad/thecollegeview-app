import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../providers/article_provider.dart';
import '../widgets/search_bar.dart' as custom_search_bar;
import '../widgets/article_list.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Article> _filteredArticles = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _filteredArticles = [];
      });
      return;
    }

    final articleProvider =
        Provider.of<ArticleProvider>(context, listen: false);
    await articleProvider.searchArticles(query);

    setState(() {
      _filteredArticles = articleProvider.articles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: custom_search_bar.SearchBar(
          controller: _searchController,
          onSearchChanged: _onSearchChanged,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _filteredArticles.isEmpty
          ? const Center(child: Text('No articles found.'))
          : ArticleList(categoryName: 'Search Results'),
    );
  }
}
