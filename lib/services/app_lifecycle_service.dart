import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'realtime_room_service.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();
  
  final RealtimeRoomService _roomService = RealtimeRoomService();
  String? _currentRoomId;
  bool _isInRoom = false;
  
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }
  
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
  
  void setCurrentRoom(String? roomId) {
    _currentRoomId = roomId;
    _isInRoom = roomId != null;
    print('🏠 App lifecycle: Current room set to $roomId');
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('📱 App lifecycle state changed to: $state');
    
    switch (state) {
      case AppLifecycleState.detached:
        _handleAppExit();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.inactive:
        // App is in transition state, don't take action
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
  }
  
  void _handleAppExit() {
    print('🚪 App is exiting, cleaning up room...');
    _leaveCurrentRoom();
  }
  
  void _handleAppPaused() {
    print('⏸️ App paused');
    // Don't leave room on pause, user might come back
    // But mark them as potentially offline
  }
  
  void _handleAppResumed() {
    print('▶️ App resumed');
    // Mark user as back online if they were in a room
  }
  
  Future<void> _leaveCurrentRoom() async {
    if (!_isInRoom || _currentRoomId == null) {
      print('No room to leave');
      return;
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('No authenticated user');
      return;
    }
    
    try {
      print('🏃‍♂️ Leaving room ${_currentRoomId} due to app exit');
      await _roomService.leaveRoom(_currentRoomId!);
      _currentRoomId = null;
      _isInRoom = false;
      print('✅ Successfully left room on app exit');
    } catch (e) {
      print('❌ Error leaving room on app exit: $e');
    }
  }
  
  // Manual cleanup method for screens to call
  Future<void> cleanupOnExit() async {
    await _leaveCurrentRoom();
  }
}