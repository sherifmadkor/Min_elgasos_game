import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomType { public, private }
enum RoomStatus { waiting, starting, rulesRevealed, inGame, voting, resultsShowing, finished }
enum PlayerRole { spy, detective }

class GameRoom {
  final String id;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final RoomType type;
  final String? roomCode; // 4-digit code for private rooms
  final String roomName;
  final RoomStatus status;
  final GameSettings gameSettings;
  final List<RoomPlayer> players;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int maxPlayers;
  final String? currentWord;
  final List<bool>? spyAssignments; // true = spy, false = detective
  final Map<String, String>? playerVotes; // playerId -> votedForPlayerId
  final Map<String, int>? sessionWins; // playerId -> wins count
  final Map<String, int>? sessionLosses; // playerId -> losses count
  final int? currentRound;
  final bool? timerPaused;

  const GameRoom({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    required this.type,
    this.roomCode,
    required this.roomName,
    required this.status,
    required this.gameSettings,
    required this.players,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    required this.maxPlayers,
    this.currentWord,
    this.spyAssignments,
    this.playerVotes,
    this.sessionWins,
    this.sessionLosses,
    this.currentRound,
    this.timerPaused,
  });

  factory GameRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GameRoom(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      hostAvatar: data['hostAvatar'] ?? '🕵️‍♂️',
      type: RoomType.values.firstWhere(
        (e) => e.toString() == 'RoomType.${data['type']}',
        orElse: () => RoomType.public,
      ),
      roomCode: data['roomCode'],
      roomName: data['roomName'] ?? '',
      status: RoomStatus.values.firstWhere(
        (e) => e.toString() == 'RoomStatus.${data['status']}',
        orElse: () => RoomStatus.waiting,
      ),
      gameSettings: GameSettings.fromMap(data['gameSettings'] ?? {}),
      players: (data['players'] as List<dynamic>?)
          ?.map((p) => RoomPlayer.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
      maxPlayers: data['maxPlayers'] ?? 10,
      currentWord: data['currentWord'],
      spyAssignments: (data['spyAssignments'] as List<dynamic>?)
          ?.map((e) => e as bool)
          .toList(),
      playerVotes: (data['playerVotes'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      sessionWins: (data['sessionWins'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)),
      sessionLosses: (data['sessionLosses'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)),
      currentRound: data['currentRound'],
      timerPaused: data['timerPaused'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'type': type.name,
      'roomCode': roomCode,
      'roomName': roomName,
      'status': status.name,
      'gameSettings': gameSettings.toMap(),
      'players': players.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'maxPlayers': maxPlayers,
      'currentWord': currentWord,
      'spyAssignments': spyAssignments,
      'playerVotes': playerVotes,
      'sessionWins': sessionWins,
      'sessionLosses': sessionLosses,
      'currentRound': currentRound,
      'timerPaused': timerPaused,
    };
  }

  GameRoom copyWith({
    String? hostId,
    String? hostName,
    String? hostAvatar,
    RoomType? type,
    String? roomCode,
    String? roomName,
    RoomStatus? status,
    GameSettings? gameSettings,
    List<RoomPlayer>? players,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? maxPlayers,
    String? currentWord,
    List<bool>? spyAssignments,
    Map<String, String>? playerVotes,
    Map<String, int>? sessionWins,
    Map<String, int>? sessionLosses,
    int? currentRound,
    bool? timerPaused,
  }) {
    return GameRoom(
      id: id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      type: type ?? this.type,
      roomCode: roomCode ?? this.roomCode,
      roomName: roomName ?? this.roomName,
      status: status ?? this.status,
      gameSettings: gameSettings ?? this.gameSettings,
      players: players ?? this.players,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      currentWord: currentWord ?? this.currentWord,
      spyAssignments: spyAssignments ?? this.spyAssignments,
      playerVotes: playerVotes ?? this.playerVotes,
      sessionWins: sessionWins ?? this.sessionWins,
      sessionLosses: sessionLosses ?? this.sessionLosses,
      currentRound: currentRound ?? this.currentRound,
      timerPaused: timerPaused ?? this.timerPaused,
    );
  }
}

class RoomPlayer {
  final String id;
  final String name;
  final String avatar;
  final String rank;
  final bool isHost;
  final bool isReady;
  final DateTime joinedAt;
  final PlayerRole? assignedRole; // Set when game starts
  final bool isOnline;

  const RoomPlayer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rank,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
    this.assignedRole,
    required this.isOnline,
  });

  factory RoomPlayer.fromMap(Map<String, dynamic> map) {
    return RoomPlayer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      avatar: map['avatar'] ?? '🕵️‍♂️',
      rank: map['rank'] ?? 'Iron',
      isHost: map['isHost'] ?? false,
      isReady: map['isReady'] ?? false,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedRole: map['assignedRole'] != null 
          ? PlayerRole.values.firstWhere(
              (e) => e.toString() == 'PlayerRole.${map['assignedRole']}',
              orElse: () => PlayerRole.detective,
            )
          : null,
      isOnline: map['isOnline'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'rank': rank,
      'isHost': isHost,
      'isReady': isReady,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'assignedRole': assignedRole?.name,
      'isOnline': isOnline,
    };
  }

  RoomPlayer copyWith({
    String? name,
    String? avatar,
    String? rank,
    bool? isHost,
    bool? isReady,
    PlayerRole? assignedRole,
    bool? isOnline,
  }) {
    return RoomPlayer(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      rank: rank ?? this.rank,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      joinedAt: joinedAt,
      assignedRole: assignedRole ?? this.assignedRole,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class GameSettings {
  final int playerCount;
  final int spyCount;
  final int minutes;
  final String category;

  const GameSettings({
    required this.playerCount,
    required this.spyCount,
    required this.minutes,
    required this.category,
  });

  factory GameSettings.fromMap(Map<String, dynamic> map) {
    return GameSettings(
      playerCount: map['playerCount'] ?? 3,
      spyCount: map['spyCount'] ?? 1,
      minutes: map['minutes'] ?? 5,
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerCount': playerCount,
      'spyCount': spyCount,
      'minutes': minutes,
      'category': category,
    };
  }

  GameSettings copyWith({
    int? playerCount,
    int? spyCount,
    int? minutes,
    String? category,
  }) {
    return GameSettings(
      playerCount: playerCount ?? this.playerCount,
      spyCount: spyCount ?? this.spyCount,
      minutes: minutes ?? this.minutes,
      category: category ?? this.category,
    );
  }
}

class RoomMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isSystemMessage;

  const RoomMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isSystemMessage,
  });

  factory RoomMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return RoomMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystemMessage: data['isSystemMessage'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSystemMessage': isSystemMessage,
    };
  }
}