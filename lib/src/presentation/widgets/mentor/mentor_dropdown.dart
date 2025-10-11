import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class Mentor {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String primaryExpertise;
  final List<String> expertiseTags;
  final int yearsOfExperience;

  const Mentor({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.primaryExpertise,
    required this.expertiseTags,
    required this.yearsOfExperience,
  });
}

class MentorDropdown extends StatefulWidget {
  final String? selectedMentorId;
  final void Function(String?) onMentorSelected;
  final List<Mentor> mentors;
  final bool isLoading;
  final String? hintText;

  const MentorDropdown({
    super.key,
    this.selectedMentorId,
    required this.onMentorSelected,
    required this.mentors,
    this.isLoading = false,
    this.hintText,
  });

  @override
  State<MentorDropdown> createState() => _MentorDropdownState();
}

class _MentorDropdownState extends State<MentorDropdown> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExpanded = false;
  List<Mentor> _filteredMentors = [];

  @override
  void initState() {
    super.initState();
    _filteredMentors = widget.mentors;
  }

  @override
  void didUpdateWidget(MentorDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mentors != widget.mentors) {
      _filteredMentors = widget.mentors;
      _filterMentors(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedMentor = widget.mentors.firstWhere(
      (mentor) => mentor.id == widget.selectedMentorId,
      orElse: () => const Mentor(
        id: '',
        name: '',
        email: '',
        primaryExpertise: '',
        expertiseTags: [],
        yearsOfExperience: 0,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Mentor',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          ),
          child: Column(
            children: [
              // Selected Mentor Display
              GestureDetector(
                onTap: widget.isLoading ? null : _toggleDropdown,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (widget.selectedMentorId != null && selectedMentor.id.isNotEmpty) ...[
                        // Mentor Avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                          backgroundImage: selectedMentor.avatarUrl != null
                              ? NetworkImage(selectedMentor.avatarUrl!)
                              : null,
                          child: selectedMentor.avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  color: AppTheme.primaryLight,
                                  size: 20,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        
                        // Mentor Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedMentor.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedMentor.primaryExpertise,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // No Mentor Selected
                        Icon(
                          Icons.person_outline,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.hintText ?? 'Select a mentor (optional)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                      
                      // Dropdown Arrow
                      if (widget.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                    ],
                  ),
                ),
              ),
              
              // Dropdown List
              if (_isExpanded) ...[
                const Divider(height: 1),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterMentors,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search mentors...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark ? AppTheme.inputBorderDark : AppTheme.inputBorderLight,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppTheme.primaryLight,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      
                      // Mentors List
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            // No Mentor Option
                            _buildMentorItem(
                              context,
                              mentor: null,
                              onTap: () => _selectMentor(null),
                            ),
                            
                            // Mentors List
                            if (_filteredMentors.isEmpty && !widget.isLoading)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No mentors found',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ..._filteredMentors.map((mentor) => _buildMentorItem(
                                context,
                                mentor: mentor,
                                onTap: () => _selectMentor(mentor.id),
                              )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMentorItem(
    BuildContext context, {
    required Mentor? mentor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = mentor?.id == widget.selectedMentorId;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withOpacity(0.1)
              : Colors.transparent,
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: AppTheme.primaryLight,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            if (mentor != null) ...[
              // Mentor Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                backgroundImage: mentor.avatarUrl != null
                    ? NetworkImage(mentor.avatarUrl!)
                    : null,
                child: mentor.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        color: AppTheme.primaryLight,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Mentor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentor.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mentor.primaryExpertise,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.work,
                          size: 14,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${mentor.yearsOfExperience} years exp.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // No Mentor Option
              Icon(
                Icons.person_off,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No mentor assigned',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            // Selection Indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleDropdown() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _filterMentors(_searchController.text);
      }
    });
  }

  void _filterMentors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMentors = widget.mentors;
      } else {
        _filteredMentors = widget.mentors.where((mentor) {
          return mentor.name.toLowerCase().contains(query.toLowerCase()) ||
                 mentor.primaryExpertise.toLowerCase().contains(query.toLowerCase()) ||
                 mentor.expertiseTags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _selectMentor(String? mentorId) {
    widget.onMentorSelected(mentorId);
    setState(() {
      _isExpanded = false;
    });
    _searchController.clear();
    _filterMentors('');
  }
}
