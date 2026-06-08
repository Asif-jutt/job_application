enum UserRole {
  user('user', 'Job Seeker'),
  company('company', 'Recruiter'),
  admin('admin', 'Administrator');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.user,
    );
  }
}
