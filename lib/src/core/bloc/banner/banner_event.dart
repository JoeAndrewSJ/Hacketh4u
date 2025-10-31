import 'package:image_picker/image_picker.dart';

abstract class BannerEvent {}

class LoadBanners extends BannerEvent {}

class CreateBanner extends BannerEvent {
  final XFile imageFile;
  final String? youtubeUrl;

  CreateBanner({required this.imageFile, this.youtubeUrl});
}

class DeleteBanner extends BannerEvent {
  final String bannerId;
  final String imagePath;

  DeleteBanner({required this.bannerId, required this.imagePath});
}

class ToggleBannerStatus extends BannerEvent {
  final String bannerId;
  final bool isActive;

  ToggleBannerStatus({required this.bannerId, required this.isActive});
}

class PickImage extends BannerEvent {}
