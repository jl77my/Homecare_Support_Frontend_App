// lib/features/caregiver/providers/caregiver_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:socket_io_client/socket_io_client.dart' as IO; 
import '../../../core/models/models.dart'; 
import '../../auth/providers/auth_provider.dart'; 
import '../services/caregiver_service.dart'; 

class CaregiverState {   
  final List<CareTask> tasks;   
  final List<HealthVitals> vitals;   
  final List<CareReport> reports;   
  final List<Map<String, String>> assignedSeniors;   
  final List<ChatMessage> currentChatMessages;   
  final List<dynamic> activeCaregivers;   
  final List<dynamic> activeFamilyMembers;   
  final String activeElderlyId;   
  final bool isLoading;   
  final String? errorMessage;
  final String? activeReminderMessage; 

  const CaregiverState({     
    this.tasks = const [],     
    this.vitals = const [],     
    this.reports = const [],     
    this.assignedSeniors = const [],     
    this.currentChatMessages = const [],     
    this.activeCaregivers = const [],     
    this.activeFamilyMembers = const [],     
    this.activeElderlyId = '',     
    this.isLoading = false,     
    this.errorMessage,
    this.activeReminderMessage, 
  });   

  CaregiverState copyWith({     
    List<CareTask>? tasks,     
    List<HealthVitals>? vitals,     
    List<CareReport>? reports,     
    List<Map<String, String>>? assignedSeniors,     
    List<ChatMessage>? currentChatMessages,     
    List<dynamic>? activeCaregivers,     
    List<dynamic>? activeFamilyMembers,     
    String? activeElderlyId,     
    bool? isLoading,     
    String? errorMessage,
    String? activeReminderMessage, 
    bool clearError = false,
    bool clearReminder = false, 
  }) {     
    return CaregiverState(       
      tasks: tasks ?? this.tasks,       
      vitals: vitals ?? this.vitals,       
      reports: reports ?? this.reports,       
      assignedSeniors: assignedSeniors ?? this.assignedSeniors,       
      currentChatMessages: currentChatMessages ?? this.currentChatMessages,       
      activeCaregivers: activeCaregivers ?? this.activeCaregivers,       
      activeFamilyMembers: activeFamilyMembers ?? this.activeFamilyMembers,       
      activeElderlyId: activeElderlyId ?? this.activeElderlyId,       
      isLoading: isLoading ?? this.isLoading,       
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      activeReminderMessage: clearReminder ? null : activeReminderMessage ?? this.activeReminderMessage,     
    );
  }
}

final caregiverServiceProvider = Provider<CaregiverService>((ref) => CaregiverService()); 

class CaregiverNotifier extends StateNotifier<CaregiverState> {   
  CaregiverNotifier(this._service, this._ref) : super(const CaregiverState()) {
    _initSocket(); 
  }
  
  final CaregiverService _service;   
  final Ref _ref;
  IO.Socket? _socket; 

  void _initSocket() {
    const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api');
    final socketUrl = baseUrl.replaceAll('/api', '');

    _socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .build());
    _socket?.connect();

