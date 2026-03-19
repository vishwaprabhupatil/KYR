class UserAccount {
  const UserAccount({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        password: (json['password'] ?? '').toString(),
      );
}
