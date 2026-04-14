import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/wp_api_service.dart';

class ContentPage extends StatefulWidget {
  final String slug;

  const ContentPage({super.key, required this.slug});

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  Future<Map<String, dynamic>> fetchContent(String slug) async {
    final response = await WpApiService.get(
      Uri.parse('https://thecollegeview.ie/wp-json/wp/v2/pages/?slug=$slug'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data[0];
      } else {
        throw Exception('No content found');
      }
    } else {
      throw Exception('Failed to load content');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Renderer'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchContent(widget.slug),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No content found'));
          } else {
            final content = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content['title']['rendered'],
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(content['content']['rendered']),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
