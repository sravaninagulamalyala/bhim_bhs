class Roles {
  static bool isSuperAdmin(String? role) => role == 'SUPER_ADMIN';
  static bool isSecretary(String? role) => role == 'SECRETARY';
  static bool isGeneralSecretary(String? role) => role == 'GENERAL_SECRETARY';
  static bool isJointSecretary(String? role) => role == 'JOINT_SECRETARY';
  static bool isOrgSecretary(String? role) => role == 'ORG_SECRETARY';
  static bool isTreasurer(String? role) => role == 'TREASURER';
  static bool canUpdateMembers(String? role) => isSuperAdmin(role) || isSecretary(role);
  static bool canManageAttendance(String? role) => isSuperAdmin(role) || isGeneralSecretary(role) || isJointSecretary(role) || isOrgSecretary(role) || isSecretary(role);
  static bool canManageTransactions(String? role) => isTreasurer(role);
}
