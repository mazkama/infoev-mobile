import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:infoev/app/modules/charger_station/controllers/ChargerStationController.dart';
import 'package:infoev/app/styles/app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  final ChargerStationController controller;

  const SearchBarWidget({super.key, required this.controller});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool isSearchFocused = false;
  final debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      setState(() {
        isSearchFocused = focusNode.hasFocus;
        if (!focusNode.hasFocus) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              widget.controller.citySuggestions.clear();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: textController,
            focusNode: focusNode,
            onChanged: (value) {
              if (value.length >= 2) {
                debouncer.run(() {
                  widget.controller.suggestCities(value);
                });
              } else {
                widget.controller.citySuggestions.clear();
              }
            },
            onSubmitted: (value) {
              widget.controller.searchLocation(value);
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            style: const TextStyle(color: AppColors.textColor),
            decoration: InputDecoration(
              hintText: 'Cari lokasi...',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textColor),
              suffixIcon:
                  textController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textColor,
                        ),
                        onPressed: () {
                          textController.clear();
                          widget.controller.citySuggestions.clear();
                          setState(() {}); // Force rebuild
                        },
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),

        // Suggestions Container - updated for CitySuggestion objects
        Obx(() {
          final suggestions = widget.controller.citySuggestions;
          final isLoading = widget.controller.isSuggestLoading.value;

          if (!isSearchFocused || (suggestions.isEmpty && !isLoading)) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child:
                isLoading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(color: AppColors.secondaryColor),
                      ),
                    )
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            suggestions[index]
                                .name, // Use .name property from CitySuggestion
                            style: const TextStyle(color: AppColors.textColor),
                          ),
                          leading: const Icon(
                            Icons.location_city,
                            color: AppColors.secondaryColor,
                          ),
                          onTap: () {
                            textController.text = suggestions[index].name;
                            widget.controller.searchLocation(
                              suggestions[index].name,
                            );
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                    ),
          );
        }),

        // Status indicator
        Obx(() {
          if (widget.controller.isLoading.value) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.secondaryColor),
              ),
            );
          } else if (widget.controller.hasError.value) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.controller.errorMessage.value,
                style: const TextStyle(color: AppColors.errorColor),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }),
      ],
    );
  }
}

// Debouncer class
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
