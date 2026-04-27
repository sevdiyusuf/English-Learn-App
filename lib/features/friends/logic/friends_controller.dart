import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/auth_controller.dart';
import '../../auth/models/app_user.dart';
import '../data/friends_repo.dart';
import '../models/friend_models.dart';

class FriendsState {
  FriendsState({
    required this.currentUser,
    required this.profile,
    required this.friends,
    required this.incomingRequests,
    required this.isLoading,
    this.errorMessage,
  });

  final AppUser? currentUser;
  final UserProfile? profile;
  final List<UserProfile> friends;
  final List<FriendRequest> incomingRequests;
  final bool isLoading;
  final String? errorMessage;

  FriendsState copyWith({
    AppUser? currentUser,
    UserProfile? profile,
    List<UserProfile>? friends,
    List<FriendRequest>? incomingRequests,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FriendsState(
      currentUser: currentUser ?? this.currentUser,
      profile: profile ?? this.profile,
      friends: friends ?? this.friends,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  factory FriendsState.initial() => FriendsState(
    currentUser: null,
    profile: null,
    friends: const [],
    incomingRequests: const [],
    isLoading: true,
  );
}

class FriendsController extends StateNotifier<FriendsState> {
  FriendsController(this._ref) : super(FriendsState.initial()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<List<UserProfile>>? _friendsSub;
  StreamSubscription<List<FriendRequest>>? _requestsSub;

  FriendsRepository get _repo => _ref.read(friendsRepositoryProvider);

  Future<void> _init() async {
    state = FriendsState.initial();

    final authState = _ref.read(authControllerProvider);
    final user = authState.value;
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Kullanıcı oturumu bulunamadı',
      );
      return;
    }

    try {
      final profile = await _repo.ensureUserProfile(user);

      _friendsSub?.cancel();
      _friendsSub = _repo.watchFriends(user).listen((friends) {
        state = state.copyWith(friends: friends, isLoading: false);
      });

      _requestsSub?.cancel();
      _requestsSub = _repo.watchIncomingRequests(user).listen((requests) {
        state = state.copyWith(incomingRequests: requests, isLoading: false);
      });

      state = state.copyWith(
        currentUser: user,
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> sendFriendRequestByCode(String code) async {
    final user = state.currentUser;
    if (user == null) {
      state = state.copyWith(
        errorMessage: 'Önce kullanıcı oturumu başlatılmalı',
      );
      return;
    }
    try {
      await _repo.sendFriendRequest(fromUser: user, targetCode: code);
      state = state.copyWith(errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> acceptRequest(FriendRequest request) async {
    final user = state.currentUser;
    if (user == null) return;
    await _repo.acceptRequest(request, user);
  }

  Future<void> rejectRequest(FriendRequest request) async {
    final user = state.currentUser;
    if (user == null) return;
    await _repo.rejectRequest(request, user);
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _requestsSub?.cancel();
    super.dispose();
  }
}

final friendsControllerProvider =
    StateNotifierProvider<FriendsController, FriendsState>((ref) {
      // Watch auth changes to recreate controller when user changes
      ref.watch(authControllerProvider);
      return FriendsController(ref);
    });
