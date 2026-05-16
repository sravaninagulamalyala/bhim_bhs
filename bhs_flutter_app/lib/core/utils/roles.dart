class Roles {
  static bool isSuperAdmin(String? role) => role == 'SUPER_ADMIN';
  static bool isSecretary(String? role) => role == 'SECRETARY';
  static bool isTreasurer(String? role) => role == 'TREASURER';
  static bool canUpdateMembers(String? role) => isSuperAdmin(role) || isSecretary(role);
}
