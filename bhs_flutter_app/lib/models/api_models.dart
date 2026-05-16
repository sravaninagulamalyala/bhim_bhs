class MemberRegistrationInput {
  MemberRegistrationInput({
    required this.firstName,
    required this.lastName,
    required this.fatherOrHusbandName,
    required this.age,
    required this.sex,
    required this.mobileNo,
    required this.address,
  });

  final String firstName;
  final String lastName;
  final String fatherOrHusbandName;
  final int? age;
  final String sex;
  final String mobileNo;
  final String address;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'fatherOrHusbandName': fatherOrHusbandName,
        'age': age,
        'sex': sex,
        'mobileNo': mobileNo,
        'address': address,
      };
}

String readText(Map value, String key, [String fallback = '']) => '${value[key] ?? fallback}';
