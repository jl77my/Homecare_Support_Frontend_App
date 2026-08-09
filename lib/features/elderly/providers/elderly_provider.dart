// lib/features/elderly/providers/elderly_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';   
import 'package:socket_io_client/socket_io_client.dart' as IO;  
import 'package:audioplayers/audioplayers.dart'; 
import '../../../core/models/models.dart';   
import '../../auth/providers/auth_provider.dart';   
import '../services/elderly_service.dart';   

class ElderlyState {         
  final List<Reminder> reminders;         
  final List<dynamic> activeCaregivers;         
  final List<dynamic> activeFamilyMembers;         
  final bool isSosActive;         
  final bool isAudioEnabled;         
  final bool isLinked;         
  final bool isLoading;         
  final String? errorMessage;
  final String? activeReminderMessage; 

  const ElderlyState({               
    this.reminders = const [],               
    this.activeCaregivers = const [],               
    this.activeFamilyMembers = const [],               
    this.isSosActive = false,               
    this.isAudioEnabled = true,               
    this.isLinked = false,               
    this.isLoading = false,               
    this.errorMessage,
    this.activeReminderMessage, 
  });         

  ElderlyState copyWith({               
    List<Reminder>? reminders,               
    List<dynamic>? activeCaregivers,               
    List<dynamic>? activeFamilyMembers,               
    bool? isSosActive,               
    bool? isAudioEnabled,               
    bool? isLinked,               
    bool? isLoading,               
    String? errorMessage,               
    String? activeReminderMessage,
    bool clearError = false,
    bool clearReminder = false, 
  }) {               
    return ElderlyState(                     
      reminders: reminders ?? this.reminders,                     
      activeCaregivers: activeCaregivers ?? this.activeCaregivers,                     
      activeFamilyMembers: activeFamilyMembers ?? this.activeFamilyMembers,                     
      isSosActive: isSosActive ?? this.isSosActive,                     
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,                     
      isLinked: isLinked ?? this.isLinked,                     
      isLoading: isLoading ?? this.isLoading,                     
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      activeReminderMessage: clearReminder ? null : activeReminderMessage ?? this.activeReminderMessage,               
    );
  }
}

final elderlyServiceProvider = Provider<ElderlyService>((ref) => ElderlyService());   

class ElderlyNotifier extends StateNotifier<ElderlyState> {         
  ElderlyNotifier(this._service, this._ref) : super(const ElderlyState()) {          
    _initSocket();   
  }

  final ElderlyService _service;         
  final Ref _ref;         
  IO.Socket? _socket;      
  final AudioPlayer _audioPlayer = AudioPlayer(); 

  void _initSocket() {          
    const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api');          
    final socketUrl = baseUrl.replaceAll('/api', '');               
    
    _socket = IO.io(socketUrl, IO.OptionBuilder()                  
        .setTransports(['websocket', 'polling'])                  
        .enableAutoConnect()                  
        .build());          
    _socket?.connect();     

    _socket?.on('SOS_ALERT_EMITTED', (_) async {
      state = state.copyWith(isSosActive: true);
      
      try {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sounds/sos_alarm.mp3'));
      } catch (e) {
        debugPrint('Error playing emergency audio: $e');
      }
    });

    _socket?.on('MEDICATION_ALARM', (data) async {
      final medElderlyId = data['elderlyId'];
      final currentUserId = _ref.read(authProvider).user?.id;
      
      if (medElderlyId == currentUserId) {
        final msg = "Time to take: ${data['medicationName']} (${data['dosage']})";
        state = state.copyWith(activeReminderMessage: msg);
        try {
          if (state.isAudioEnabled) {
            await _audioPlayer.setReleaseMode(ReleaseMode.loop);
            await _audioPlayer.play(AssetSource('sounds/notification.mp3')); 
          }
        } catch (e) {
          debugPrint('Audio error: $e');
        }
      }
    });
  }

  void resolveReminder() {
    _audioPlayer.stop();
    state = state.copyWith(clearReminder: true);
  }

  void toggleAudio() {               
    state = state.copyWith(isAudioEnabled: !state.isAudioEnabled);         
  }

