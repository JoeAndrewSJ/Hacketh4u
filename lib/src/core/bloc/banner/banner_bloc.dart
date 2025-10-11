import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/banner_repository.dart';
import '../../../data/models/banner_model.dart';
import 'banner_event.dart';
import 'banner_state.dart';

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  final BannerRepository _bannerRepository;

  BannerBloc({required BannerRepository bannerRepository})
      : _bannerRepository = bannerRepository,
        super(BannerInitial()) {
    on<LoadBanners>(_onLoadBanners);
    on<CreateBanner>(_onCreateBanner);
    on<DeleteBanner>(_onDeleteBanner);
    on<ToggleBannerStatus>(_onToggleBannerStatus);
    on<PickImage>(_onPickImage);
  }

  Future<void> _onLoadBanners(LoadBanners event, Emitter<BannerState> emit) async {
    try {
      emit(BannerLoading());
      final List<BannerModel> banners = await _bannerRepository.getBanners();
      emit(BannersLoaded(banners: banners));
    } catch (e) {
      emit(BannerError(message: e.toString()));
    }
  }

  Future<void> _onCreateBanner(CreateBanner event, Emitter<BannerState> emit) async {
    try {
      emit(BannerLoading());
      final BannerModel banner = await _bannerRepository.createBanner(event.imageFile);
      emit(BannerCreated(banner: banner));
      
      // Reload banners after creation
      final List<BannerModel> banners = await _bannerRepository.getBanners();
      emit(BannersLoaded(banners: banners));
    } catch (e) {
      emit(BannerError(message: e.toString()));
    }
  }

  Future<void> _onDeleteBanner(DeleteBanner event, Emitter<BannerState> emit) async {
    try {
      emit(BannerLoading());
      await _bannerRepository.deleteBanner(event.bannerId, event.imagePath);
      emit(BannerDeleted(bannerId: event.bannerId));
      
      // Reload banners after deletion
      final List<BannerModel> banners = await _bannerRepository.getBanners();
      emit(BannersLoaded(banners: banners));
    } catch (e) {
      emit(BannerError(message: e.toString()));
    }
  }

  Future<void> _onToggleBannerStatus(ToggleBannerStatus event, Emitter<BannerState> emit) async {
    try {
      emit(BannerLoading());
      await _bannerRepository.toggleBannerStatus(event.bannerId, event.isActive);
      emit(BannerStatusToggled(bannerId: event.bannerId, isActive: event.isActive));
      
      // Reload banners after status change
      final List<BannerModel> banners = await _bannerRepository.getBanners();
      emit(BannersLoaded(banners: banners));
    } catch (e) {
      emit(BannerError(message: e.toString()));
    }
  }

  Future<void> _onPickImage(PickImage event, Emitter<BannerState> emit) async {
    try {
      final image = await _bannerRepository.pickImage();
      if (image != null) {
        // Create banner with picked image
        add(CreateBanner(imageFile: image));
      }
    } catch (e) {
      emit(BannerError(message: e.toString()));
    }
  }
}
