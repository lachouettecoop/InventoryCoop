class User {
  final String user;
  final String name;
  final String lastname;
  final String role;

  User({this.user, this.name, this.lastname, this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      user: json['user'],
      name: json['name'],
      lastname: json['lastname'],
      role: json['role'],
    );
  }
}