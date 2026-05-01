import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import 'add_amenity_screen.dart';
import 'add_document_screen.dart';

class SocietyInfoScreen extends StatefulWidget {
  const SocietyInfoScreen({super.key});

  @override
  State<SocietyInfoScreen> createState() => _SocietyInfoScreenState();
}

class _SocietyInfoScreenState extends State<SocietyInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<dynamic> _amenities = [];
  List<dynamic> _documents = [];
  bool _isLoadingAmenities = true;
  bool _isLoadingDocuments = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Update FAB when swipe completes
      }
    });
    _fetchAmenities();
    _fetchDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAmenities() async {
    setState(() => _isLoadingAmenities = true);
    try {
      final response = await _apiService.get(ApiConstants.amenities);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _amenities = data is List ? data : (data['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching amenities: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAmenities = false);
    }
  }

  Future<void> _fetchDocuments() async {
    setState(() => _isLoadingDocuments = true);
    try {
      final response = await _apiService.get(ApiConstants.documents);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _documents = data is List ? data : (data['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching documents: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDocuments = false);
    }
  }

  IconData _getAmenityIcon(String category) {
    switch (category) {
      case 'gym': return Icons.fitness_center;
      case 'pool': return Icons.pool;
      case 'garden': return Icons.park;
      case 'clubhouse': return Icons.house;
      case 'playground': return Icons.sports_tennis;
      case 'parking': return Icons.local_parking;
      case 'hall': return Icons.event_seat;
      case 'library': return Icons.local_library;
      case 'sports': return Icons.sports_basketball;
      default: return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Info'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Amenities'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAmenitiesTab(),
          _buildDocumentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_tabController.index == 0) {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAmenityScreen()));
            if (result == true) _fetchAmenities();
          } else {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDocumentScreen()));
            if (result == true) _fetchDocuments();
          }
        },
        backgroundColor: AppTheme.primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Amenity' : 'Add Document',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAmenitiesTab() {
    if (_isLoadingAmenities) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_amenities.isEmpty) {
      return const Center(child: Text('No amenities added yet.', style: TextStyle(color: Colors.grey)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _amenities.length,
      itemBuilder: (context, index) {
        final amenity = _amenities[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: amenity['image'] != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            amenity['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(_getAmenityIcon(amenity['category']), size: 48, color: AppTheme.primaryColor),
                          ),
                        )
                      : Icon(_getAmenityIcon(amenity['category']), size: 48, color: AppTheme.primaryColor),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        amenity['name'] ?? 'Unnamed',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (amenity['location'] != null && amenity['location'].isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                amenity['location'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (amenity['timings'] != null && amenity['timings'].isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                amenity['timings'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (amenity['caretaker_name'] != null && amenity['caretaker_name'].isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                amenity['caretaker_name'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentsTab() {
    if (_isLoadingDocuments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_documents.isEmpty) {
      return const Center(child: Text('No documents uploaded yet.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description, color: Colors.blue),
            ),
            title: Text(doc['title'] ?? 'Document', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Tap to view or download'),
            trailing: const Icon(Icons.download, color: AppTheme.primaryColor),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading document...')),
              );
            },
          ),
        );
      },
    );
  }
}