  Future<void> fetchReminders({String? elderlyId}) async {               
    final token = _ref.read(authProvider).token;               
    if (token == null) return;               
    state = state.copyWith(isLoading: true, clearError: true);               
    try {                     
      final rawList = await _service.getMedications(token, elderlyId: elderlyId);                     
      final reminders = rawList.map((json) => Reminder.fromJson(json)).toList();                            
      final isLinked = await _service.checkPairingStatus(token);                                   
      state = state.copyWith(                           
        reminders: reminders,                           
        isLinked: isLinked,                           
        isLoading: false,                     
      );                     
      await fetchCareConnections();               
    } catch (e) {                     
      state = state.copyWith(                           
        isLoading: false,                           
        errorMessage: e.toString().replaceFirst('Exception: ', ''),                     
      );               
    }         
  }

  Future<void> fetchCareConnections() async {               
    final token = _ref.read(authProvider).token;               
    if (token == null) return;               
    try {                     
      final data = await _service.getCareConnections(token);                     
      state = state.copyWith(                           
        activeCaregivers: data['caregivers'] as List<dynamic>? ?? [],                           
        activeFamilyMembers: data['familyMembers'] as List<dynamic>? ?? [],                     
      );               
    } catch (e) {                     
      state = state.copyWith(                           
        errorMessage: e.toString().replaceFirst('Exception: ', ''),                     
      );               
    }         
  }

  Future<bool> deleteReminder(String medicationId, {String? elderlyId}) async {               
    final token = _ref.read(authProvider).token;               
    if (token == null) return false;               
    state = state.copyWith(isLoading: true, clearError: true);               
    try {                     
      await _service.deleteMedication(token: token, medicationId: medicationId);                     
      await fetchReminders(elderlyId: elderlyId);                      
      return true;               
    } catch (e) {                     
      state = state.copyWith(                           
        isLoading: false,                           
        errorMessage: e.toString().replaceFirst('Exception: ', ''),                     
      );                     
      return false;               
    }         
  }

  Future<bool> deleteCareConnection(String connectionId) async {               
    final token = _ref.read(authProvider).token;               
    if (token == null) return false;               
    state = state.copyWith(isLoading: true, clearError: true);               
    try {                     
      await _service.deleteCareConnection(token, connectionId);                     
      await fetchReminders();                      
      return true;               
    } catch (e) {                     
      state = state.copyWith(                           
        isLoading: false,                           
        errorMessage: e.toString().replaceFirst('Exception: ', ''),                     
      );                     
      return false;               
    }         
  }

  Future<bool> confirmMedication(String medicationId, {String? elderlyId}) async {               
    final token = _ref.read(authProvider).token;               
    if (token == null) return false;               
    try {                     
      await _service.confirmMedication(                           
        token: token,                           
        medicationId: medicationId,                           
        status: 'Taken',                           
        elderlyId: elderlyId,                     
      );                     
      await fetchReminders(elderlyId: elderlyId);                     
      return true;               
    } catch (e) {                     
      state = state.copyWith(                           
        errorMessage: e.toString().replaceFirst('Exception: ', ''),                     
      );                     
      return false;               
    }         
  }

  Future<bool> logMood(String mood) async {               
    final token = _ref.read(authProvider).token;               
    if (token == null) return false;               
    try {                     
      await _service.logMood(token: token, mood: mood);                     
      return true;               
    } catch (e) {                     
      state = state.copyWith(                           
        errorMessage: e.toString().replaceFirst('Exception: ', ''),                     
      );                     
      return false;               
    }         
  }

  Future<void> triggerSOS() async {               
    final token = _ref.read(authProvider).token;               
    if (token == null) return;               
    state = state.copyWith(isSosActive: true);               
    try {                     
      await _service.triggerSos(token: token);               
    } catch (e) {                     
      state = state.copyWith(                           
        isSosActive: false,                           
        errorMessage: e.toString().replaceFirst('Exception: ', ''),                     
      );               
    }         
  }

  Future<void> resolveSOS() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
    state = state.copyWith(isSosActive: false);
  }

  @override
  void dispose() {
    _socket?.dispose();
    _audioPlayer.dispose(); // Clean up audio resources on dispose
    super.dispose();
  }

  Future<String?> generatePairingCode(String roleTarget) async {               
    final token = _ref.read(authProvider).token;               
    if (token == null) return null;               
    try {                     
      final res = await _service.generatePairingCode(                           
        token: token,                           
        roleTarget: roleTarget,                     
      );                     
      return res['code']?.toString();               
    } catch (e) {                     
      state = state.copyWith(                           
        errorMessage: e.toString().replaceFirst('Exception: ', ''),                     
      );                     
      return null;               
    }
  }
}

final elderlyProvider = StateNotifierProvider<ElderlyNotifier, ElderlyState>((ref) {         
  return ElderlyNotifier(ref.watch(elderlyServiceProvider), ref);   
});