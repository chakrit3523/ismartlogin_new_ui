class ItemsOTPList {
  final dynamic MSG; // Can be String or Map depending on API response
  final String RESULT;

  ItemsOTPList({
    required this.MSG,
    required this.RESULT,
  });

  factory ItemsOTPList.fromJson(Map<String, dynamic> json) {
    // Handle msg - can be String or Map (from otpRequest function)
    dynamic msgValue = json['msg'];

    return ItemsOTPList(
      MSG: msgValue,
      RESULT: json['result']?.toString() ?? '',
    );
  }

  // Helper to get MSG as string for display
  String get msgString {
    if (MSG is String) {
      return MSG;
    } else if (MSG is Map) {
      // If it's a map, try to get a status message
      return MSG['message']?.toString() ??
          MSG['status']?.toString() ??
          'OTP sent';
    }
    return MSG.toString();
  }
}
