class Program {
  final String id;
  final String name;
  final int duration;

  Program({
    required this.id,
    required this.name,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'duration': duration,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'],
      name: map['name'],
      duration: map['duration'],
    );
  }
} 