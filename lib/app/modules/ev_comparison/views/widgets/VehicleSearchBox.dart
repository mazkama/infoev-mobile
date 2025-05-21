import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/ev_comparison/controllers/EvCompareController.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class EVSearchField extends StatefulWidget {
  final String hintText;
  final Function(String slug) onSelected;
  final TextEditingController? externalController;

  const EVSearchField({
    super.key,
    required this.hintText,
    required this.onSelected,
    this.externalController,
  });

  @override
  State<EVSearchField> createState() => _EVSearchFieldState();
}

class _EVSearchFieldState extends State<EVSearchField> {
  late final TextEditingController _controller;
  final EVComparisonController controller = Get.find();

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.externalController ?? TextEditingController();
  }

  void _searchVehicles(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final data = await controller.searchVehicles(query);
      setState(() {
        _results = data;
      });
    } catch (e) {
      setState(() => _results = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectVehicle(Map<String, dynamic> vehicle) {
    _controller.text = '${vehicle['brand']['name']} ${vehicle['name']}';
    widget.onSelected(vehicle['slug']);
    setState(() => _results = []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.black),
          onChanged: _searchVehicles,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.amber),
            ),
            suffixIcon:
                _isLoading
                    ? const Padding(
                      padding: EdgeInsets.all(5),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.amber,
                      ),
                    )
                    : (_controller.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black54),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _results = [];
                            });
                          },
                        )
                        : const Icon(Icons.search, color: Colors.black54)),
          ),
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SizedBox(
              height: 260,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _results.length,
                separatorBuilder:
                    (_, __) => Divider(
                      color: Colors.grey[300],
                      height: 1,
                      indent: 12,
                      endIndent: 12,
                    ),
                itemBuilder: (context, index) {
                  final vehicle = _results[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                      imageUrl: vehicle['thumbnail_url'],
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                        height: 48,
                        width: 48,
                        color: Colors.grey.shade300,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 48,
                        width: 48,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.redAccent),
                      ),
                      height: 48,
                      width: 48,
                      fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      '${vehicle['brand']['name']} ${vehicle['name']}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Tahun ${double.parse(vehicle['pivot']['value'].toString()).toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    onTap:
                        () => {
                          _selectVehicle(vehicle),
                          FocusManager.instance.primaryFocus?.unfocus(),
                        },
                    hoverColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