    _socket?.on('MEDICATION_ALARM', (data) {
      final medElderlyId = data['elderlyId'];
      final isAssigned = state.assignedSeniors.any((s) => s['elderlyId'] == medElderlyId);
      
      if (isAssigned) {
        final msg = "${data['elderlyName']} needs to take: ${data['medicationName']} (${data['dosage']})";
        state = state.copyWith(activeReminderMessage: msg);
      }
    });
  }

  void resolveReminder() {
    state = state.copyWith(clearReminder: true);
  }

  String? get _token => _ref.read(authProvider).token;   

  Future<bool> pairWithElderly(String code) async {     
    final token = _token;     
    if (token == null) return _handleAuthError();     
    state = state.copyWith(isLoading: true, clearError: true);     
    try {       
      await _service.pairWithElderly(token: token, code: code);       
      await fetchAssignedSeniors();       
      state = state.copyWith(isLoading: false);       
      return true;     
    } catch (e) {       
      return _handleException(e);     
    }   
  }

  Future<void> fetchAssignedSeniors() async {     
    final token = _token;     
    if (token == null) return;     
    try {       
      final seniors = await _service.getAssignedSeniors(token);       
      String currentActive = state.activeElderlyId;       
      if (currentActive.isEmpty && seniors.isNotEmpty) {         
        currentActive = seniors.first['elderlyId'] ?? '';       
      }       
      state = state.copyWith(         
        assignedSeniors: seniors,         
        activeElderlyId: currentActive,       
      );       
      if (currentActive.isNotEmpty) {         
        await fetchCareConnections(currentActive);         
        await fetchCareTasks(currentActive);       
      }     
    } catch (e) {       
      _handleException(e);     
    }   
  }

  void switchElderlyContext(String elderlyId) {     
    state = state.copyWith(activeElderlyId: elderlyId);     
    fetchCareConnections(elderlyId);     
    fetchCareTasks(elderlyId);   
  }

  Future<void> fetchCareConnections(String elderlyId) async {     
    final token = _token;     
    if (token == null) return;     
    try {       
      final data = await _service.getCareConnections(token, elderlyId);       
      state = state.copyWith(         
        activeCaregivers: data['caregivers'] as List<dynamic>? ?? [],         
        activeFamilyMembers: data['familyMembers'] as List<dynamic>? ?? [],       
      );     
    } catch (e) {       
      _handleException(e);     
    }   
  }

  Future<void> fetchCareTasks(String elderlyId) async {     
    final token = _token;     
    if (token == null) return;     
    try {       
      final rawTasks = await _service.getCareTasks(         
        token: token,         
        patientId: elderlyId,       
      );       
      final parsedTasks = rawTasks.map((json) => CareTask.fromJson(json)).toList();       
      state = state.copyWith(tasks: parsedTasks);     
    } catch (e) {       
      _handleException(e);     
    }   
  }

  Future<bool> createTask({     
    required String title,     
    required String description,     
    required String dueDate,     
    required String assignedTo,   
  }) async {     
    final token = _token;     
    if (token == null) return _handleAuthError();     
    state = state.copyWith(isLoading: true, clearError: true);     
    try {       
      await _service.createTask(         
        token: token,         
        title: title,         
        description: description,         
        dueDate: dueDate,         
        assignedTo: assignedTo,       
      );       
      await fetchCareTasks(assignedTo);       
      state = state.copyWith(isLoading: false);       
      return true;     
    } catch (e) {       
      return _handleException(e);     
    }   
  }

  Future<bool> updateTaskStatus(String taskId, String status) async {     
    final token = _token;     
    if (token == null) return _handleAuthError();     
    state = state.copyWith(isLoading: true, clearError: true);     
    try {       
      await _service.updateTaskStatus(         
        token: token,         
        taskId: taskId,         
        status: status,       
      );              
      if (state.activeElderlyId.isNotEmpty) {         
        await fetchCareTasks(state.activeElderlyId);       
      }              
      state = state.copyWith(isLoading: false);       
      return true;     
    } catch (e) {       
      return _handleException(e);     
    }   
  }

  Future<bool> deleteCareConnection(String connectionId) async {     
    final token = _token;     
    if (token == null) return _handleAuthError();     
    state = state.copyWith(isLoading: true, clearError: true);     
    try {       
      await _service.deleteCareConnection(token, connectionId);       
      if (state.activeElderlyId.isNotEmpty) {         
        await fetchCareConnections(state.activeElderlyId);       
      }       
      await fetchAssignedSeniors();       
      state = state.copyWith(isLoading: false);       
      return true;     
    } catch (e) {       
      return _handleException(e);     
    }   
  }

  Future<void> fetchChatMessages(String elderlyId) async {     
    final token = _token;     
    if (token == null) return;     
    state = state.copyWith(isLoading: true, clearError: true);     
    try {       
      final messages = await _service.getChatMessages(         
        token: token,         
        elderlyId: elderlyId,       
      );       
      state = state.copyWith(         
        currentChatMessages: messages,         
        isLoading: false,       
      );     
    } catch (e) {       
      _handleException(e);     
    }   
  }

  Future<bool> sendChatMessage({     
    required String elderlyId,     
    required String messageText,     
    String? receiverId,   
  }) async {     
    final token = _token;     
    if (token == null) return _handleAuthError();     
    try {       
      await _service.sendMessage(         
        token: token,         
        elderlyId: elderlyId,         
        messageText: messageText,         
        receiverId: receiverId,       
      );       
      await fetchChatMessages(elderlyId);       
      return true;     
    } catch (e) {       
      return _handleException(e);     
    }   
  }

  Future<bool> scheduleMedication({     
    required String patientId,     
    required String medicationName,     
    required String dosage,     
    required String scheduledDate,      
    required String scheduledTime,     
    required String category,     
    required String frequency,     
    String? notes,   
  }) async {     
    final token = _token;     
    if (token == null) return _handleAuthError();     
    state = state.copyWith(isLoading: true, clearError: true);     
    try {       
      await _service.scheduleMedication(         
        token: token,         
        patientId: patientId,         
        medicationName: medicationName,         
        dosage: dosage,         
        scheduledDate: scheduledDate,          
        scheduledTime: scheduledTime,         
        category: category,         
        frequency: frequency,         
        notes: notes,       
      );       
      state = state.copyWith(isLoading: false);       
      return true;     
    } catch (e) {       
      return _handleException(e);     
    }   
  }

  Future<bool> recordHealth({     
    required String patientId,     
    required String heartRate,     
    required String bloodPressure,     
    required String bloodSugar,     
    required String notes,   
  }) async {     
    final token = _token;     
    if (token == null) return _handleAuthError();     
    state = state.copyWith(isLoading: true, clearError: true);     
    try {       
      await _service.recordHealth(         
        token: token,         
        patientId: patientId,         
        heartRate: heartRate,         
        bloodPressure: bloodPressure,         
        bloodSugar: bloodSugar,         
        notes: notes,       
      );       
      state = state.copyWith(isLoading: false);       
      return true;     
    } catch (e) {       
      return _handleException(e);     
    }   
  }

  Future<bool> submitCareReport({     
    required String patientId,     
    required String healthStatusNotes,     
    required String dailyActivities,     
    required String observations,     
    String? photoUrl,   
  }) async {     
    final token = _token;     
    if (token == null) return _handleAuthError();     
    state = state.copyWith(isLoading: true, clearError: true);     
    try {       
      await _service.submitCareReport(         
        token: token,         
        patientId: patientId,         
        healthStatusNotes: healthStatusNotes,         
        dailyActivities: dailyActivities,         
        observations: observations,         
        photoUrl: photoUrl,       
      );       
      state = state.copyWith(isLoading: false);       
      return true;     
    } catch (e) {       
      return _handleException(e);     
    }   
  }

  bool _handleAuthError() {     
    state = state.copyWith(       
      isLoading: false,       
      errorMessage: 'Session expired or invalid token. Please log in again.',     
    );     
    return false;   
  }

  bool _handleException(dynamic e) {     
    state = state.copyWith(       
      isLoading: false,       
      errorMessage: e.toString().replaceFirst('Exception: ', ''),     
    );     
    return false;   
  }
}

final caregiverProvider = StateNotifierProvider<CaregiverNotifier, CaregiverState>((ref) {   
  return CaregiverNotifier(ref.watch(caregiverServiceProvider), ref); 
});