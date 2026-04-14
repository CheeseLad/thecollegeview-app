import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/page_content.dart';
import '../services/wp_api_service.dart';

class PageContentProvider with ChangeNotifier {
  PageContent? _aboutContent;
  ContactInfo? _contactInfo;
  bool _loading = false;
  String? _error;

  PageContent? get aboutContent => _aboutContent;
  ContactInfo? get contactInfo => _contactInfo;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchAboutContent() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to fetch from WordPress pages endpoint first
      final response = await WpApiService.get(
        Uri.parse('https://thecollegeview.ie/wp-json/wp/v2/pages?slug=about'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          _aboutContent = PageContent.fromJson(data[0]);
        } else {
          // Fallback to static content if no page found
          _aboutContent = _getStaticAboutContent();
        }
      } else {
        // Fallback to static content on API error
        _aboutContent = _getStaticAboutContent();
      }
    } catch (e) {
      _error = e.toString();
      // Fallback to static content on error
      _aboutContent = _getStaticAboutContent();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchContactInfo() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to fetch from WordPress pages endpoint first
      final response = await WpApiService.get(
        Uri.parse('https://thecollegeview.ie/wp-json/wp/v2/pages?slug=contact'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // Parse contact info from page content
          _contactInfo = _parseContactInfoFromContent(data[0]);
        } else {
          // Fallback to static contact info
          _contactInfo = _getStaticContactInfo();
        }
      } else {
        // Fallback to static contact info on API error
        _contactInfo = _getStaticContactInfo();
      }
    } catch (e) {
      _error = e.toString();
      // Fallback to static contact info on error
      _contactInfo = _getStaticContactInfo();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  PageContent _getStaticAboutContent() {
    return PageContent(
      id: 0,
      title: 'About',
      content: '''
        <p>The College View is Dublin City University's only student newspaper, independently run voluntarily by students affiliated to DCU's Journalism Society. The newspaper was first published in 1999 after changing its name from The Bullsheet, its predecessor.</p>
        
        <p>The College View has nine sections – News, Opinions, Features, Irish, Sports, Lifestyle, Satire, Science and Tech and our arts section, The Hype. These sections cover everything from DCU student issues to national student issues, humour and satire to life through the eyes of students, as well as extensive sports coverage and analysis. The Irish section is written and edited by students studying Journalism through Irish in DCU.</p>
        
        <p>The College View is published fortnightly on Wednesday, with six issues per semester and is circulated among 12,000 students as well as DCU lecturers and staff.</p>
        
        <h3>Community standards and participation guidelines</h3>
        
        <p>The College View reserves the right to delete comments which it deems abusive. Such comments are deemed to be directly insulting, racist, sexist, xenophobic, or homophobic to other readers or its staff of journalists and writers.</p>
        
        <p>The College View welcomes criticism and opposing viewpoints through constructive and rational debate and wishes to create an atmosphere which encourages an open dialogue.</p>
      ''',
      excerpt: 'About The College View - DCU\'s Independent Student Newspaper',
      link: 'https://thecollegeview.ie/about/',
      slug: 'about',
    );
  }

  ContactInfo _getStaticContactInfo() {
    return ContactInfo(
      editorInChief: 'Katie O\'Shaughnessy',
      editorInChiefEmail: 'editor@thecollegeview.ie',
      deputyEditor: 'Leonor Selas Amaral',
      deputyEditorEmail: 'deputyeditor@thecollegeview.ie',
      newsEditors: 'Annu Mandal & Adam Van Eekeren',
      newsEmail: 'news@thecollegeview.ie',
      opinionFeaturesEditors: 'Ciara McGuinness, Erin Reel & Zoe Percival',
      opinionEmail: 'opinion@thecollegeview.ie',
      featuresEmail: 'features@thecollegeview.ie',
      sportsEditors: 'Torna Mulconry, Ross Flanagan & Tiarnan O\'Kelly',
      sportsEmail: 'sports@thecollegeview.ie',
      lifestyleEditors: 'Ruby Hegarty & Leah Doherty',
      lifestyleEmail: 'lifestyle@thecollegeview.ie',
      hypeEditors: 'Dylan Hand & Erica Elliott',
      hypeEmail: 'thehype@thecollegeview.ie',
      satireEditors: 'Ailish Connor & Shane Meleady',
      satireEmail: 'satire@thecollegeview.ie',
      irishEditors: 'Harry Byrne & Aisling O\'Kane',
      irishEmail: 'gaeilge@thecollegeview.ie',
      productionEmail: 'production@thecollegeview.ie',
      webmaster: 'Jake Farrell',
      webmasterEmail: 'webmaster@dcumps.ie',
    );
  }

  ContactInfo _parseContactInfoFromContent(Map<String, dynamic> pageData) {
    // This would parse the contact information from the WordPress page content
    // For now, return static data as fallback
    return _getStaticContactInfo();
  }
}
