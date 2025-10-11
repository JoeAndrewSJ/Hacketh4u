import '../../../data/models/banner_model.dart';

abstract class BannerState {}

class BannerInitial extends BannerState {}

class BannerLoading extends BannerState {}

class BannersLoaded extends BannerState {
  final List<BannerModel> banners;

  BannersLoaded({required this.banners});
}

class BannerCreated extends BannerState {
  final BannerModel banner;

  BannerCreated({required this.banner});
}

class BannerDeleted extends BannerState {
  final String bannerId;

  BannerDeleted({required this.bannerId});
}

class BannerStatusToggled extends BannerState {
  final String bannerId;
  final bool isActive;

  BannerStatusToggled({required this.bannerId, required this.isActive});
}

class BannerError extends BannerState {
  final String message;

  BannerError({required this.message});
}
