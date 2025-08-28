class Validators {
  // 이메일 유효성 검사
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요.';
    }

    // 이메일 형식 검사 (간단한 정규식)
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return '유효한 이메일 주소를 입력해주세요.';
    }

    return null;
  }

  // 비밀번호 유효성 검사
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (value.length < 6) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    }

    return null;
  }

  // 비밀번호 확인 일치 검사
  static String? validatePasswordMatch(String? value, String password) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요.';
    }

    if (value != password) {
      return '비밀번호가 일치하지 않습니다.';
    }

    return null;
  }

  // 이름 유효성 검사
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요.';
    }

    if (value.length < 2) {
      return '이름은 최소 2자 이상이어야 합니다.';
    }

    return null;
  }

  // 활동 이름 유효성 검사
  static String? validateActivityName(String? value) {
    if (value == null || value.isEmpty) {
      return '활동 이름을 입력해주세요.';
    }

    if (value.length < 2) {
      return '활동 이름은 최소 2자 이상이어야 합니다.';
    }

    if (value.length > 30) {
      return '활동 이름은 최대 30자 이하여야 합니다.';
    }

    return null;
  }

  // 활동 설명 유효성 검사
  static String? validateActivityDescription(String? value) {
    if (value == null || value.isEmpty) {
      return '활동 설명을 입력해주세요.';
    }

    if (value.length > 100) {
      return '활동 설명은 최대 100자 이하여야 합니다.';
    }

    return null;
  }

  // 수치 유효성 검사 (양수만 허용)
  static String? validatePositiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '값을 입력해주세요.';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '유효한 숫자를 입력해주세요.';
    }

    if (number <= 0) {
      return '0보다 큰 값을 입력해주세요.';
    }

    return null;
  }

  // 시간(분) 유효성 검사
  static String? validateMinutes(String? value) {
    if (value == null || value.isEmpty) {
      return '시간(분)을 입력해주세요.';
    }

    final minutes = int.tryParse(value);
    if (minutes == null) {
      return '유효한 숫자를 입력해주세요.';
    }

    if (minutes <= 0) {
      return '0보다 큰 값을 입력해주세요.';
    }

    if (minutes > 180) {
      return '180분(3시간) 이하로 입력해주세요.';
    }

    return null;
  }
}
