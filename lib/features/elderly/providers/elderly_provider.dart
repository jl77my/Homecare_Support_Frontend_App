import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';   
import 'package:socket_io_client/socket_io_client.dart' as IO;  
import 'package:audioplayers/audioplayers.dart'; 
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';   
import '../../auth/providers/auth_provider.dart';   
import '../services/elderly_service.dart';   

class SosAlertData {
  final String alertId;
  final String elderlyId;
  final String elderlyName;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? triggeredAt;

  const SosAlertData({
    required this.alertId,
    required this.elderlyId,
    required this.elderlyName,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.triggeredAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory SosAlertData.fromSocket(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    return SosAlertData(
      alertId: map['alertId']?.toString() ?? '',
      elderlyId: map['elderlyId']?.toString() ?? '',
      elderlyName: map['elderlyName']?.toString() ?? 'Elderly user',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      triggeredAt: map['triggeredAt']?.toString(),
    );
  }
}

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
  final SosAlertData? activeSosAlert;

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
    this.activeSosAlert,
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
    SosAlertData? activeSosAlert,
    bool clearSosAlert = false,
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
      activeSosAlert: clearSosAlert ? null : activeSosAlert ?? this.activeSosAlert,
    );
  }
}

final elderlyServiceProvider = Provider<ElderlyService>((ref) => ElderlyService());   

class ElderlyNotifier extends StateNotifier<ElderlyState> {         
  ElderlyNotifier(this._service, this._ref) : super(const ElderlyState()) {          
    _loadAudioPreference();
    _initSocket();   
  }

  final ElderlyService _service;         
  final Ref _ref;         
  IO.Socket? _socket;      
  static const _audioPreferenceKey = 'elderly_reminder_audio_enabled';
  final AudioPlayer _reminderAudioPlayer = AudioPlayer();
  final AudioPlayer _sosAudioPlayer = AudioPlayer();

  Future<void> _loadAudioPreference() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final isEnabled = preferences.getBool(_audioPreferenceKey) ?? true;
      state = state.copyWith(isAudioEnabled: isEnabled);
    } catch (e) {
      debugPrint('Error loading reminder audio preference: $e');
    }
  }

  Future<void> _playReminderSound({required bool loop}) async {
    await _reminderAudioPlayer.stop();
    await _reminderAudioPlayer.setReleaseMode(
      loop ? ReleaseMode.loop : ReleaseMode.stop,
    );
    await _reminderAudioPlayer.play(
      AssetSource('sounds/notification.mp3'),
    );
  }

  void _initSocket() {          
    const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api');          
    final socketUrl = baseUrl.replaceAll('/api', '');               
    
    _socket = IO.io(socketUrl, IO.OptionBuilder()                  
        .setTransports(['websocket', 'polling'])                  
        .disableAutoConnect()                  
        .build());          

    _socket?.onConnect((_) {
      final token = _ref.read(authProvider).token;
      if (token != null) {
        _socket?.emit('REGISTER_USER', {'token': token});
      }
    });

    _socket?.on('SOS_ALERT_EMITTED', (data) async {
      final role = _ref.read(authProvider).user?.role.toLowerCase();
      if (role != 'caregiver' && role != 'family') return;

      final alert = SosAlertData.fromSocket(data);
      state = state.copyWith(isSosActive: true, activeSosAlert: alert);
      
      try {
        await _sosAudioPlayer.setReleaseMode(ReleaseMode.loop);
        await _sosAudioPlayer.play(AssetSource('sounds/sos_alarm.mp3'));
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
            await _playReminderSound(loop: true);
          }
        } catch (e) {
          debugPrint('Audio error: $e');
        }
      }
    });

    _socket?.connect();
  }

  Future<void> resolveReminder() async {
    await _reminderAudioPlayer.stop();
    state = state.copyWith(clearReminder: true);
  }

  Future<bool> toggleAudio() async {
    final isEnabled = !state.isAudioEnabled;
    state = state.copyWith(isAudioEnabled: isEnabled);

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_audioPreferenceKey, isEnabled);
      if (isEnabled) {
        await _playReminderSound(loop: false);
      } else {
        await _reminderAudioPlayer.stop();
      }
    } catch (e) {
      debugPrint('Error changing reminder audio: $e');
    }
    return isEnabled;
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
      Position? position;
      try {
        if (await Geolocator.isLocationServiceEnabled()) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 10),
              ),
            );
          }
        }
      } catch (e) {
        // Location must never block an emergency alert.
        debugPrint('SOS location unavailable: $e');
      }

      await _service.triggerSos(
        token: token,
        latitude: position?.latitude,
        longitude: position?.longitude,
        accuracy: position?.accuracy,
      );               
    } catch (e) {                     
      state = state.copyWith(                           
        isSosActive: false,                           
        errorMessage: e.toString().replaceFirst('Exception: ', ''),                     
      );               
    }         
  }

  Future<void> resolveSOS() async {
    try {
      await _sosAudioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
    state = state.copyWith(isSosActive: false, clearSosAlert: true);
  }

  @override
  void dispose() {
    _socket?.dispose();
    _reminderAudioPlayer.dispose();
    _sosAudioPlayer.dispose();
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

final elderlyProvider = StateNotifierProvider.autoDispose<ElderlyNotifier, ElderlyState>((ref) {         
  return ElderlyNotifier(ref.watch(elderlyServiceProvider), ref);   
});
