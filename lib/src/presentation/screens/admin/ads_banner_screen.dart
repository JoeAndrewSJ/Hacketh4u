import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/bloc/banner/banner_bloc.dart';
import '../../../core/bloc/banner/banner_event.dart';
import '../../../core/bloc/banner/banner_state.dart';
import '../../../data/models/banner_model.dart';
import '../../widgets/navigation/admin_bottom_nav_bar.dart';
import '../home/admin_home_screen.dart';

class AdsBannerScreen extends StatefulWidget {
  const AdsBannerScreen({super.key});

  @override
  State<AdsBannerScreen> createState() => _AdsBannerScreenState();
}

class _AdsBannerScreenState extends State<AdsBannerScreen> {
  final TextEditingController _youtubeUrlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<BannerBloc>().add(LoadBanners());
  }

  @override
  void dispose() {
    _youtubeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ads Banners'),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,

      ),
      body: BlocConsumer<BannerBloc, BannerState>(
        listener: (context, state) {
          if (state is BannerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BannerCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Banner uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is BannerDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Banner deleted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BannerLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is BannersLoaded) {
            if (state.banners.isEmpty) {
              return _buildEmptyState(isDark);
            }
            return _buildBannersList(state.banners, isDark);
          } else if (state is BannerError) {
            return _buildErrorState(state.message, isDark);
          }
          return _buildEmptyState(isDark);
        },
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Navigate back to main screen with the selected tab
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen(initialIndex: index)),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign,
            size: 80,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(height: 24),
          Text(
            'No Banners Yet',
            style: AppTextStyles.h2.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload your first banner image',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showCreateBannerDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Upload Banner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Banners',
            style: AppTextStyles.h2.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<BannerBloc>().add(LoadBanners());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannersList(List<BannerModel> banners, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Banners (${banners.length})',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showCreateBannerDialog();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Banner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemCount: banners.length,
              itemBuilder: (context, index) {
                return _buildBannerCard(banners[index], isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(BannerModel banner, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with enhanced design
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: DecorationImage(
                      image: NetworkImage(banner.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                      
                      // Status indicator with enhanced design
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: banner.isActive ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                banner.isActive ? Icons.check_circle : Icons.pause_circle,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                banner.isActive ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Delete button with enhanced design
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () => _showDeleteDialog(banner),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      
                      // YouTube indicator with enhanced design
                      if (banner.youtubeUrl != null && banner.youtubeUrl!.isNotEmpty)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'YouTube',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Content section with enhanced design
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date with icon
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatDate(banner.createdAt),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Action button with enhanced design
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<BannerBloc>().add(
                              ToggleBannerStatus(
                                bannerId: banner.id,
                                isActive: !banner.isActive,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: banner.isActive ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                banner.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  banner.isActive ? 'Deactivate' : 'Activate',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BannerModel banner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Banner',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this banner?',
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: const Text(
                'This action cannot be undone and will permanently remove the banner from your system.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BannerBloc>().add(
                DeleteBanner(
                  bannerId: banner.id,
                  imagePath: banner.imagePath,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateBannerDialog() {
    _youtubeUrlController.clear();
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
            title: Row(
              children: [
                Icon(Icons.campaign, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                Text(
                  'Create Banner',
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedImage != null
                          ? AppTheme.primaryLight
                          : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _selectedImage != null ? AppTheme.primaryLight.withOpacity(0.1) : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _selectedImage != null ? Icons.check_circle : Icons.image,
                          size: 48,
                          color: _selectedImage != null
                            ? AppTheme.primaryLight
                            : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedImage != null ? 'Image Selected' : 'Select Banner Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _selectedImage != null
                              ? AppTheme.primaryLight
                              : (isDark ? AppTheme.textSecondaryDark : Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(setDialogState),
                          icon: Icon(_selectedImage != null ? Icons.refresh : Icons.image),
                          label: Text(_selectedImage != null ? 'Change Image' : 'Select Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryLight,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // YouTube URL field
                  TextFormField(
                    controller: _youtubeUrlController,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      labelText: 'YouTube URL (Optional)',
                      labelStyle: TextStyle(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                      hintText: 'https://www.youtube.com/watch?v=...',
                      hintStyle: TextStyle(
                        color: isDark ? AppTheme.textSecondaryDark.withOpacity(0.5) : Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryLight,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.play_circle_outline,
                        color: AppTheme.primaryLight,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        // Basic YouTube URL validation
                        if (!value.contains('youtube.com') && !value.contains('youtu.be')) {
                          return 'Please enter a valid YouTube URL';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _selectedImage != null ? () => _createBanner(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedImage != null ? AppTheme.primaryLight : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Create Banner'),
              ),
            ],
          ),
        );
      },
    );
  }

  XFile? _selectedImage;

  Future<void> _pickImage(StateSetter setDialogState) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      setDialogState(() {
        _selectedImage = image;
      });
    }
  }

  void _createBanner(BuildContext context) {
    if (_formKey.currentState!.validate() && _selectedImage != null) {
      Navigator.pop(context);
      
      final String? youtubeUrl = _youtubeUrlController.text.trim().isEmpty 
          ? null 
          : _youtubeUrlController.text.trim();
      
      context.read<BannerBloc>().add(
        CreateBanner(
          imageFile: _selectedImage!,
          youtubeUrl: youtubeUrl,
        ),
      );
      
      // Reset the selected image
      _selectedImage = null;
    }
  }
}
